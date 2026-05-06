//
//  EmotionPlanetView.swift
//  Soulverse
//

import SnapKit
import UIKit

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

    /// Maximum sizeMultiplier used by callers (placeholder planets randomize 0.7–1.1).
    /// Parent layouts that need to reserve space for the worst-case planet size
    /// should reference this constant rather than guessing.
    static let maxSizeMultiplier: CGFloat = 1.1

    /// Outermost visible edge (inner circle + halo glow) of the largest possible
    /// emotion planet, measured from the planet circle's center. Used by parent
    /// layouts to compute orbit gaps that work for all sizeMultiplier values.
    static let maxVisibleRadius: CGFloat = (Layout.baseSize * maxSizeMultiplier) / 2 + Layout.haloExpand

    /// Floating animation amplitude in points (vertical, ±). Exposed so parents
    /// can include it in safety gaps for orbit calculations.
    static let floatingAnimationAmplitude: CGFloat = Layout.animationDistance

    // MARK: - Properties

    private let data: EmotionPlanetData
    /// Internal access for parent hit testing (see InnerCosmoRecentView.emotionPlanetIndex)
    let planetSize: CGFloat

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

        // Hide label container when emotion text is empty and re-center the
        // planet so the halo sits symmetrically around it (matches the
        // CheckInDetail planet layout). The default planet position is
        // top-aligned to leave room for the label below; without a label
        // there's no reason to bias upward.
        if data.emotion.isEmpty {
            labelContainerView.isHidden = true
            labelContainerView.snp.remakeConstraints { _ in }
            planetView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.height.equalTo(planetSize)
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

    // MARK: - Hit Testing

    /// Returns the planet circle's actual rendered center in the given view's coordinate system.
    /// Used by InnerCosmoRecentView for hit testing, because the internal subview positions
    /// can diverge from the view's frame due to Auto Layout resolving constraints with
    /// zero-size bounds before the parent sets the correct bounds.
    func planetCircleCenter(in targetView: UIView) -> CGPoint {
        let localCenter = CGPoint(x: planetView.frame.midX, y: planetView.frame.midY)
        return convert(localCenter, to: targetView)
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
    ///
    /// The bounds match the internal SnapKit layout exactly:
    /// - Vertical: `haloExpand` (top) + `planetSize` + `labelTopPadding` + label container
    /// - Horizontal: max of the planet+halo footprint and the label container
    ///
    /// Including `haloExpand` in the height/width is critical: the inner planet
    /// circle is constrained `top.offset(haloExpand)`, so a bounds.height that
    /// omits `haloExpand` would force AutoLayout to squeeze the label container
    /// AND make the visible circle render at an offset from `bounds.midY` —
    /// which breaks orbit positioning in `InnerCosmoRecentView`.
    func calculateSize() -> CGSize {
        if data.emotion.isEmpty {
            // Symmetric square — planet is centered, halo on all sides.
            let bound = planetSize + Layout.haloExpand * 2
            return CGSize(width: bound, height: bound)
        }

        let labelIntrinsicHeight = emotionLabel.intrinsicContentSize.height
        let labelContainerHeight = labelIntrinsicHeight + (Layout.labelVerticalPadding * 2)
        let totalHeight = Layout.haloExpand + planetSize + Layout.labelTopPadding + labelContainerHeight

        let labelIntrinsicWidth = emotionLabel.intrinsicContentSize.width
        let labelContainerWidth = labelIntrinsicWidth + (Layout.labelHorizontalPadding * 2)
        // Halo extends ±haloExpand outside the planet circle on the sides too.
        let planetWithHaloWidth = planetSize + Layout.haloExpand * 2
        let width = max(planetWithHaloWidth, labelContainerWidth)

        return CGSize(width: width, height: totalHeight)
    }

    /// Center of the visible planet circle in this view's local (bounds) coordinates,
    /// for the bounds returned by `calculateSize()`. Parents should use this to
    /// position the *visible circle* at a target point (e.g. an orbit position),
    /// rather than the view's geometric center which differs for non-empty planets.
    func planetCircleCenterInBounds() -> CGPoint {
        let size = calculateSize()
        if data.emotion.isEmpty {
            return CGPoint(x: size.width / 2, y: size.height / 2)
        }
        // Inner circle is constrained `top.offset(haloExpand)` and `centerX.equalToSuperview()`.
        return CGPoint(x: size.width / 2, y: Layout.haloExpand + planetSize / 2)
    }
}
