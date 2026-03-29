//
//  CentralPlanetView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Delegate protocol for CentralPlanetView tap events
protocol CentralPlanetViewDelegate: AnyObject {
    func centralPlanetViewDidTapPlanet(_ view: CentralPlanetView)
}

/// Central planet view showing emotion gradient with E.M.O pet overlay
class CentralPlanetView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let outerGlowAlpha: CGFloat = 0.3
        static let innerDiameter: CGFloat = 160

        static let emoPetImageSize: CGFloat = 64
        static let emoPetImageCenterYOffset: CGFloat = -8

        static let emotionLabelFontSize: CGFloat = 11

        // Edge halo: slightly larger circle with radial gradient behind inner planet
        static let haloExpand: CGFloat = 8

        static let tapScaleDown: CGFloat = 0.9
        static let tapAnimationDuration: TimeInterval = 0.1

        // Affirmation bubble positioning (relative to center)
        static let bubbleLeftOffset: CGFloat = 20
        static let bubbleCenterYOffset: CGFloat = -10
        static let bubbleHideDelay: TimeInterval = 0.2
    }

    // MARK: - Properties

    weak var delegate: CentralPlanetViewDelegate?
    private let size: CGFloat
    private var currentBubbleView: AffirmationBubbleView?
    private var bubbleHideTimer: Timer?

    // MARK: - UI Components

    private lazy var outerGlowView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private lazy var outerGlowGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    /// Radial gradient circle behind inner planet — fades from color to transparent
    private lazy var haloView: UIView = {
        let haloSize = Layout.innerDiameter + Layout.haloExpand * 2
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

    private lazy var innerPlanetView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        view.layer.cornerRadius = Layout.innerDiameter / 2
        return view
    }()

    private lazy var emotionGradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.type = .radial
        gradient.startPoint = CGPoint(x: 0.3, y: 0.3)
        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
        return gradient
    }()

    private lazy var emoPetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "basic_first_level")
        return imageView
    }()

    private lazy var emotionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.emotionLabelFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization

    init(size: CGFloat) {
        self.size = size
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        outerGlowView.layer.cornerRadius = size / 2
        outerGlowGradientLayer.frame = outerGlowView.bounds
        haloGradientLayer.frame = haloView.bounds
        emotionGradientLayer.frame = innerPlanetView.bounds
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .clear
        clipsToBounds = false

        addSubview(outerGlowView)
        outerGlowView.layer.insertSublayer(outerGlowGradientLayer, at: 0)
        addSubview(haloView)
        haloView.layer.insertSublayer(haloGradientLayer, at: 0)
        addSubview(innerPlanetView)
        innerPlanetView.layer.insertSublayer(emotionGradientLayer, at: 0)
        innerPlanetView.addSubview(emoPetImageView)
        innerPlanetView.addSubview(emotionLabel)

        isUserInteractionEnabled = true
        setupTapGesture()

        outerGlowView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(size)
        }

        let haloSize = Layout.innerDiameter + Layout.haloExpand * 2
        haloView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(haloSize)
        }

        innerPlanetView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.innerDiameter)
        }

        emoPetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(Layout.emoPetImageCenterYOffset)
            make.width.height.equalTo(Layout.emoPetImageSize)
        }

        emotionLabel.snp.makeConstraints { make in
            make.top.equalTo(emoPetImageView.snp.bottom)
            make.centerX.equalToSuperview()
        }
    }

    // MARK: - Tap Gesture

    private func setupTapGesture() {
        // EmoPet image tap → affirmation bubble
        let emoPetTap = UITapGestureRecognizer(target: self, action: #selector(handleEmoPetTap))
        emoPetImageView.addGestureRecognizer(emoPetTap)
        emoPetImageView.isUserInteractionEnabled = true

        // Planet tap (outside emoPet) → navigation
        let planetTap = UITapGestureRecognizer(target: self, action: #selector(handlePlanetTap))
        innerPlanetView.addGestureRecognizer(planetTap)
        innerPlanetView.isUserInteractionEnabled = true
    }

    @objc private func handleEmoPetTap() {
        guard currentBubbleView == nil else { return }
        animateTap()
        showAffirmationBubble()
    }

    @objc private func handlePlanetTap() {
        delegate?.centralPlanetViewDidTapPlanet(self)
    }

    private func animateTap() {
        UIView.animate(
            withDuration: Layout.tapAnimationDuration,
            delay: 0,
            options: .curveEaseIn
        ) {
            self.emoPetImageView.transform = CGAffineTransform(scaleX: Layout.tapScaleDown, y: Layout.tapScaleDown)
        } completion: { _ in
            UIView.animate(
                withDuration: Layout.tapAnimationDuration,
                delay: 0,
                options: .curveEaseOut
            ) {
                self.emoPetImageView.transform = .identity
            }
        }
    }

    // MARK: - Configuration

    /// Configure the central planet with emotion data (gradient circle + outer glow + emotion label)
    func configure(emotionPlanet data: EmotionPlanetData) {
        let baseColor = data.color

        // Spotlight gradient: highlight at upper-left → base → dark edge
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let highlightColor = UIColor(red: min(r + 0.4, 1), green: min(g + 0.4, 1), blue: min(b + 0.4, 1), alpha: a)
        let darkerColor = UIColor(red: r * 0.6, green: g * 0.6, blue: b * 0.6, alpha: a)
        emotionGradientLayer.colors = [
            highlightColor.cgColor,
            baseColor.cgColor,
            darkerColor.cgColor
        ]
        emotionGradientLayer.locations = [0.0, 0.45, 1.0]

        // Outer glow: faded radial gradient of the same color
        outerGlowGradientLayer.colors = [
            baseColor.withAlphaComponent(Layout.outerGlowAlpha).cgColor,
            baseColor.withAlphaComponent(Layout.outerGlowAlpha * 0.5).cgColor,
            UIColor.clear.cgColor
        ]

        // Halo: radial gradient from color → transparent at edge
        let haloSize = Layout.innerDiameter + Layout.haloExpand * 2
        let fadeStart = NSNumber(value: Double(Layout.innerDiameter / haloSize))
        haloGradientLayer.colors = [
            baseColor.cgColor,
            baseColor.cgColor,
            UIColor.clear.cgColor
        ]
        haloGradientLayer.locations = [0.0, fadeStart, 1.0]

        if data.emotion.isEmpty {
            emotionLabel.isHidden = true
            accessibilityLabel = nil
        } else {
            emotionLabel.isHidden = false
            emotionLabel.text = data.emotion
            accessibilityLabel = data.emotion
        }
    }

    // MARK: - Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: size, height: size)
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
        layer.zPosition = 1

        // Position bubble to the right of the emo pet, close to center
        bubbleView.snp.makeConstraints { make in
            make.left.equalTo(self.snp.centerX).offset(Layout.bubbleLeftOffset)
            make.centerY.equalTo(self.snp.centerY).offset(Layout.bubbleCenterYOffset)
        }

        currentBubbleView = bubbleView

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

        // Clear reference immediately to avoid race with rapid taps
        currentBubbleView = nil

        if animated {
            bubbleView.hideAnimated { [weak self] in
                self?.layer.zPosition = 0
            }
        } else {
            bubbleView.removeFromSuperview()
            layer.zPosition = 0
        }
    }
}

// MARK: - SpeechServiceDelegate

extension CentralPlanetView: SpeechServiceDelegate {
    func speechServiceDidFinishSpeaking(_ service: SpeechService) {
        bubbleHideTimer?.invalidate()
        bubbleHideTimer = Timer.scheduledTimer(withTimeInterval: Layout.bubbleHideDelay, repeats: false) { [weak self] _ in
            self?.hideAffirmationBubble(animated: true)
        }
    }
}
