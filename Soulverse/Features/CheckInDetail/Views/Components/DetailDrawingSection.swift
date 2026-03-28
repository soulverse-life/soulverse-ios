//
//  DetailDrawingSection.swift
//  Soulverse
//
//  Card section displaying the drawing image and reflection text,
//  or a CTA button when no drawing exists.
//

import Kingfisher
import SnapKit
import UIKit

protocol DetailDrawingSectionDelegate: AnyObject {
    func detailDrawingSectionDidTapCreate(_ section: DetailDrawingSection, checkinId: String?)
}

class DetailDrawingSection: UIView {

    // MARK: - Properties

    weak var delegate: DetailDrawingSectionDelegate?
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
        imageView.image = UIImage(systemName: "paintbrush")
        imageView.tintColor = .themeTextSecondary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let sectionTitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("checkin_detail_reflection", comment: "")
        label.font = .projectFont(ofSize: CheckInDetailLayout.sectionTitleFontSize, weight: .semibold)
        label.textColor = .themeTextSecondary
        return label
    }()

    private let drawingImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = CheckInDetailLayout.drawingImageCornerRadius
        imageView.backgroundColor = .white
        return imageView
    }()

    private let promptLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        return label
    }()

    private let reflectionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var ctaButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("checkin_detail_draw_cta", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.themeButtonPrimaryText, for: .normal)
        button.backgroundColor = .themeButtonPrimaryBackground
        button.layer.cornerRadius = CheckInDetailLayout.ctaButtonCornerRadius
        button.isHidden = true
        button.addTarget(self, action: #selector(ctaTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Content stack (hidden when empty)

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
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

        contentStack.addArrangedSubview(drawingImageView)
        contentStack.addArrangedSubview(promptLabel)
        contentStack.addArrangedSubview(reflectionLabel)

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

        drawingImageView.snp.makeConstraints { make in
            make.height.equalTo(CheckInDetailLayout.drawingImageHeight)
        }

        ctaButton.snp.makeConstraints { make in
            make.top.equalTo(headerStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.height.equalTo(CheckInDetailLayout.ctaButtonHeight)
            make.bottom.equalToSuperview().offset(-padding)
        }
    }

    // MARK: - Configuration

    func configure(imageURL: String?, prompt: String?, reflection: String?, checkinId: String?) {
        self.checkinId = checkinId

        let hasContent = imageURL != nil || prompt != nil || reflection != nil

        contentStack.isHidden = !hasContent
        ctaButton.isHidden = hasContent

        if let imageURL = imageURL, let url = URL(string: imageURL) {
            drawingImageView.isHidden = false
            drawingImageView.kf.setImage(with: url)
        } else {
            drawingImageView.isHidden = true
        }

        if let prompt = prompt {
            promptLabel.isHidden = false
            promptLabel.text = prompt
        } else {
            promptLabel.isHidden = true
        }

        if let reflection = reflection {
            reflectionLabel.isHidden = false
            reflectionLabel.text = reflection
        } else {
            reflectionLabel.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func ctaTapped() {
        delegate?.detailDrawingSectionDidTapCreate(self, checkinId: checkinId)
    }
}
