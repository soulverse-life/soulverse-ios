//
//  InnerCosmoRecentView.swift
//  Soulverse
//

import SnapKit
import UIKit

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

    private var emotionPlanets: [EmotionPlanetView] = []
    private var emotionData: [EmotionPlanetData] = []
    private var currentBubbleView: AffirmationBubbleView?
    private var bubbleHideTimer: Timer?
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

        // Surrounding planets = remaining emotions (indices 1-6)
        let surroundingEmotions = Array(emotions.dropFirst())
        emotionData = surroundingEmotions

        for data in surroundingEmotions {
            let planetView = EmotionPlanetView(data: data)
            addSubview(planetView)
            emotionPlanets.append(planetView)
        }

        // Reset flag so planets get positioned on next layout
        hasPositionedPlanets = false
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Only position planets once to avoid re-randomizing their positions
        if !hasPositionedPlanets {
            positionEmotionPlanets()
            startAnimations()
            hasPositionedPlanets = true
        }
    }

    // MARK: - Positioning

    private func positionEmotionPlanets() {
        guard !emotionPlanets.isEmpty else { return }

        let centralPlanetCenterY = Layout.centralPlanetTopPadding + (Layout.centralPlanetSize / 2)
        let center = CGPoint(x: bounds.midX, y: centralPlanetCenterY)
        let count = emotionPlanets.count

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

    // MARK: - Affirmation Bubble

    private func showAffirmationBubble() {
        // Remove existing bubble if any
        hideAffirmationBubble(animated: false)

        let bubbleView = AffirmationBubbleView()
        let quote = AffirmationQuoteProvider.random()
        bubbleView.configure(with: quote)

        // Speak the quote using TTS
        SpeechService.shared.speak(quote.text)

        addSubview(bubbleView)

        // Position bubble to the right of the emo pet, close to center
        bubbleView.snp.makeConstraints { make in
            make.left.equalTo(centralPlanetView.snp.centerX).offset(20)
            make.centerY.equalTo(centralPlanetView.snp.centerY).offset(-10)
        }

        currentBubbleView = bubbleView

        // Force layout to get correct frame before animation
        layoutIfNeeded()

        bubbleView.showAnimated()

        // Listen for TTS completion to dismiss bubble
        SpeechService.shared.delegate = self
    }

    private func hideAffirmationBubble(animated: Bool) {
        bubbleHideTimer?.invalidate()
        bubbleHideTimer = nil

        // Stop TTS and clear delegate
        SpeechService.shared.stop()
        SpeechService.shared.delegate = nil

        guard let bubbleView = currentBubbleView else { return }

        if animated {
            bubbleView.hideAnimated { [weak self] in
                self?.currentBubbleView = nil
            }
        } else {
            bubbleView.removeFromSuperview()
            currentBubbleView = nil
        }
    }
}

// MARK: - CentralPlanetViewDelegate

extension InnerCosmoRecentView: CentralPlanetViewDelegate {
    func centralPlanetViewDidTapEmoPet(_ view: CentralPlanetView) {
        showAffirmationBubble()
    }
}

// MARK: - SpeechServiceDelegate

extension InnerCosmoRecentView: SpeechServiceDelegate {
    func speechServiceDidFinishSpeaking(_ service: SpeechService) {
        // Dismiss bubble 0.2s after TTS finishes
        bubbleHideTimer?.invalidate()
        bubbleHideTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.hideAffirmationBubble(animated: true)
        }
    }
}
