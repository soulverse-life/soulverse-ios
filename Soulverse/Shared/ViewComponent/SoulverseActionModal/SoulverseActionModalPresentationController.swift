//
//  SoulverseActionModalPresentationController.swift
//  Soulverse
//
//  Created by Claude on 2026/2/13.
//

import UIKit

// MARK: - Presentation Controller

final class SoulverseActionModalPresentationController: UIPresentationController {

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let dimmingAlpha: CGFloat = 0.5
    }

    // MARK: - Dimming View

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(Layout.dimmingAlpha)
        view.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(dimmingViewTapped))
        view.addGestureRecognizer(tap)
        return view
    }()

    // MARK: - Overrides

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView,
              let presentedView = presentedView else {
            return .zero
        }

        let containerBounds = containerView.bounds
        let targetWidth = containerBounds.width

        let fittingSize = CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height)
        let contentHeight = presentedView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        let safeAreaBottom = containerView.safeAreaInsets.bottom
        let totalHeight = min(contentHeight + safeAreaBottom, containerBounds.height * 0.9)

        return CGRect(
            x: 0,
            y: containerBounds.height - totalHeight,
            width: targetWidth,
            height: totalHeight
        )
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)

        presentedView?.layer.cornerRadius = Layout.cornerRadius
        presentedView?.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        presentedView?.clipsToBounds = true

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 1
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0
            return
        }

        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.dimmingView.alpha = 0
        })
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            dimmingView.removeFromSuperview()
        }
    }

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    // MARK: - Actions

    @objc private func dimmingViewTapped() {
        presentedViewController.dismiss(animated: true)
    }
}

// MARK: - Slide-Up Transition Animator

final class SoulverseActionModalAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private enum Layout {
        static let presentDuration: TimeInterval = 0.35
        static let dismissDuration: TimeInterval = 0.25
        static let springDamping: CGFloat = 0.9
        static let springVelocity: CGFloat = 0.5
    }

    let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        isPresenting ? Layout.presentDuration : Layout.dismissDuration
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        if isPresenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }

    private func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toVC)

        toView.frame = finalFrame.offsetBy(dx: 0, dy: finalFrame.height)
        containerView.addSubview(toView)

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: Layout.springDamping,
            initialSpringVelocity: Layout.springVelocity,
            options: .curveEaseOut
        ) {
            toView.frame = finalFrame
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseIn
        ) {
            fromView.frame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

// MARK: - Interactive Dismiss Driver

final class SoulverseActionModalInteractiveDismiss: UIPercentDrivenInteractiveTransition {

    private enum Threshold {
        static let dismissDistance: CGFloat = 100
        static let dismissVelocity: CGFloat = 800
    }

    private(set) var isInteracting = false
    private weak var viewController: UIViewController?
    private var presentedViewHeight: CGFloat = 0

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init()

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        viewController.view.addGestureRecognizer(pan)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }

        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)

        switch gesture.state {
        case .began:
            presentedViewHeight = view.frame.height
            isInteracting = true
            viewController?.dismiss(animated: true)

        case .changed:
            let progress = max(0, min(1, translation.y / presentedViewHeight))
            update(progress)

        case .ended, .cancelled:
            isInteracting = false
            let shouldDismiss = translation.y > Threshold.dismissDistance
                || velocity.y > Threshold.dismissVelocity

            if shouldDismiss {
                finish()
            } else {
                cancel()
            }

        default:
            isInteracting = false
            cancel()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SoulverseActionModalInteractiveDismiss: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: pan.view)
        // Only activate for downward drags
        return velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
    }
}
