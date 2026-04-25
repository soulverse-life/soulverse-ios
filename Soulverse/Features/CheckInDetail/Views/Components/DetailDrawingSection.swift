//
//  DetailDrawingSection.swift
//  Soulverse
//
//  Glass-effect card displaying drawing image, reflection title/prompt/reply,
//  or a CTA button when no drawing exists. Uses state machine for layout.
//

import Kingfisher
import SnapKit
import UIKit

protocol DetailDrawingSectionDelegate: AnyObject {
    func detailDrawingSectionDidTapCreate(_ section: DetailDrawingSection, checkinId: String?)
    func detailDrawingSectionDidTapAddReflection(
        _ section: DetailDrawingSection,
        drawingId: String,
        imageURL: String?,
        reflectiveQuestion: String?,
        reflectiveAnswer: String?
    )
}

final class DetailDrawingSection: UIView {

    // MARK: - State

    private enum State {
        case loading
        case content
        case unanswered
        case empty
    }

    // MARK: - Properties

    weak var delegate: DetailDrawingSectionDelegate?
    private var checkinId: String?
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
        stack.spacing = 12
        stack.alignment = .center
        return stack
    }()

    private lazy var drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = CheckInDetailLayout.drawingImageCornerRadius
        imageView.backgroundColor = .white
        return imageView
    }()

    private lazy var textStack: UIStackView = {
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
        label.font = .projectFont(ofSize: 20, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var reflectionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    // -- Empty / CTA --

    private lazy var drawCTAButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("checkin_detail_draw_cta", comment: ""),
            style: .primary,
            delegate: self
        )
        return button
    }()

    private lazy var addReflectionCTAButton: SoulverseButton = {
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
        addSubview(cardView)
        setupCardGlassEffect()

        let padding = CheckInDetailLayout.sectionContentPadding

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bodyContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(padding)
        }
    }

    private func setupCardGlassEffect() {
        ViewComponentConstants.applyGlassCardEffect(
            to: cardView,
            visualEffectView: visualEffectView,
            contentView: bodyContainer,
            cornerRadius: CheckInDetailLayout.sectionCornerRadius,
            darkMode: true
        )
    }

    // MARK: - State Transitions

    private func transition(to state: State) {
        guard currentState != state else { return }
        currentState = state

        // Remove previous content
        bodyContainer.subviews.forEach { $0.removeFromSuperview() }

        switch state {
        case .loading:
            installLoading()
        case .content:
            installContent(showingAnswer: true)
        case .unanswered:
            installContent(showingAnswer: false)
        case .empty:
            installDrawCTA()
        }
    }

    private func installLoading() {
        bodyContainer.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.top.bottom.centerX.equalToSuperview()
        }
        loadingIndicator.startAnimating()
    }

    private func installContent(showingAnswer: Bool) {
        let headerStack = UIStackView(arrangedSubviews: [sectionIconView, sectionTitleLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center

        sectionIconView.snp.remakeConstraints { make in
            make.width.height.equalTo(CheckInDetailLayout.sectionTitleIconSize)
        }

        textStack.arrangedSubviews.forEach { textStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        textStack.addArrangedSubview(headerStack)
        textStack.addArrangedSubview(promptLabel)
        if showingAnswer {
            textStack.addArrangedSubview(reflectionLabel)
        } else {
            textStack.addArrangedSubview(addReflectionCTAButton)
            addReflectionCTAButton.snp.remakeConstraints { make in
                make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
            }
        }

        contentStack.arrangedSubviews.forEach { contentStack.removeArrangedSubview($0); $0.removeFromSuperview() }
        contentStack.addArrangedSubview(drawingImageView)
        contentStack.addArrangedSubview(textStack)

        drawingImageView.snp.remakeConstraints { make in
            make.width.equalTo(CheckInDetailLayout.drawingImageWidth)
            make.height.equalTo(CheckInDetailLayout.drawingImageHeight)
        }

        bodyContainer.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        textStack.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
    }

    private func installDrawCTA() {
        bodyContainer.addSubview(drawCTAButton)
        drawCTAButton.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    // MARK: - Public API

    func showLoading() {
        transition(to: .loading)
    }

    func configure(
        drawingId: String?,
        imageURL: String?,
        reflectiveQuestion: String?,
        reflectiveAnswer: String?,
        checkinId: String?
    ) {
        self.checkinId = checkinId
        self.pendingDrawingId = drawingId
        self.pendingImageURL = imageURL
        self.pendingReflectiveQuestion = reflectiveQuestion
        self.pendingReflectiveAnswer = reflectiveAnswer

        guard imageURL != nil else {
            transition(to: .empty)
            return
        }

        let hasAnswer = reflectiveAnswer?.isEmpty == false
        transition(to: hasAnswer ? .content : .unanswered)

        if let imageURL = imageURL, let url = URL(string: imageURL) {
            drawingImageView.isHidden = false
            drawingImageView.kf.setImage(with: url)
        } else {
            drawingImageView.isHidden = true
        }

        if let question = reflectiveQuestion {
            promptLabel.isHidden = false
            promptLabel.text = question
        } else {
            promptLabel.isHidden = true
        }

        if hasAnswer {
            reflectionLabel.isHidden = false
            reflectionLabel.text = reflectiveAnswer
        } else {
            reflectionLabel.isHidden = true
        }
    }

}

// MARK: - SoulverseButtonDelegate

extension DetailDrawingSection: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        if button === addReflectionCTAButton {
            guard let drawingId = pendingDrawingId else { return }
            delegate?.detailDrawingSectionDidTapAddReflection(
                self,
                drawingId: drawingId,
                imageURL: pendingImageURL,
                reflectiveQuestion: pendingReflectiveQuestion,
                reflectiveAnswer: pendingReflectiveAnswer
            )
        } else {
            delegate?.detailDrawingSectionDidTapCreate(self, checkinId: checkinId)
        }
    }
}
