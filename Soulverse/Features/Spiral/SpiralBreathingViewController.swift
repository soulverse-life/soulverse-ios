import Hero
import SnapKit
import UIKit

class SpiralBreathingViewController: ViewController {

    // MARK: - UI Components
    private lazy var navigationView: SoulverseNavigationView = {
        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("spiral_navigation_title", comment: "Breathing Exercise"),
            showBackButton: true
        )
        let view = SoulverseNavigationView(config: config)
        view.delegate = self
        return view
    }()

    private let spiralView = SpiralView()
    private let instructionLabel = UILabel()
    private let backgroundImageView = UIImageView()  // Optional, for atmosphere

    // MARK: - State
    enum BreathingState {
        case idle
        case inhale
        case hold
        case exhale
        case completed
    }

    private var currentState: BreathingState = .idle
    private var currentProgress: CGFloat = 0.0
    private var lastHapticProgress: CGFloat = 0.0

    // Haptics
    private let impactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Configuration
    private var actionConfig = SpiralActionConfig()

    // MARK: - Hold State Properties
    private var holdRemainingTime: TimeInterval = 20.0
    private var holdTimer: Timer?
    private var holdCycleStartTime: Date?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarController?.tabBar.isHidden = true
        holdRemainingTime = actionConfig.holdDuration
        setupUI()
        setupHeroTransitions()
        transition(to: .idle)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopHolding()
    }

    // MARK: - Setup
    private func setupUI() {
        // Navigation View
        view.addSubview(navigationView)
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }

        // Spiral View
        spiralView.translatesAutoresizingMaskIntoConstraints = false
        spiralView.backgroundColor = .clear
        // Pass config to view if needed, though view initializes its own default.
        // If we want to override view config from controller:
        // spiralView.visualConfig = ...
        view.addSubview(spiralView)

        // Instruction Label
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .center
        instructionLabel.textColor = .themeTextPrimary
        instructionLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        instructionLabel.numberOfLines = 0
        view.addSubview(instructionLabel)

        NSLayoutConstraint.activate([
            spiralView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spiralView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            // Make spiral larger: use almost full width
            spiralView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20),
            spiralView.heightAnchor.constraint(equalTo: spiralView.widthAnchor),

            instructionLabel.bottomAnchor.constraint(equalTo: spiralView.topAnchor, constant: -40),
            instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func setupHeroTransitions() {
        // Enable Hero for this view controller
        hero.isEnabled = true

    }

    // MARK: - State Management
    private func transition(to state: BreathingState) {
        currentState = state

        switch state {
        case .idle:
            instructionLabel.text = NSLocalizedString(
                "spiral_idle_instruction", comment: "Place your finger in the center of the spiral."
            )
            spiralView.setProgress(0.0, isInhale: true)
            spiralView.setHeadGlow(visible: true)
            spiralView.pulseHead()
            currentProgress = 0.0
            lastHapticProgress = 0.0

        case .inhale:
            instructionLabel.text = NSLocalizedString(
                "spiral_inhale_instruction",
                comment: "Inhale slowly and draw outward along the spiral.")
            spiralView.stopPulse()
            spiralView.setHeadGlow(visible: true)
            impactGenerator.prepare()

        case .hold:
            instructionLabel.text = NSLocalizedString(
                "spiral_hold_instruction", comment: "Hold your breath")
            spiralView.stopPulse()
            holdRemainingTime = actionConfig.holdDuration
            notificationGenerator.notificationOccurred(.success)
        // Timer starts only when user touches

        case .exhale:
            instructionLabel.text = NSLocalizedString(
                "spiral_exhale_instruction",
                comment: "Exhale gently as you trace your way back to the center.")
            spiralView.resetForExhale()
            // Reset progress for exhale logic (0 = start of exhale at outer edge)
            currentProgress = 0.0
            lastHapticProgress = 0.0
            impactGenerator.prepare()

        case .completed:
            instructionLabel.text = NSLocalizedString(
                "spiral_completion_message", comment: "Well done.")
            spiralView.setHeadGlow(visible: false)
            showCompletionAlert()
        }
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: spiralView)
        handleTouch(at: location, phase: .began)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: spiralView)
        handleTouch(at: location, phase: .moved)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        handleTouch(at: .zero, phase: .ended)
    }

    private enum TouchPhase { case began, moved, ended }

    private func handleTouch(at location: CGPoint, phase: TouchPhase) {
        // Check proximity for all states except ended
        if phase != .ended {
            let headPos = spiralView.getHeadPosition()
            let dist = hypot(location.x - headPos.x, location.y - headPos.y)

            // Strict check: must be near the current head position
            // Allow some tolerance, e.g. 44pt (60pt for moving)
            let tolerance: CGFloat = (phase == .began) ? 44.0 : 60.0

            if dist > tolerance {
                // Finger too far
                if currentState == .hold {
                    stopHolding()
                }
                return
            }
        } else {
            // Touch ended
            if currentState == .hold {
                stopHolding()
            }
            return
        }

        let (closestProgress, _) = spiralView.closestProgress(to: location)

        switch currentState {
        case .idle:
            // Must start near 0
            if closestProgress < 0.05 {
                transition(to: .inhale)
            }

        case .inhale:
            // Must be moving forward
            // Prevent jumping: change must be small
            let delta = closestProgress - currentProgress
            if delta > 0 && delta < 0.1 {
                updateProgress(closestProgress)

                // Check if reached end
                if closestProgress >= 0.99 {
                    transition(to: .hold)
                }
            }

        case .hold:
            // If we are here, touch is valid and close to head
            startHolding()

        case .exhale:
            // Exhale logic:
            // closestProgress returns 0..1 based on spiral from center to out.
            // But we are moving from out (1) to center (0).
            // So "progress" for exhale is how much we moved back.
            // Let's define exhaleProgress = 1.0 - closestProgress.
            // Start of exhale: closestProgress is ~1.0, so exhaleProgress is 0.
            // End of exhale: closestProgress is ~0.0, so exhaleProgress is 1.

            let exhaleProgress = 1.0 - closestProgress
            let delta = exhaleProgress - currentProgress

            if delta > 0 && delta < 0.1 {
                updateProgress(exhaleProgress)

                // Check if reached start (center)
                if exhaleProgress >= 0.98 {
                    transition(to: .completed)
                }
            }

        case .completed:
            break
        }
    }

    private func updateProgress(_ progress: CGFloat) {
        currentProgress = progress
        spiralView.setProgress(progress, isInhale: currentState == .inhale)

        // Haptic feedback throttling
        // Calculate physical distance moved since last haptic
        let distanceMoved = abs(progress - lastHapticProgress) * spiralView.pathLength

        if distanceMoved >= actionConfig.hapticFeedbackDistance {
            impactGenerator.impactOccurred(intensity: 0.5)
            lastHapticProgress = progress
        }
    }

    // MARK: - Hold State Logic
    private func startHolding() {
        guard currentState == .hold, holdTimer == nil else { return }

        // Start visual pulse
        spiralView.startHoldPulse()

        // Start haptic cycle
        startHapticCycle()

        // Track cycle start time for breathing guidance
        holdCycleStartTime = Date()

        // Start timers
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateHoldState()
        }
    }

    private func stopHolding() {
        // Stop visual pulse
        spiralView.stopHoldPulse()

        // Stop haptic cycle
        stopHapticCycle()

        holdTimer?.invalidate()
        holdTimer = nil
        holdCycleStartTime = nil
    }

    // MARK: - Haptic Cycle
    private var hapticCycleTimer: Timer?

    private func startHapticCycle() {
        // Immediate first beat sequence
        playHapticSequence()

        // Schedule repeats based on config cycle duration
        hapticCycleTimer = Timer.scheduledTimer(
            withTimeInterval: actionConfig.holdCycleDuration, repeats: true
        ) { [weak self] _ in
            self?.playHapticSequence()
        }
    }

    private func stopHapticCycle() {
        hapticCycleTimer?.invalidate()
        hapticCycleTimer = nil
    }

    private func playHapticSequence() {
        let totalBeats = Int(actionConfig.holdCycleUpDuration / actionConfig.hapticBeatInterval)
        guard totalBeats > 0 else { return }

        impactGenerator.impactOccurred(intensity: 1.0)

        if totalBeats > 1 {
            for i in 1..<totalBeats {
                let delay = Double(i) * actionConfig.hapticBeatInterval
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard self?.hapticCycleTimer != nil else { return }
                    self?.impactGenerator.impactOccurred(intensity: 0.5)
                }
            }
        }
    }

    private func updateHoldState() {
        holdRemainingTime -= 0.1

        // Calculate opacity: duration -> 0s maps to 1.0 -> 0.0
        let opacity = Float(max(0.0, holdRemainingTime / actionConfig.holdDuration))
        spiralView.setOpacity(opacity)

        // Update breathing guidance text based on cycle phase
        updateBreathingGuidance()

        if holdRemainingTime <= 0 {
            stopHolding()
            transition(to: .exhale)
        }
    }

    private func updateBreathingGuidance() {
        guard let startTime = holdCycleStartTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let cycleDuration = actionConfig.holdCycleDuration
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: cycleDuration)

        let upDuration = actionConfig.holdCycleUpDuration
        let pauseDuration = actionConfig.holdCyclePauseDuration

        if cycleProgress < upDuration {
            // Inhale phase
            instructionLabel.text = NSLocalizedString(
                "spiral_hold_inhale", comment: "Breathe in slowly")
        } else if cycleProgress < upDuration + pauseDuration {
            // Hold phase
            instructionLabel.text = NSLocalizedString(
                "spiral_hold_pause", comment: "Hold your breath")
        } else {
            // Exhale phase
            instructionLabel.text = NSLocalizedString(
                "spiral_hold_exhale", comment: "Breathe out slowly")
        }
    }

    private func showCompletionAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("spiral_alert_title", comment: "Congratulations"),
            message: NSLocalizedString(
                "spiral_alert_message", comment: "You have completed the breathing exercise."),
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("spiral_alert_button", comment: "OK"), style: .default,
                handler: { [weak self] _ in
                    self?.transition(to: .idle)
                }))
        present(alert, animated: true)
    }
}
