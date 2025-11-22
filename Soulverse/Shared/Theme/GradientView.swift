//
//  GradientView.swift
//  Soulverse
//

import UIKit

/// A view that displays a gradient or image background based on the current theme
class GradientView: UIView {

    // MARK: - Properties
    private var gradientLayer: CAGradientLayer?
    private var backgroundImageView: UIImageView?
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

        // Update frames without animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer?.frame = bounds
        backgroundImageView?.frame = bounds
        CATransaction.commit()

        // Check if theme has changed and update if needed
        let theme = ThemeManager.shared.currentTheme
        if theme.id != currentThemeId {
            updateBackground()
        }
    }

    // MARK: - Setup
    private func setupGradient() {
        let theme = ThemeManager.shared.currentTheme
        currentThemeId = theme.id

        // Set background color
        backgroundColor = UIColor(red: 33.0/255.0, green: 23.0/255.0, blue: 51.0/255.0, alpha: 1.0)

        // Remove existing layers/views
        gradientLayer?.removeFromSuperlayer()
        backgroundImageView?.removeFromSuperview()

        // Check if theme has background image
        if let imageName = theme.backgroundImageName, let image = UIImage(named: imageName) {
            // Use image background
            let imageView = UIImageView(frame: bounds)
            imageView.image = image
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            insertSubview(imageView, at: 0)
            backgroundImageView = imageView
        } else {
            // Use gradient background
            let gradient = CAGradientLayer()
            gradient.frame = bounds
            gradient.colors = theme.backgroundGradientColors.map { $0.cgColor }
            gradient.locations = theme.backgroundGradientLocations
            gradient.startPoint = theme.backgroundGradientDirection.startPoint
            gradient.endPoint = theme.backgroundGradientDirection.endPoint

            layer.insertSublayer(gradient, at: 0)
            gradientLayer = gradient
        }
    }

    // MARK: - Public Methods
    /// Manually update the background to match the current theme
    func updateBackground() {
        setupGradient()
    }

    /// Legacy method name for backward compatibility
    func updateGradient() {
        updateBackground()
    }
}
