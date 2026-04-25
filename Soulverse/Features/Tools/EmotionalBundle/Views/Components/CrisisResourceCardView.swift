//
//  CrisisResourceCardView.swift
//  Soulverse
//
//  Created on 2026/4/16.
//

import UIKit
import SnapKit

final class CrisisResourceCardView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let contentInsetVertical: CGFloat = 16
        static let contentInsetHorizontal: CGFloat = 20
        static let nameFontSize: CGFloat = 16
        static let numberFontSize: CGFloat = 17
        static let descriptionFontSize: CGFloat = 15
        static let availabilityFontSize: CGFloat = 13
        static let starIconSize: CGFloat = 14
        static let headerRowSpacing: CGFloat = 8
        static let headerToBodySpacing: CGFloat = 16
        static let numberToDescriptionSpacing: CGFloat = 4
        static let minimumHeight: CGFloat = ViewComponentConstants.navigationButtonSize
    }

    // MARK: - Properties

    weak var parentViewController: UIViewController?
    private var phoneNumber: String?

    // MARK: - UI Elements

    private let baseView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private let starIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themeTextPrimary
        imageView.image = UIImage(systemName: "star")
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.nameFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 1
        return label
    }()

    private let availabilityLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.availabilityFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 1
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var headerRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [starIconView, nameLabel, availabilityLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = Layout.headerRowSpacing
        return stack
    }()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.numberFontSize, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.descriptionFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        return label
    }()

    private let fallbackMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.descriptionFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var rootStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            headerRow, numberLabel, descriptionLabel, fallbackMessageLabel
        ])
        stack.axis = .vertical
        stack.spacing = 0
        stack.setCustomSpacing(Layout.headerToBodySpacing, after: headerRow)
        stack.setCustomSpacing(Layout.numberToDescriptionSpacing, after: numberLabel)
        return stack
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        baseView.addSubview(rootStack)

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.greaterThanOrEqualTo(Layout.minimumHeight)
            }

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            addSubview(baseView)
            baseView.layer.cornerRadius = Layout.cornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .white.withAlphaComponent(0.1)
            baseView.clipsToBounds = true

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.greaterThanOrEqualTo(Layout.minimumHeight)
            }
        }

        setupConstraints()
    }

    private func setupConstraints() {
        rootStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.contentInsetVertical)
            make.leading.trailing.equalToSuperview().inset(Layout.contentInsetHorizontal)
        }

        starIconView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.starIconSize)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    // MARK: - Actions

    @objc private func handleTap() {
        guard let number = phoneNumber else { return }

        let cleanedNumber = number.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        guard let url = URL(string: "tel:\(cleanedNumber)") else { return }

        guard UIApplication.shared.canOpenURL(url) else {
            let alert = UIAlertController(
                title: NSLocalizedString("emotional_bundle_crisis_call_unavailable_title", comment: ""),
                message: NSLocalizedString("emotional_bundle_crisis_call_unavailable_message", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("emotional_bundle_crisis_ok", comment: ""),
                style: .default
            ))
            parentViewController?.present(alert, animated: true)
            return
        }

        let alert = UIAlertController(
            title: String(
                format: NSLocalizedString("emotional_bundle_crisis_call_confirmation", comment: ""),
                number
            ),
            message: nil,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("emotional_bundle_crisis_call_action", comment: ""),
            style: .default
        ) { _ in
            UIApplication.shared.open(url)
        })

        alert.addAction(UIAlertAction(
            title: NSLocalizedString("emotional_bundle_crisis_cancel", comment: ""),
            style: .cancel
        ))

        parentViewController?.present(alert, animated: true)
    }

    // MARK: - Configuration

    func configure(with resource: CrisisResource) {
        phoneNumber = resource.number
        nameLabel.text = resource.name
        numberLabel.text = String(
            format: NSLocalizedString("emotional_bundle_crisis_call_or_text_format", comment: ""),
            resource.number
        )
        descriptionLabel.text = NSLocalizedString(resource.descriptionKey, comment: "")
        availabilityLabel.text = resource.availability

        headerRow.isHidden = false
        numberLabel.isHidden = false
        descriptionLabel.isHidden = false
        fallbackMessageLabel.isHidden = true
        isUserInteractionEnabled = true
    }

    func configureWithFallbackMessage() {
        phoneNumber = nil
        fallbackMessageLabel.text = NSLocalizedString("emotional_bundle_crisis_fallback_message", comment: "")

        headerRow.isHidden = true
        numberLabel.isHidden = true
        descriptionLabel.isHidden = true
        fallbackMessageLabel.isHidden = false
        isUserInteractionEnabled = false
    }
}
