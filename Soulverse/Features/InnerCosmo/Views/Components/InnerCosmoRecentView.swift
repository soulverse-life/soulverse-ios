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
        static let nearestOrbitRadius: CGFloat = 115    // Radius for the 2nd planet (closest)
        static let farthestOrbitRadius: CGFloat = 150   // Radius for the 7th planet (farthest)

        // Arc starts at ~200° (upper-left) and sweeps clockwise ~200°
        static let startAngle: Double = 1.1 * Double.pi
        static let arcSpan: Double = -1.15 * Double.pi

        static let positionRandomness: CGFloat = 3   // Slight jitter for organic feel
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

        for (index, data) in surroundingEmotions.enumerated() {
            let planetView = EmotionPlanetView(data: data)
            planetView.planetIndex = index + 1  // index 0 is central planet
            planetView.delegate = self
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

            let x = center.x + radius * CGFloat(cos(angle)) + jitterX
            let y = center.y + radius * CGFloat(sin(angle)) + jitterY

            let planetSize = planetView.calculateSize()
            planetView.bounds = CGRect(origin: .zero, size: planetSize)
            planetView.center = CGPoint(x: x, y: y)

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

// MARK: - EmotionPlanetViewDelegate

extension InnerCosmoRecentView: EmotionPlanetViewDelegate {
    func emotionPlanetViewDidTap(_ view: EmotionPlanetView, at index: Int) {
        delegate?.recentViewDidTapPlanet(self, at: index)
    }
}
