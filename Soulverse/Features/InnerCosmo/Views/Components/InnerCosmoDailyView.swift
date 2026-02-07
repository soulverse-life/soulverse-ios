//
//  InnerCosmoDailyView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Daily view containing central planet and surrounding emotion planets
class InnerCosmoDailyView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        // Central planet configuration
        static let centralPlanetSize: CGFloat = 200        // Diameter of the central planet
        static let centralPlanetTopPadding: CGFloat = 20   // Distance from top of view to central planet

        // Orbit radius: distance from central planet center to emotion planets
        // - Increase: planets move further from center
        // - Decrease: planets move closer to center
        static let minOrbitRadius: CGFloat = 150
        static let maxOrbitRadius: CGFloat = 155

        // Semi-circular arrangement: horseshoe open at top
        // UIKit angle reference: 0=right, π/2=bottom, π=left, 3π/2=top
        //
        // startAngle: where the first emotion planet is positioned
        // - Increase (towards 1.25π): moves first planet higher (upper-left)
        // - Decrease (towards π): moves first planet lower (left side)
        static let startAngle: Double = 1.08 * Double.pi   // ~194°, slightly above left

        // arcSpan: total angle covered by all emotion planets (negative = counter-clockwise)
        // - Increase magnitude: planets spread over wider arc
        // - Decrease magnitude: planets grouped in tighter arc
        static let arcSpan: Double = -1.12 * Double.pi
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

    /// Configure the daily view with E.M.O pet name and emotion data
    /// - Parameters:
    ///   - petName: The E.M.O pet name
    ///   - emotions: Array of emotion planet data
    func configure(petName: String?, emotions: [EmotionPlanetData]) {
        centralPlanetView.configure(petName: petName)

        // Clear existing emotion planets
        emotionPlanets.forEach { $0.removeFromSuperview() }
        emotionPlanets.removeAll()

        emotionData = emotions

        // Create new emotion planets
        for data in emotions {
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

        // Center point should match the central planet's actual position
        let centralPlanetCenterY = Layout.centralPlanetTopPadding + (Layout.centralPlanetSize / 2)
        let center = CGPoint(x: bounds.midX, y: centralPlanetCenterY)
        let count = emotionPlanets.count

        // Distribute planets in a horseshoe arc (open at top)
        // From upper-right → right → bottom → left → upper-left
        for (index, planetView) in emotionPlanets.enumerated() {
            // Calculate angle for this planet within the arc span
            // Spread planets evenly across the arc, with slight randomness
            let spacing = count > 1 ? Layout.arcSpan / Double(count - 1) : 0
            let baseAngle = Layout.startAngle + spacing * Double(index)
            let angleOffset = Double.random(in: -0.15...0.15)
            let angle = baseAngle + angleOffset

            // Calculate radius with some variation
            let radius = CGFloat.random(in: Layout.minOrbitRadius...Layout.maxOrbitRadius)

            // Calculate position
            let x = center.x + radius * CGFloat(cos(angle))
            let y = center.y + radius * CGFloat(sin(angle))

            // Size the planet view
            let planetSize = planetView.calculateSize()
            planetView.bounds = CGRect(origin: .zero, size: planetSize)
            planetView.center = CGPoint(x: x, y: y)
        }
    }

    // MARK: - Animation

    /// Start floating animations for all emotion planets
    func startAnimations() {
        for (_, planetView) in emotionPlanets.enumerated() {
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

extension InnerCosmoDailyView: CentralPlanetViewDelegate {
    func centralPlanetViewDidTapEmoPet(_ view: CentralPlanetView) {
        showAffirmationBubble()
    }
}

// MARK: - SpeechServiceDelegate

extension InnerCosmoDailyView: SpeechServiceDelegate {
    func speechServiceDidFinishSpeaking(_ service: SpeechService) {
        // Dismiss bubble 0.2s after TTS finishes
        bubbleHideTimer?.invalidate()
        bubbleHideTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            self?.hideAffirmationBubble(animated: true)
        }
    }
}
