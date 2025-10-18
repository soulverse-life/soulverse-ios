//
//  GradientView.swift
//  Soulverse
//

import UIKit

/// A view that displays a gradient background based on the current theme
class GradientView: UIView {

    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var currentThemeId: String?

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()

        // Update frame without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer?.frame = bounds
        CATransaction.commit()

        // Check if theme has changed and update if needed
        let theme = ThemeManager.shared.currentTheme
        if theme.id != currentThemeId {
            updateGradient()
        }
    }

    // MARK: - Setup
    private func setupGradient() {
        let theme = ThemeManager.shared.currentTheme
        currentThemeId = theme.id

        // Remove existing gradient layer if any
        gradientLayer?.removeFromSuperlayer()

        // Create new gradient layer
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.colors = theme.backgroundGradientColors.map { $0.cgColor }
        gradient.locations = theme.backgroundGradientLocations
        gradient.startPoint = theme.backgroundGradientDirection.startPoint
        gradient.endPoint = theme.backgroundGradientDirection.endPoint

        layer.insertSublayer(gradient, at: 0)
        gradientLayer = gradient
    }

    // MARK: - Public Methods
    /// Manually update the gradient to match the current theme
    func updateGradient() {
        let theme = ThemeManager.shared.currentTheme
        currentThemeId = theme.id

        // Update without animation to prevent blinking during tab switches
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        gradientLayer?.colors = theme.backgroundGradientColors.map { $0.cgColor }
        gradientLayer?.locations = theme.backgroundGradientLocations
        gradientLayer?.startPoint = theme.backgroundGradientDirection.startPoint
        gradientLayer?.endPoint = theme.backgroundGradientDirection.endPoint

        CATransaction.commit()
    }
}
