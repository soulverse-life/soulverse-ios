//
//  SoulverseButton.swift
//  Soulverse
//
//  Created by mingshing on 2021/12/10.
//

import Foundation
import UIKit
import SnapKit

// MARK: - Third Party Auth Configuration

struct ThirdPartyAuthConfig {
    let backgroundColor: UIColor
    let textColor: UIColor
    let borderColor: UIColor
    let borderWidth: CGFloat
    let icon: UIImage?
    let cornerRadius: CGFloat

    // Convenience factory methods for common auth providers
    static func google() -> ThirdPartyAuthConfig {
        ThirdPartyAuthConfig(
            backgroundColor: .white,
            textColor: .black,
            borderColor: .lightGray,
            borderWidth: 1,
            icon: UIImage(named: "icon_google"),
            cornerRadius: 25
        )
    }

    static func apple() -> ThirdPartyAuthConfig {
        ThirdPartyAuthConfig(
            backgroundColor: .black,
            textColor: .white,
            borderColor: .black,
            borderWidth: 1,
            icon: UIImage(systemName: "apple.logo"),
            cornerRadius: 25
        )
    }

    static func facebook() -> ThirdPartyAuthConfig {
        ThirdPartyAuthConfig(
            backgroundColor: UIColor(red: 24/255, green: 119/255, blue: 242/255, alpha: 1),
            textColor: .white,
            borderColor: .clear,
            borderWidth: 0,
            icon: UIImage(named: "icon_facebook"),
            cornerRadius: 25
        )
    }

    static func line() -> ThirdPartyAuthConfig {
        ThirdPartyAuthConfig(
            backgroundColor: UIColor(red: 0/255, green: 195/255, blue: 0/255, alpha: 1),
            textColor: .white,
            borderColor: .clear,
            borderWidth: 0,
            icon: UIImage(named: "icon_line"),
            cornerRadius: 25
        )
    }
}

// MARK: - Button Style

enum SoulverseButtonStyle {
    case primary                                    // Standard button (black border, white bg)
    case thirdPartyAuth(ThirdPartyAuthConfig)      // Third-party auth button (Google, Apple, etc.)
    case outlined                                   // Outlined style with customization
}

// MARK: - Button Delegate

protocol SoulverseButtonDelegate: AnyObject {
    func clickSoulverseButton(_ button: SoulverseButton)
}

// MARK: - Soulverse Button

class SoulverseButton: UIView {

    // MARK: - Properties

    weak var delegate: SoulverseButtonDelegate?

    private let baseView = UIView()
    private let visualEffectView = UIVisualEffectView()

    private let titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        titleLabel.font = .projectFont(ofSize: 16.0, weight: .medium)
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    public var titleText: String {
        didSet {
            titleLabel.text = titleText
            accessibilityLabel = titleText
        }
    }

    public var titleColor: UIColor {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

    public var isEnabled: Bool = true {
        didSet {
            updateEnabledState()
        }
    }

    private var style: SoulverseButtonStyle

    // MARK: - Initialization

    init(title: String = "", style: SoulverseButtonStyle = .primary, delegate: SoulverseButtonDelegate? = nil) {
        self.titleText = title
        self.style = style
        self.delegate = delegate
        super.init(frame: .zero)

        clipsToBounds = false
        self.isAccessibilityElement = true
        self.accessibilityLabel = title

        setupView()
        applyStyle(style)
    }

    // Legacy initializer for backward compatibility
    convenience init(title: String = "", image: UIImage?, delegate: SoulverseButtonDelegate? = nil) {
        self.init(title: title, style: .primary, delegate: delegate)
        if let image = image {
            iconImageView.image = image
            iconImageView.isHidden = false
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        // Setup base view to hold content
        baseView.addSubview(containerStackView)
        containerStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }

        // Add icon and title to stack view
        containerStackView.addArrangedSubview(iconImageView)
        containerStackView.addArrangedSubview(titleLabel)

        // Icon size constraints with lower priority to avoid conflicts
        iconImageView.snp.makeConstraints { make in
            make.width.equalTo(20).priority(.high)
            make.height.equalTo(20).priority(.high)
        }

        // Initially hide icon
        iconImageView.isHidden = true

        // Setup tap gesture
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(didTapButton))
        self.addGestureRecognizer(singleTap)

        titleLabel.text = titleText
    }

    // MARK: - Style Management

    public func applyStyle(_ style: SoulverseButtonStyle) {
        self.style = style

        // Clean up previous style's views
        baseView.removeFromSuperview()
        visualEffectView.removeFromSuperview()
        visualEffectView.contentView.subviews.forEach { $0.removeFromSuperview() }

        switch style {
        case .primary:
            titleLabel.textColor = .themeButtonPrimaryText
            iconImageView.isHidden = true

            addSubview(baseView)
            baseView.layer.cornerRadius = 24
            baseView.clipsToBounds = true

            // Set solid background color based on enabled state
            baseView.backgroundColor = isEnabled ? .themeButtonPrimaryBackground : .themeButtonDisabledBackground

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            if #available(iOS 26.0, *) {
                // iOS 26+: Layer glass effect on top of colored background
                let glassEffect = UIGlassEffect(style: .clear)
                visualEffectView.effect = glassEffect
                visualEffectView.clipsToBounds = true
                visualEffectView.isUserInteractionEnabled = false
                visualEffectView.overrideUserInterfaceStyle = .light
                baseView.addSubview(visualEffectView)

                visualEffectView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }

                // Move content to glass effect's content view
                visualEffectView.contentView.addSubview(containerStackView)
            }

        case .thirdPartyAuth(let config):
            addSubview(baseView)
            baseView.backgroundColor = config.backgroundColor
            titleLabel.textColor = config.textColor
            baseView.layer.borderWidth = config.borderWidth
            baseView.layer.borderColor = config.borderColor.cgColor
            baseView.layer.cornerRadius = config.cornerRadius
            baseView.clipsToBounds = true

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            if let icon = config.icon {
                iconImageView.image = icon
                iconImageView.tintColor = config.textColor
                iconImageView.isHidden = false
            } else {
                iconImageView.isHidden = true
            }

        case .outlined:
            addSubview(baseView)
            baseView.backgroundColor = .white
            titleLabel.textColor = .black
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.lightGray.cgColor
            baseView.layer.cornerRadius = 8
            baseView.clipsToBounds = true
            iconImageView.isHidden = true

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        updateEnabledState()
    }

    private func updateEnabledState() {
        isUserInteractionEnabled = isEnabled

        // Update appearance based on style
        switch style {
        case .primary:
            // For primary style, change background color and keep full opacity
            baseView.backgroundColor = isEnabled ? .themeButtonPrimaryBackground : .themeButtonDisabledBackground
            titleLabel.textColor = isEnabled ? .themeButtonPrimaryText : .themeButtonDisabledText
            alpha = 1.0
        default:
            // For other styles, use opacity change
            alpha = isEnabled ? 1.0 : 0.5
        }
    }

    // MARK: - Actions

    @objc private func didTapButton() {
        guard isEnabled else { return }

        // Add tap animation
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }

        delegate?.clickSoulverseButton(self)
    }
}
