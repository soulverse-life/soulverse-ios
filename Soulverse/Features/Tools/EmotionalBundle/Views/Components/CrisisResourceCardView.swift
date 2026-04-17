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
        static let numberFontSize: CGFloat = 20
        static let descriptionFontSize: CGFloat = 14
        static let availabilityFontSize: CGFloat = 12
        static let nameToNumberSpacing: CGFloat = 4
        static let numberToDescriptionSpacing: CGFloat = 8
        static let descriptionToAvailabilitySpacing: CGFloat = 4
        static let phoneIconSize: CGFloat = 20
        static let phoneIconTrailingInset: CGFloat = 20
        static let labelToIconSpacing: CGFloat = 12
        static let minimumHeight: CGFloat = ViewComponentConstants.navigationButtonSize
    }

    // MARK: - Properties

    weak var parentViewController: UIViewController?
    private var phoneNumber: String?

    // MARK: - UI Elements

    private let baseView: UIView = {
        let view = UIView()
        view.backgroundColor = .themeCardBackground
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.nameFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 1
        return label
    }()

    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.numberFontSize, weight: .bold)
        label.textColor = .themePrimary
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

    private let availabilityLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.availabilityFontSize, weight: .regular)
        label.textColor = .themeTextDisabled
        label.numberOfLines = 1
        return label
    }()

    private let phoneIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themePrimary
        imageView.image = UIImage(systemName: "phone.fill")
        return imageView
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
        baseView.addSubview(nameLabel)
        baseView.addSubview(numberLabel)
        baseView.addSubview(descriptionLabel)
        baseView.addSubview(availabilityLabel)
        baseView.addSubview(phoneIconView)

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

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            addSubview(baseView)
            baseView.layer.cornerRadius = Layout.cornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.clipsToBounds = true

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.greaterThanOrEqualTo(Layout.minimumHeight)
            }
        }

        setupConstraints()
    }

    private func setupConstraints() {
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        phoneIconView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.phoneIconTrailingInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.phoneIconSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.contentInsetVertical)
            make.leading.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.trailing.lessThanOrEqualTo(phoneIconView.snp.leading).offset(-Layout.labelToIconSpacing)
        }

        numberLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(Layout.nameToNumberSpacing)
            make.leading.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.trailing.lessThanOrEqualTo(phoneIconView.snp.leading).offset(-Layout.labelToIconSpacing)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(numberLabel.snp.bottom).offset(Layout.numberToDescriptionSpacing)
            make.leading.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.trailing.lessThanOrEqualTo(phoneIconView.snp.leading).offset(-Layout.labelToIconSpacing)
        }

        availabilityLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(Layout.descriptionToAvailabilitySpacing)
            make.leading.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.trailing.lessThanOrEqualTo(phoneIconView.snp.leading).offset(-Layout.labelToIconSpacing)
            make.bottom.equalToSuperview().inset(Layout.contentInsetVertical)
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

        // Check if device can make phone calls
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

        // Show confirmation alert before dialing
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
        numberLabel.text = resource.number
        descriptionLabel.text = resource.description
        availabilityLabel.text = resource.availability
    }
}
