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
    case gradient                                   // Gradient button with shadow effect (theme-aware)
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
        titleLabel.textColor = .black
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

    private var gradientLayer: CAGradientLayer?

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
            titleLabel.textColor = .themeTextPrimary
            iconImageView.isHidden = true

            if #available(iOS 26.0, *) {
                // iOS 26+: Use glass effect
                let glassEffect = UIGlassEffect(style: .clear)
                visualEffectView.effect = glassEffect
                visualEffectView.layer.cornerRadius = 25
                visualEffectView.clipsToBounds = true
                visualEffectView.contentView.addSubview(baseView)
                addSubview(visualEffectView)

                visualEffectView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }

                UIView.animate {
                    self.visualEffectView.effect = glassEffect
                    self.visualEffectView.overrideUserInterfaceStyle = .light
                }
            } else {
                // Pre-iOS 26: Fallback to translucent style
                addSubview(baseView)
                baseView.layer.cornerRadius = 25
                baseView.layer.borderWidth = 1
                baseView.layer.borderColor = UIColor.themeSeparator.cgColor
                baseView.backgroundColor = .white.withAlphaComponent(0.1)
                baseView.clipsToBounds = true
            }

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
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

        case .gradient:
            addSubview(baseView)

            // Remove existing gradient layer
            gradientLayer?.removeFromSuperlayer()

            // Create gradient layer
            let gradient = CAGradientLayer()
            gradient.frame = bounds
            let theme = ThemeManager.shared.currentTheme
            gradient.colors = theme.buttonGradientColors.map { $0.cgColor }
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1)
            gradient.cornerRadius = 25

            baseView.layer.insertSublayer(gradient, at: 0)
            gradientLayer = gradient

            // Configure appearance
            baseView.backgroundColor = .clear
            titleLabel.textColor = .white
            baseView.layer.borderWidth = 0
            baseView.layer.cornerRadius = 25
            baseView.clipsToBounds = false
            iconImageView.isHidden = true

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            // Add shadow: box-shadow: 0px 4px 20px 0px rgba(93, 219, 207, 0.4)
            // Use the second gradient color for shadow (typically the lighter/end color)
            if theme.buttonGradientColors.count > 1 {
                baseView.layer.shadowColor = theme.buttonGradientColors[1].cgColor
            } else {
                baseView.layer.shadowColor = theme.buttonGradientColors[0].cgColor
            }
            baseView.layer.shadowOffset = CGSize(width: 0, height: 4)
            baseView.layer.shadowRadius = 20
            baseView.layer.shadowOpacity = 0.4
        }

        updateEnabledState()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Update gradient frame when bounds change
        gradientLayer?.frame = baseView.bounds
    }

    private func updateEnabledState() {
        alpha = isEnabled ? 1.0 : 0.5
        isUserInteractionEnabled = isEnabled
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

    // MARK: - FlexLayout Compatibility

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // Account for horizontal padding (16pt on each side = 32pt total)
        let availableWidth = size.width > 32 ? size.width - 32 : size.width

        // Let the internal stack view calculate its natural size
        let contentSize = containerStackView.systemLayoutSizeFitting(
            CGSize(width: availableWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        // Add horizontal padding and ensure minimum touch target height
        return CGSize(
            width: contentSize.width + 32,
            height: max(50, contentSize.height + 32)  // Minimum 50pt height (matches button design)
        )
    }
}
