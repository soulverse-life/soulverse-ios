//
//  IntensitySelectionView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

/// Delegate protocol for intensity selection events
protocol IntensitySelectionViewDelegate: AnyObject {
    func didChangeIntensity(_ view: IntensitySelectionView, emotion: EmotionType, intensity: Double)
}

/// A view that allows users to select emotion intensity using three tappable circles
/// Contains a title, horizontal line with three circles, and intensity level labels
class IntensitySelectionView: UIView {

    // MARK: - Properties

    weak var delegate: IntensitySelectionViewDelegate?

    private var currentEmotion: EmotionType?
    private var emotionIntensity: Double = 0.5
    private var selectedIndex: Int = 1  // Default to middle (medium intensity)

    // MARK: - Layout Constants

    private enum Layout {
        static let titleToCirclesSpacing: CGFloat = 16
        static let circleToLabelSpacing: CGFloat = 8
        static let circleSize: CGFloat = 20
        static let lineHeight: CGFloat = 3
        static let circlesContainerWidth: CGFloat = 320
        static let circleTag: Int = 100
        static let glassEffectTag: Int = 101
    }

    // MARK: - UI Elements

    private lazy var intensityTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 17, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var connectionLine: UIView = {
        let view = UIView()
        view.backgroundColor = .themeTextPrimary
        return view
    }()

    private lazy var circlesContainer: UIView = {
        let view = UIView()
        return view
    }()

    private var circleViews: [UIView] = []
    private var labelViews: [UILabel] = []

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
        addSubview(intensityTitleLabel)
        addSubview(circlesContainer)
        circlesContainer.addSubview(connectionLine)

        // Create three circles with labels
        for index in 0..<3 {
            let (circleContainer, label) = createCircleWithLabel(at: index)
            circlesContainer.addSubview(circleContainer)
            circleViews.append(circleContainer)
            labelViews.append(label)
        }

        setupConstraints()
        updateSelection()
    }

    private func createCircleWithLabel(at index: Int) -> (UIView, UILabel) {
        // Container for tap gesture
        let container = UIView()
        container.tag = index
        container.isUserInteractionEnabled = true

        // Circle view (base layer with background color)
        let circle = UIView()
        circle.tag = Layout.circleTag
        circle.layer.cornerRadius = Layout.circleSize / 2
        circle.clipsToBounds = true
        circle.isUserInteractionEnabled = false  // Let taps pass through to container
        container.addSubview(circle)

        // Glass effect view (overlay for iOS 26+)
        if #available(iOS 26.0, *) {
            let glassEffectView = UIVisualEffectView()
            glassEffectView.tag = Layout.glassEffectTag
            glassEffectView.clipsToBounds = true
            glassEffectView.layer.cornerRadius = Layout.circleSize / 2
            glassEffectView.isUserInteractionEnabled = false
            glassEffectView.isHidden = true  // Initially hidden, shown when selected
            circle.addSubview(glassEffectView)

            glassEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        // Label below the circle
        let label = UILabel()
        label.font = .projectFont(ofSize: 15, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.isUserInteractionEnabled = false  // Let taps pass through to container
        container.addSubview(label)

        // Circle constraints
        circle.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(Layout.circleSize)
        }

        // Label constraints - use left/right to give container width
        label.snp.makeConstraints { make in
            make.top.equalTo(circle.snp.bottom).offset(Layout.circleToLabelSpacing)
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        // Add tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(circleTapped(_:)))
        container.addGestureRecognizer(tapGesture)

        return (container, label)
    }

    private func setupConstraints() {
        intensityTitleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        circlesContainer.snp.makeConstraints { make in
            make.top.equalTo(intensityTitleLabel.snp.bottom).offset(Layout.titleToCirclesSpacing)
            make.centerX.equalToSuperview()
            make.width.equalTo(Layout.circlesContainerWidth)
            make.bottom.equalToSuperview()
        }

        // Connection line - spans between left and right circles
        connectionLine.snp.makeConstraints { make in
            make.left.equalTo(circleViews[0].snp.centerX)
            make.right.equalTo(circleViews[2].snp.centerX)
            make.centerY.equalTo(circleViews[0].snp.top).offset(Layout.circleSize / 2)
            make.height.equalTo(Layout.lineHeight)
        }

        // Position circles: left, center, right
        circleViews[0].snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
        }

        circleViews[1].snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }

        circleViews[2].snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Actions

    @objc private func circleTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        let index = tappedView.tag

        // Update selected index
        selectedIndex = index
        emotionIntensity = intensityForIndex(index)
        updateSelection()

        // Notify delegate
        if let emotion = currentEmotion {
            delegate?.didChangeIntensity(self, emotion: emotion, intensity: emotionIntensity)
        }
    }

    // MARK: - Private Methods

    private func updateSelection() {
        for (index, container) in circleViews.enumerated() {
            let isSelected = index == selectedIndex
            guard let circleView = container.viewWithTag(Layout.circleTag) else { continue }

            UIView.animate(withDuration: 0.2) {
                if isSelected {
                    circleView.backgroundColor = .themeButtonPrimaryBackground
                    self.labelViews[index].font = .projectFont(ofSize: 15, weight: .semibold)
                } else {
                    circleView.backgroundColor = .themeCircleUnselectedBackground
                    self.labelViews[index].font = .projectFont(ofSize: 15, weight: .regular)
                }
            }

            // Apply glass effect on iOS 26+
            applyGlassEffect(to: circleView, enabled: isSelected)
        }
    }

    private func applyGlassEffect(to circleView: UIView, enabled: Bool) {
        if #available(iOS 26.0, *) {
            guard let glassEffectView = circleView.viewWithTag(Layout.glassEffectTag) as? UIVisualEffectView else { return }

            if enabled {
                let glassEffect = UIGlassEffect(style: .clear)
                glassEffectView.effect = glassEffect
                glassEffectView.isHidden = false
            } else {
                glassEffectView.effect = nil
                glassEffectView.isHidden = true
            }
        }
    }

    private func intensityForIndex(_ index: Int) -> Double {
        switch index {
        case 0: return 0.0
        case 1: return 0.5
        case 2: return 1.0
        default: return 0.5
        }
    }

    // MARK: - Public Methods

    /// Configure the view for a specific emotion
    /// Updates the title and intensity level labels based on the emotion
    /// - Parameter emotion: The emotion type to configure for
    func configure(emotion: EmotionType) {
        currentEmotion = emotion

        let titleFormat = NSLocalizedString("mood_checkin_naming_intensity_title", comment: "")
        intensityTitleLabel.text = String(format: titleFormat, emotion.displayName)

        let labels = emotion.intensityLabels
        labelViews[0].text = labels.left
        labelViews[1].text = labels.center
        labelViews[2].text = labels.right

        // Reset to default selection (middle)
        selectedIndex = 1
        emotionIntensity = 0.5
        updateSelection()
    }

    /// Get the currently selected intensity value
    /// - Returns: Intensity value: 0.0 (low), 0.5 (medium), or 1.0 (high)
    func getIntensity() -> Double {
        return emotionIntensity
    }
}
