//
//  ColorGradientSliderView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

protocol ColorGradientSliderViewDelegate: AnyObject {
    func didSelectColor(_ view: ColorGradientSliderView, color: UIColor, position: Double)
}

class ColorGradientSliderView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let gradientBarHeight: CGFloat = 30  // Gradient bar height
        static let sliderHeight: CGFloat = 60       // Slider height to accommodate larger thumb
        static let thumbSize: CGFloat = 50          // Circular thumb diameter
    }

    // MARK: - Properties

    weak var delegate: ColorGradientSliderViewDelegate?

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)

        // Rainbow gradient colors
        layer.colors = [
            UIColor(red: 255.0/255.0, green: 82.0/255.0, blue: 82.0/255.0, alpha: 1).cgColor,    // Red
            UIColor(red: 255.0/255.0, green: 183.0/255.0, blue: 77.0/255.0, alpha: 1).cgColor,   // Orange
            UIColor(red: 255.0/255.0, green: 235.0/255.0, blue: 59.0/255.0, alpha: 1).cgColor,   // Yellow
            UIColor(red: 118.0/255.0, green: 209.0/255.0, blue: 145.0/255.0, alpha: 1).cgColor,  // Green
            UIColor(red: 103.0/255.0, green: 183.0/255.0, blue: 220.0/255.0, alpha: 1).cgColor,  // Blue
            UIColor(red: 138.0/255.0, green: 129.0/255.0, blue: 207.0/255.0, alpha: 1).cgColor   // Purple
        ]

        layer.cornerRadius = Layout.gradientBarHeight / 2
        return layer
    }()

    private lazy var slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear

        // Set initial thumb image with color
        let initialColor = getColorAt(position: 0.5)
        updateThumbImage(color: initialColor, for: slider)

        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
        return slider
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
        // Add gradient layer (thin bar)
        layer.addSublayer(gradientLayer)

        // Add slider on top (taller to accommodate thumb)
        addSubview(slider)
        slider.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.sliderHeight)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Position gradient bar in the center vertically
        let gradientY = (bounds.height - Layout.gradientBarHeight) / 2
        gradientLayer.frame = CGRect(
            x: 0,
            y: gradientY,
            width: bounds.width,
            height: Layout.gradientBarHeight
        )
    }

    // MARK: - Public Methods

    /// Get the currently selected color based on slider position
    var selectedColor: UIColor {
        return getColorAt(position: slider.value)
    }

    /// Get the current slider position (0.0 to 1.0)
    var currentPosition: Double {
        return Double(slider.value)
    }

    /// Set the slider position programmatically
    func setPosition(_ position: Double) {
        slider.value = Float(position)
        notifyDelegate()
    }

    // MARK: - Private Methods

    @objc private func sliderValueChanged() {
        // Update thumb image with new color
        updateThumbImage(color: selectedColor, for: slider)
        notifyDelegate()
    }

    /// Creates a circular thumb image with the given color
    private func updateThumbImage(color: UIColor, for slider: UISlider) {
        let thumbImage = createCircularThumbImage(color: color, size: Layout.thumbSize)
        slider.setThumbImage(thumbImage, for: .normal)
        slider.setThumbImage(thumbImage, for: .highlighted)
    }

    private func createCircularThumbImage(color: UIColor, size: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { context in
            let rect = CGRect(x: 0, y: 0, width: size, height: size)
            color.setFill()
            context.cgContext.fillEllipse(in: rect)
        }
    }

    private func notifyDelegate() {
        let color = selectedColor
        delegate?.didSelectColor(self, color: color, position: Double(slider.value))
    }

    /// Calculate color at specific position on the gradient
    private func getColorAt(position: Float) -> UIColor {
        // Map position to color gradient
        let colors = [
            UIColor(red: 255.0/255.0, green: 82.0/255.0, blue: 82.0/255.0, alpha: 1),    // Red
            UIColor(red: 255.0/255.0, green: 183.0/255.0, blue: 77.0/255.0, alpha: 1),   // Orange
            UIColor(red: 255.0/255.0, green: 235.0/255.0, blue: 59.0/255.0, alpha: 1),   // Yellow
            UIColor(red: 118.0/255.0, green: 209.0/255.0, blue: 145.0/255.0, alpha: 1),  // Green
            UIColor(red: 103.0/255.0, green: 183.0/255.0, blue: 220.0/255.0, alpha: 1),  // Blue
            UIColor(red: 138.0/255.0, green: 129.0/255.0, blue: 207.0/255.0, alpha: 1)   // Purple
        ]

        let clampedPosition = max(0, min(1, position))
        let scaledPosition = clampedPosition * Float(colors.count - 1)
        let index = Int(scaledPosition)
        let fraction = CGFloat(scaledPosition - Float(index))

        // Interpolate between colors
        if index >= colors.count - 1 {
            return colors.last!
        }

        let color1 = colors[index]
        let color2 = colors[index + 1]

        return interpolateColor(from: color1, to: color2, fraction: fraction)
    }

    private func interpolateColor(from color1: UIColor, to color2: UIColor, fraction: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(
            red: r1 + (r2 - r1) * fraction,
            green: g1 + (g2 - g1) * fraction,
            blue: b1 + (b2 - b1) * fraction,
            alpha: a1 + (a2 - a1) * fraction
        )
    }
}
