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
        static let animationDuration: TimeInterval = 0.3
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
        static let animationDuration: TimeInterval = 0.4
        static let springDamping: CGFloat = 0.85
        static let springVelocity: CGFloat = 0.5
    }

    let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
        super.init()
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        Layout.animationDuration
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
        } completion: { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }

    private func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }

        let duration = transitionDuration(using: transitionContext)

        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: .curveEaseIn
        ) {
            fromView.frame = fromView.frame.offsetBy(dx: 0, dy: fromView.frame.height)
        } completion: { finished in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
