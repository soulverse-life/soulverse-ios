//
//  InnerCosmoRecentView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Delegate protocol for InnerCosmoRecentView events
protocol InnerCosmoRecentViewDelegate: AnyObject {
    func recentViewDidTapPlanet(_ view: InnerCosmoRecentView, at index: Int)
}

/// Recent view containing central planet and surrounding emotion planets
class InnerCosmoRecentView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        // Central planet configuration
        static let centralPlanetSize: CGFloat = 200        // Diameter of the central planet
        static let centralPlanetTopPadding: CGFloat = 20   // Distance from top of view to central planet

        // Horseshoe arc around central planet
        // UIKit angle: 0=right, π/2=bottom, π=left, 3π/2=top
        // Starts upper-left, sweeps clockwise through bottom to upper-right
        // Arc starts at ~200° (upper-left) and sweeps clockwise ~200°
        static let startAngle: Double = 1.1 * Double.pi
        static let arcSpan: Double = -1.15 * Double.pi

        static let positionRandomness: CGFloat = 3   // Slight jitter for organic feel
        // Extra tap area around planet circle. Also covers the ±5pt floating animation
        // offset since planetCircleCenter(in:) reads the model layer, not the presentation layer.
        static let tapHitExpansion: CGFloat = 10

        // MARK: Orbit gap (between central planet halo and nearest emotion planet halo)
        //
        // Orbit radii are computed from the actual visible halo edges of both
        // planets so the gap stays correct regardless of device, sizeMultiplier
        // randomization, or future tweaks to either component's halo. Hardcoded
        // radii were the original bug — they didn't account for the halos and
        // produced ~1pt margin at rest, which any negative jitter or floating
        // animation phase turned into a visible overlap.
        //
        // Components of `minOrbitGap`:
        //   - positionRandomness (3pt) — jitter
        //   - floating animation amplitude (5pt, from EmotionPlanetView)
        //   - visual breathing room (8pt) — keeps the haloes clearly separate
        //                                   so users perceive distinct planets
        //
        // `orbitSpread` controls how spread out the 6 surrounding planets appear
        // along the arc. Sized so the rightmost planet's halo fits within
        // iPhone SE 2nd/3rd gen width (375pt) with a small safety margin.
        static let visualBreathingRoom: CGFloat = 8
        static let orbitSpread: CGFloat = 30

        static var minOrbitGap: CGFloat {
            return positionRandomness + EmotionPlanetView.floatingAnimationAmplitude + visualBreathingRoom
        }

        /// Distance from the view's orbit center to the *visible circle center* of
        /// the closest emotion planet. Computed so that the closest planet's halo
        /// is `minOrbitGap` away from the central planet's halo:
        ///   nearestOrbitRadius = centralVisibleRadius + maxEmotionVisibleRadius + minOrbitGap
        static var nearestOrbitRadius: CGFloat {
            return CentralPlanetView.visibleRadius + EmotionPlanetView.maxVisibleRadius + minOrbitGap
        }

        /// Farthest orbit radius — `orbitSpread` further out than the nearest.
        static var farthestOrbitRadius: CGFloat {
            return nearestOrbitRadius + orbitSpread
        }
    }

    // MARK: - Properties

    weak var delegate: InnerCosmoRecentViewDelegate?

    private var emotionPlanets: [EmotionPlanetView] = []
    private var emotionData: [EmotionPlanetData] = []
    /// Saved planet positions (center + bounds) to restore after auto-layout passes
    private var savedPlanetPositions: [(center: CGPoint, bounds: CGRect)] = []
    private var hasPositionedPlanets = false

    // MARK: - UI Components

    private lazy var centralPlanetView: CentralPlanetView = {
        let view = CentralPlanetView(size: Layout.centralPlanetSize)
        return view
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
        backgroundColor = .clear
        addSubview(centralPlanetView)

        centralPlanetView.delegate = self

        // Emotion planet taps are handled at this level instead of on each EmotionPlanetView.
        // EmotionPlanetView uses translatesAutoresizingMaskIntoConstraints = false with no
        // external constraints, so Auto Layout can corrupt its frame. This makes gesture
        // recognizers on individual planets unreliable. By handling taps here and using
        // the actual rendered subview positions for hit testing, we bypass the frame issue.
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleEmotionPlanetTap(_:)))
        addGestureRecognizer(tap)

        centralPlanetView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Layout.centralPlanetTopPadding)
            make.width.height.equalTo(Layout.centralPlanetSize)
        }
    }

    // MARK: - Configuration

    /// Configure the recent view with emotion data
    /// - Parameter emotions: Array of emotion planet data (first = central, rest = surrounding)
    func configure(emotions: [EmotionPlanetData]) {
        // Configure central planet with first emotion (latest check-in)
        if let centralEmotion = emotions.first {
            centralPlanetView.configure(emotionPlanet: centralEmotion)
        }

        // Clear existing surrounding emotion planets
        emotionPlanets.forEach { $0.removeFromSuperview() }
        emotionPlanets.removeAll()
        savedPlanetPositions.removeAll()

        // Surrounding planets = remaining emotions (indices 1-6)
        let surroundingEmotions = Array(emotions.dropFirst())
        emotionData = surroundingEmotions

        for data in surroundingEmotions {
            let planetView = EmotionPlanetView(data: data)
            addSubview(planetView)
            emotionPlanets.append(planetView)
        }

        // Reset flag so planets get positioned on next layout pass
        hasPositionedPlanets = false
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !hasPositionedPlanets {
            // First layout: calculate and apply positions, then save them
            positionEmotionPlanets()
            startAnimations()
            hasPositionedPlanets = true
        } else {
            // Subsequent layouts: restore saved positions that auto-layout may have reset
            restorePlanetPositions()
        }
    }

    // MARK: - Positioning

    private func positionEmotionPlanets() {
        guard !emotionPlanets.isEmpty else { return }

        let centralPlanetCenterY = Layout.centralPlanetTopPadding + (Layout.centralPlanetSize / 2)
        let center = CGPoint(x: bounds.midX, y: centralPlanetCenterY)
        let count = emotionPlanets.count

        savedPlanetPositions.removeAll()

        for (index, planetView) in emotionPlanets.enumerated() {
            // Distribute evenly along the horseshoe arc
            let spacing = count > 1 ? Layout.arcSpan / Double(count - 1) : 0
            let angle = Layout.startAngle + spacing * Double(index)

            // Radius increases with index: nearest planet orbits tighter
            let t = count > 1 ? CGFloat(index) / CGFloat(count - 1) : 0
            let radius = Layout.nearestOrbitRadius + t * (Layout.farthestOrbitRadius - Layout.nearestOrbitRadius)

            // Add slight jitter for organic feel
            let jitterX = CGFloat.random(in: -Layout.positionRandomness...Layout.positionRandomness)
            let jitterY = CGFloat.random(in: -Layout.positionRandomness...Layout.positionRandomness)

            // Target position is for the *visible planet circle*, not the view's
            // geometric center. For non-empty planets, the inner circle is offset
            // upward inside its bounds (room for label below), so positioning by
            // view.center would let the visible circle drift toward the central
            // planet on the lower arc and away from it on the upper arc.
            let targetCircleX = center.x + radius * CGFloat(cos(angle)) + jitterX
            let targetCircleY = center.y + radius * CGFloat(sin(angle)) + jitterY

            let planetSize = planetView.calculateSize()
            planetView.bounds = CGRect(origin: .zero, size: planetSize)

            // Compute view.center such that the visible circle lands at the
            // target orbit position.
            let circleInBounds = planetView.planetCircleCenterInBounds()
            let dx = circleInBounds.x - planetSize.width / 2
            let dy = circleInBounds.y - planetSize.height / 2
            planetView.center = CGPoint(x: targetCircleX - dx, y: targetCircleY - dy)

            // Save position to restore after future layout passes
            savedPlanetPositions.append((center: planetView.center, bounds: planetView.bounds))
        }
    }

    /// Restore saved planet positions after auto-layout resets them
    private func restorePlanetPositions() {
        for (index, planetView) in emotionPlanets.enumerated() where index < savedPlanetPositions.count {
            let saved = savedPlanetPositions[index]
            planetView.bounds = saved.bounds
            planetView.center = saved.center
        }
    }

    // MARK: - Hit Testing

    /// Custom hit testing that bypasses EmotionPlanetView's potentially corrupt frame.
    ///
    /// EmotionPlanetView uses `translatesAutoresizingMaskIntoConstraints = false` for its
    /// internal SnapKit layout, but has no external Auto Layout constraints (it's positioned
    /// via manual frame setting). This causes Auto Layout to resolve its internal constraints
    /// with zero-size bounds before the parent sets the correct bounds. The internal subviews
    /// (planet circle, label) end up rendered at offset positions that don't match the view's
    /// frame. Since standard hit testing relies on the view's frame, taps on the visible planet
    /// can miss while taps on empty space can register.
    ///
    /// This override returns `self` for emotion planet taps so the gesture recognizer on
    /// InnerCosmoRecentView handles them using the actual rendered subview positions.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard !isHidden, alpha > 0.01, isUserInteractionEnabled else { return nil }

        // Emotion planets first — they render on top of the central planet's outer glow,
        // so they should have priority for overlapping areas.
        if emotionPlanetIndex(at: point) != nil {
            return self
        }

        // Central planet uses proper Auto Layout constraints, so standard hitTest works.
        let centralPoint = convert(point, to: centralPlanetView)
        if let centralHit = centralPlanetView.hitTest(centralPoint, with: event) {
            return centralHit
        }

        // Fall back to standard hit testing for any other subviews
        return super.hitTest(point, with: event)
    }

    /// Find which emotion planet the point hits.
    ///
    /// Uses `planetCircleCenter(in:)` to query the actual rendered position of each planet's
    /// circle subview, rather than relying on pre-calculated positions. This is necessary
    /// because Auto Layout resolves EmotionPlanetView's internal constraints with zero-size
    /// bounds (before the parent sets the correct bounds), causing the circle subview to
    /// render at an offset from the view's center. The offset equals bounds.width/2 horizontally.
    private func emotionPlanetIndex(at point: CGPoint) -> Int? {
        var bestIndex: Int?
        var bestDistanceSq: CGFloat = .greatestFiniteMagnitude

        for (index, planet) in emotionPlanets.enumerated() {
            let renderedCenter = planet.planetCircleCenter(in: self)
            let hitRadius = planet.planetSize / 2 + Layout.tapHitExpansion
            let dx = point.x - renderedCenter.x
            let dy = point.y - renderedCenter.y
            let distanceSq = dx * dx + dy * dy

            guard distanceSq <= hitRadius * hitRadius else { continue }

            if distanceSq < bestDistanceSq {
                bestDistanceSq = distanceSq
                bestIndex = index
            }
        }

        return bestIndex
    }

    @objc private func handleEmotionPlanetTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        if let index = emotionPlanetIndex(at: point) {
            // Planet indices: 0 = central, 1-6 = surrounding
            delegate?.recentViewDidTapPlanet(self, at: index + 1)
        }
    }

    // MARK: - Animation

    /// Start floating animations for all emotion planets
    func startAnimations() {
        for planetView in emotionPlanets {
            // Use random phase offset for each planet to avoid synchronized movement
            let phaseOffset = Double.random(in: 0...1)
            planetView.startFloatingAnimation(withPhaseOffset: phaseOffset)
        }
    }

    /// Stop all floating animations
    func stopAnimations() {
        emotionPlanets.forEach { $0.stopFloatingAnimation() }
    }
}

// MARK: - CentralPlanetViewDelegate

extension InnerCosmoRecentView: CentralPlanetViewDelegate {
    func centralPlanetViewDidTapPlanet(_ view: CentralPlanetView) {
        delegate?.recentViewDidTapPlanet(self, at: 0)
    }
}

