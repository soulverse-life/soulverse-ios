//
//  DetailJournalSection.swift
//  Soulverse
//
//  Card section displaying journal title and content,
//  or a CTA button when no journal exists.
//

import SnapKit
import UIKit

protocol DetailJournalSectionDelegate: AnyObject {
    func detailJournalSectionDidTapCreate(_ section: DetailJournalSection, checkinId: String?)
}

class DetailJournalSection: UIView {

    // MARK: - Properties

    weak var delegate: DetailJournalSectionDelegate?
    private var checkinId: String?

    // MARK: - UI Components

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.3)
        view.layer.cornerRadius = CheckInDetailLayout.sectionCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let sectionIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "book")
        imageView.tintColor = .themeTextSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("checkin_detail_journal", comment: "")
        label.font = .projectFont(ofSize: CheckInDetailLayout.sectionTitleFontSize, weight: .semibold)
        label.textColor = .themeTextSecondary
        return label
    }()

    private let journalTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .bold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private let journalContentLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var ctaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("checkin_detail_journal_cta", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.themeButtonPrimaryText, for: .normal)
        button.backgroundColor = .themeButtonPrimaryBackground
        button.layer.cornerRadius = CheckInDetailLayout.ctaButtonCornerRadius
        button.isHidden = true
        button.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        return button
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
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

        let headerStack = UIStackView(arrangedSubviews: [sectionIconView, sectionTitleLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 6
        headerStack.alignment = .center

        sectionIconView.snp.makeConstraints { make in
            make.width.height.equalTo(CheckInDetailLayout.sectionTitleIconSize)
        }

        contentStack.addArrangedSubview(journalTitleLabel)
        contentStack.addArrangedSubview(journalContentLabel)

        cardView.addSubview(headerStack)
        cardView.addSubview(contentStack)
        cardView.addSubview(ctaButton)

        let padding = CheckInDetailLayout.sectionContentPadding

        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerStack.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(padding)
            make.trailing.lessThanOrEqualToSuperview().offset(-padding)
        }

        contentStack.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.bottom.equalToSuperview().offset(-padding)
        }

        ctaButton.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
            make.bottom.equalToSuperview().offset(-padding)
        }
    }

    // MARK: - Configuration

    func configure(title: String?, content: String?, checkinId: String?) {
        self.checkinId = checkinId

        let hasContent = title != nil || content != nil

        contentStack.isHidden = !hasContent
        ctaButton.isHidden = hasContent

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
    }

    // MARK: - Actions

    @objc private func ctaTapped() {
        delegate?.detailJournalSectionDidTapCreate(self, checkinId: checkinId)
    }
}
