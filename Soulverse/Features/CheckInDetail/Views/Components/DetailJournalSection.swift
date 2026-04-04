//
//  DetailJournalSection.swift
//  Soulverse
//
//  Glass-effect card displaying journal header, title and content,
//  or a CTA button when no journal exists. Uses state machine for layout.
//

import SnapKit
import UIKit

protocol DetailJournalSectionDelegate: AnyObject {
    func detailJournalSectionDidTapCreate(_ section: DetailJournalSection, checkinId: String?)
}

class DetailJournalSection: UIView {

    // MARK: - State

    private enum State {
        case loading
        case content
        case empty
    }

    // MARK: - Properties

    weak var delegate: DetailJournalSectionDelegate?
    private var checkinId: String?
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
        stack.spacing = 8
        return stack
    }()

    private lazy var sectionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "book")
        imageView.tintColor = .themeTextSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("checkin_detail_journal", comment: "")
        label.font = .projectFont(ofSize: CheckInDetailLayout.sectionTitleFontSize, weight: .semibold)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var journalTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .bold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var journalContentLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    // -- Empty / CTA --

    private lazy var ctaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("checkin_detail_journal_cta", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.themeButtonPrimaryText, for: .normal)
        button.backgroundColor = .themeButtonPrimaryBackground
        button.layer.cornerRadius = CheckInDetailLayout.ctaButtonCornerRadius
        button.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
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
            installContent()
        case .empty:
            installCTA()
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
        contentStack.addArrangedSubview(journalTitleLabel)
        contentStack.addArrangedSubview(journalContentLabel)

        bodyContainer.addSubview(contentStack)
        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func installCTA() {
        bodyContainer.addSubview(ctaButton)
        ctaButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
        }
    }

    // MARK: - Public API

    func showLoading() {
        transition(to: .loading)
    }

    func configure(title: String?, content: String?, checkinId: String?) {
        self.checkinId = checkinId

        let hasContent = title != nil || content != nil

        if hasContent {
            transition(to: .content)

            if let title = title {
                journalTitleLabel.isHidden = false
                journalTitleLabel.text = title
            } else {
                journalTitleLabel.isHidden = true
            }

            if let content = content {
                journalContentLabel.isHidden = false
                journalContentLabel.text = content
            } else {
                journalContentLabel.isHidden = true
            }
        } else {
            transition(to: .empty)
        }
    }

    // MARK: - Actions

    @objc private func ctaTapped() {
        delegate?.detailJournalSectionDidTapCreate(self, checkinId: checkinId)
    }
}
