//
//  ColorGradientSliderView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

protocol ColorGradientSliderViewDelegate: AnyObject {
    func colorGradientSliderView(_ view: ColorGradientSliderView, didSelectColor color: UIColor, at position: Float)
}

class ColorGradientSliderView: UIView {

    // MARK: - Properties

    weak var delegate: ColorGradientSliderViewDelegate?

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)

        // Rainbow gradient colors
        layer.colors = [
            UIColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 1).cgColor,    // Red
            UIColor(red: 255/255, green: 183/255, blue: 77/255, alpha: 1).cgColor,   // Orange
            UIColor(red: 255/255, green: 235/255, blue: 59/255, alpha: 1).cgColor,   // Yellow
            UIColor(red: 118/255, green: 209/255, blue: 145/255, alpha: 1).cgColor,  // Green
            UIColor(red: 103/255, green: 183/255, blue: 220/255, alpha: 1).cgColor,  // Blue
            UIColor(red: 138/255, green: 129/255, blue: 207/255, alpha: 1).cgColor   // Purple
        ]

        layer.cornerRadius = 15
        return layer
    }()

    private lazy var slider: SummitSlider = {
        let slider = SummitSlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        slider.minimumTrackTintColor = .clear
        slider.maximumTrackTintColor = .clear
        slider.thumbTintColor = .white
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
        // Add gradient layer
        layer.addSublayer(gradientLayer)

        // Add slider on top
        addSubview(slider)
        slider.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Public Methods

    /// Get the currently selected color based on slider position
    var selectedColor: UIColor {
        return getColorAt(position: slider.value)
    }

    /// Get the current slider position (0.0 to 1.0)
    var currentPosition: Float {
        return slider.value
    }

    /// Set the slider position programmatically
    func setPosition(_ position: Float) {
        slider.value = position
        notifyDelegate()
    }

    // MARK: - Private Methods

    @objc private func sliderValueChanged() {
        notifyDelegate()
    }

    private func notifyDelegate() {
        let color = selectedColor
        delegate?.colorGradientSliderView(self, didSelectColor: color, at: slider.value)
    }

    /// Calculate color at specific position on the gradient
    private func getColorAt(position: Float) -> UIColor {
        // Map position to color gradient
        let colors = [
            UIColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 1),    // Red
            UIColor(red: 255/255, green: 183/255, blue: 77/255, alpha: 1),   // Orange
            UIColor(red: 255/255, green: 235/255, blue: 59/255, alpha: 1),   // Yellow
            UIColor(red: 118/255, green: 209/255, blue: 145/255, alpha: 1),  // Green
            UIColor(red: 103/255, green: 183/255, blue: 220/255, alpha: 1),  // Blue
            UIColor(red: 138/255, green: 129/255, blue: 207/255, alpha: 1)   // Purple
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
