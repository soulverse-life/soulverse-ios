//
//  EmotionPlanetView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Delegate protocol for EmotionPlanetView tap events
protocol EmotionPlanetViewDelegate: AnyObject {
    func emotionPlanetViewDidTap(_ view: EmotionPlanetView, at index: Int)
}

/// Individual emotion planet view with label
class EmotionPlanetView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let baseSize: CGFloat = 36
        static let labelFontSize: CGFloat = 11
        static let labelTopPadding: CGFloat = 2
        static let animationDistance: CGFloat = 5
        static let animationDuration: TimeInterval = 2.5
        // Glass label container
        static let labelCornerRadius: CGFloat = 11
        static let labelHorizontalPadding: CGFloat = 8
        static let labelVerticalPadding: CGFloat = 4
        // Edge halo: slightly larger circle with radial gradient behind the planet
        static let haloExpand: CGFloat = 6
    }

    // MARK: - Properties

    weak var delegate: EmotionPlanetViewDelegate?
    var planetIndex: Int = 0

    private let data: EmotionPlanetData
    private let planetSize: CGFloat

    // MARK: - UI Components

    /// Radial gradient circle behind the planet — fades from color to transparent at edge
    private lazy var haloView: UIView = {
        let haloSize = planetSize + Layout.haloExpand * 2
        let view = UIView()
        view.layer.cornerRadius = haloSize / 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var haloGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    private lazy var planetView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = planetSize / 2
        view.clipsToBounds = true
        return view
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.3, y: 0.3)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    private lazy var labelContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.labelCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var labelVisualEffectView: UIVisualEffectView = {
        let view = UIVisualEffectView()
        view.layer.cornerRadius = Layout.labelCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private lazy var emotionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.labelFontSize, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization

    init(data: EmotionPlanetData) {
        self.data = data
        self.planetSize = Layout.baseSize * data.sizeMultiplier
        super.init(frame: .zero)
        setupView()
        configure(with: data)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = planetView.bounds
        haloGradientLayer.frame = haloView.bounds
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true

        addSubview(haloView)
        haloView.layer.insertSublayer(haloGradientLayer, at: 0)
        addSubview(planetView)
        addSubview(labelContainerView)

        planetView.layer.insertSublayer(gradientLayer, at: 0)

        let haloSize = planetSize + Layout.haloExpand * 2
        haloView.snp.makeConstraints { make in
            make.center.equalTo(planetView)
            make.width.height.equalTo(haloSize)
        }

        planetView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.haloExpand)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(planetSize)
        }

        labelContainerView.snp.makeConstraints { make in
            make.top.equalTo(planetView.snp.bottom).offset(Layout.labelTopPadding)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        // Setup glass effect with iOS version check
        setupLabelGlassEffect()
    }

    private func setupLabelGlassEffect() {
        if #available(iOS 26.0, *) {
            // Use UIGlassEffect for iOS 26+
            let glassEffect = UIGlassEffect()
            labelVisualEffectView.effect = glassEffect

            labelContainerView.addSubview(labelVisualEffectView)
            labelVisualEffectView.contentView.addSubview(emotionLabel)

            labelVisualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            emotionLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(Layout.labelVerticalPadding)
                make.left.right.equalToSuperview().inset(Layout.labelHorizontalPadding)
            }
        } else {
            // Fallback: semi-transparent background for earlier iOS
            labelContainerView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            labelContainerView.addSubview(emotionLabel)

            emotionLabel.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview().inset(Layout.labelVerticalPadding)
                make.left.right.equalToSuperview().inset(Layout.labelHorizontalPadding)
            }
        }
    }

    // MARK: - Configuration

    private func configure(with data: EmotionPlanetData) {
        emotionLabel.text = data.emotion

        // Accessibility
        if data.emotion.isEmpty {
            isAccessibilityElement = false
        } else {
            isAccessibilityElement = true
            accessibilityLabel = data.emotion
            accessibilityTraits = .staticText
        }

        // Hide label container when emotion text is empty
        if data.emotion.isEmpty {
            labelContainerView.isHidden = true
            labelContainerView.snp.remakeConstraints { _ in }
            planetView.snp.makeConstraints { make in
                make.bottom.equalToSuperview()
            }
        }

        // Spotlight gradient: white highlight at upper-left → base → dark edge (3D sphere)
        let baseColor = data.color
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let highlightColor = UIColor(red: min(r + 0.4, 1), green: min(g + 0.4, 1), blue: min(b + 0.4, 1), alpha: a)
        let darkerColor = UIColor(red: r * 0.6, green: g * 0.6, blue: b * 0.6, alpha: a)

        gradientLayer.colors = [
            highlightColor.cgColor,
            baseColor.cgColor,
            darkerColor.cgColor
        ]
        gradientLayer.locations = [0.0, 0.45, 1.0]

        // Halo: radial gradient from color → transparent at edge
        let haloSize = planetSize + Layout.haloExpand * 2
        let fadeStart = NSNumber(value: Double(planetSize / haloSize))
        haloGradientLayer.colors = [
            baseColor.cgColor,
            baseColor.cgColor,
            UIColor.clear.cgColor
        ]
        haloGradientLayer.locations = [0.0, fadeStart, 1.0]
    }

    // MARK: - Tap Handling

    @objc private func handleTap() {
        delegate?.emotionPlanetViewDidTap(self, at: planetIndex)
    }

    // MARK: - Animation

    /// Start floating animation
    func startFloatingAnimation(withPhaseOffset offset: Double = 0) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }

        // Remove any existing animations
        layer.removeAnimation(forKey: "floatingAnimation")

        // Create position animation
        let animation = CABasicAnimation(keyPath: "position.y")
        animation.fromValue = layer.position.y - Layout.animationDistance
        animation.toValue = layer.position.y + Layout.animationDistance
        animation.duration = Layout.animationDuration
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        // Apply phase offset
        animation.timeOffset = offset * Layout.animationDuration

        layer.add(animation, forKey: "floatingAnimation")
    }

    /// Stop floating animation
    func stopFloatingAnimation() {
        layer.removeAnimation(forKey: "floatingAnimation")
    }

    // MARK: - Size Calculation

    /// Calculate the size needed for this planet view.
    /// Must match the internal constraint chain to avoid auto-layout conflicts.
    func calculateSize() -> CGSize {
        if data.emotion.isEmpty {
            return CGSize(width: planetSize + Layout.haloExpand * 2,
                          height: planetSize + Layout.haloExpand)
        }

        let labelIntrinsicHeight = emotionLabel.intrinsicContentSize.height
        let labelContainerHeight = labelIntrinsicHeight + (Layout.labelVerticalPadding * 2)
        let totalHeight = Layout.haloExpand + planetSize + Layout.labelTopPadding + labelContainerHeight

        let labelIntrinsicWidth = emotionLabel.intrinsicContentSize.width
        let labelContainerWidth = labelIntrinsicWidth + (Layout.labelHorizontalPadding * 2)
        let width = max(planetSize + Layout.haloExpand * 2, labelContainerWidth)

        return CGSize(width: width, height: totalHeight)
    }
}
