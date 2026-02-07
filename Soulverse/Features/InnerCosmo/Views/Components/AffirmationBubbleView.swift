//
//  AffirmationBubbleView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Speech bubble view for displaying affirmation quotes from the E.M.O pet
class AffirmationBubbleView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 10
        static let cornerRadius: CGFloat = 12
        static let maxWidth: CGFloat = 150
        static let tailSize: CGFloat = 8
        static let fontSize: CGFloat = 13
    }

    // MARK: - UI Components

    private lazy var bubbleContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .themeSecondary
        view.layer.cornerRadius = Layout.cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
        view.layer.shadowOpacity = 0.15
        return view
    }()

    private lazy var quoteLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.fontSize, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var tailView: UIView = {
        let view = LeftPointingTriangleView()
        view.fillColor = .themeSecondary
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear

        addSubview(tailView)
        addSubview(bubbleContainer)
        bubbleContainer.addSubview(quoteLabel)

        // Tail on the left, pointing toward the emo pet
        tailView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(Layout.tailSize)
            make.height.equalTo(Layout.tailSize * 2)
        }

        // Bubble container to the right of the tail
        bubbleContainer.snp.makeConstraints { make in
            make.left.equalTo(tailView.snp.right)
            make.top.bottom.right.equalToSuperview()
            make.width.lessThanOrEqualTo(Layout.maxWidth)
        }

        quoteLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.verticalPadding)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }
    }

    // MARK: - Configuration

    /// Configure the bubble with a quote
    /// - Parameter quote: The affirmation quote to display
    func configure(with quote: AffirmationQuote) {
        quoteLabel.text = quote.text
    }

    // MARK: - Animation

    /// Show the bubble with a pop-in animation
    func showAnimated(completion: (() -> Void)? = nil) {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.5, y: 0.5)

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            usingSpringWithDamping: 0.6,
            initialSpringVelocity: 0.5,
            options: .curveEaseOut
        ) {
            self.alpha = 1
            self.transform = .identity
        } completion: { _ in
            completion?()
        }
    }

    /// Hide the bubble with a fade-out animation
    func hideAnimated(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: AnimationConstant.defaultDuration, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        } completion: { _ in
            self.removeFromSuperview()
            completion?()
        }
    }
}

// MARK: - Left-Pointing Triangle View for Speech Bubble Tail

private class LeftPointingTriangleView: UIView {
    var fillColor: UIColor = .white {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        // Triangle pointing left: tip on left, flat edge on right
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))  // Left tip
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))  // Top right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))  // Bottom right
        path.close()

        fillColor.setFill()
        path.fill()
    }
}
