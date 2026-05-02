//
//  DetailReflectionSection.swift
//  Soulverse
//
//  Dark-card section showing the reflection prompt + answer for a check-in's drawing.
//  Three states:
//    - loading: spinner
//    - content: prompt + answer
//    - empty:   "Add Reflection" CTA (drawing exists, reflection missing)
//
//  When the parent has no drawing image at all, the entire section is hidden by the
//  containing view controller (not handled here).
//

import SnapKit
import UIKit

protocol DetailReflectionSectionDelegate: AnyObject {
    func detailReflectionSectionDidTapAdd(
        _ section: DetailReflectionSection,
        drawingId: String,
        imageURL: String?,
        reflectiveQuestion: String?,
        reflectiveAnswer: String?
    )
}

final class DetailReflectionSection: UIView {

    // MARK: - State

    private enum State {
        case loading
        case content
        case empty
    }

    // MARK: - Properties

    weak var delegate: DetailReflectionSectionDelegate?
    private var pendingDrawingId: String?
    private var pendingImageURL: String?
    private var pendingReflectiveQuestion: String?
    private var pendingReflectiveAnswer: String?
    private var currentState: State?

    // MARK: - UI Components

    private let cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = CheckInDetailLayout.sectionCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    /// Single container whose child is swapped between loading / content / CTA.
    private let bodyContainer = UIView()

    /// Holds cardView and ctaButton as arranged subviews so that hiding one
    /// collapses it from layout (UIStackView respects isHidden). This avoids
    /// the over-constrained "both pinned to all edges" pattern.
    private let containerStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        return stack
    }()

    // -- Loading --

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .themeTextSecondary
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // -- Content --

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private lazy var sectionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "star")
        imageView.tintColor = .themeTextSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("checkin_detail_reflection", comment: "")
        label.font = .projectFont(ofSize: CheckInDetailLayout.sectionTitleFontSize, weight: .semibold)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: CheckInDetailLayout.reflectionTitleFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var reflectionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: CheckInDetailLayout.reflectionAnswerFontSize, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    // -- Empty / CTA --

    private lazy var ctaButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("drawing_reflection_add_cta", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
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
        containerStack.addArrangedSubview(cardView)
        containerStack.addArrangedSubview(ctaButton)
        addSubview(containerStack)

        setupCardGlassEffect()

        let padding = CheckInDetailLayout.sectionContentPadding

        containerStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bodyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
        }

        ctaButton.snp.makeConstraints { make in
            make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
        }
        ctaButton.isHidden = true
    }

    private func setupCardGlassEffect() {
        ViewComponentConstants.applyDarkGlassCardEffect(
            to: cardView,
            visualEffectView: visualEffectView,
            contentView: bodyContainer,
            cornerRadius: CheckInDetailLayout.sectionCornerRadius
        )
    }

    // MARK: - State Transitions

    private func transition(to state: State) {
        guard currentState != state else { return }
        currentState = state

        // Remove previous content from the card body
        bodyContainer.subviews.forEach { $0.removeFromSuperview() }

        switch state {
        case .loading:
            cardView.isHidden = false
            ctaButton.isHidden = true
            installLoading()
        case .content:
            cardView.isHidden = false
            ctaButton.isHidden = true
            installContent()
        case .empty:
            // Render the CTA standalone — no card chrome around an empty section.
            cardView.isHidden = true
            ctaButton.isHidden = false
        }
    }

    private func installLoading() {
        bodyContainer.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
        }
        loadingIndicator.startAnimating()
    }

    private func installContent() {
        let headerStack = UIStackView(arrangedSubviews: [sectionIconView, sectionTitleLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center

        sectionIconView.snp.remakeConstraints { make in
            make.width.height.equalTo(CheckInDetailLayout.sectionTitleIconSize)
        }

        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentStack.addArrangedSubview(headerStack)
        contentStack.addArrangedSubview(promptLabel)
        contentStack.addArrangedSubview(reflectionLabel)

        bodyContainer.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Public API

    func showLoading() {
        transition(to: .loading)
    }

    /// Configure with the drawing context. Pass nil/empty reflectiveAnswer to render the empty CTA.
    /// drawingId is required because the "Add Reflection" navigation needs it to persist the answer.
    func configure(
        drawingId: String?,
        imageURL: String?,
        reflectiveQuestion: String?,
        reflectiveAnswer: String?
    ) {
        self.pendingDrawingId = drawingId
        self.pendingImageURL = imageURL
        self.pendingReflectiveQuestion = reflectiveQuestion
        self.pendingReflectiveAnswer = reflectiveAnswer

        if let reflectiveAnswer = reflectiveAnswer, !reflectiveAnswer.isEmpty {
            transition(to: .content)
            promptLabel.text = reflectiveQuestion
            promptLabel.isHidden = (reflectiveQuestion == nil)
            reflectionLabel.text = reflectiveAnswer
        } else {
            transition(to: .empty)
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension DetailReflectionSection: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let drawingId = pendingDrawingId else { return }
        delegate?.detailReflectionSectionDidTapAdd(
            self,
            drawingId: drawingId,
            imageURL: pendingImageURL,
            reflectiveQuestion: pendingReflectiveQuestion,
            reflectiveAnswer: pendingReflectiveAnswer
        )
    }
}
