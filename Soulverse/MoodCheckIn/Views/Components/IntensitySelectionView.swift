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

/// A view that allows users to select emotion intensity
/// Contains a title, slider with snap-to positions, and intensity level labels
class IntensitySelectionView: UIView {

    // MARK: - Properties

    weak var delegate: IntensitySelectionViewDelegate?

    private var currentEmotion: EmotionType?
    private var emotionIntensity: Double = 0.5

    // MARK: - Layout Constants

    private enum Layout {
        static let titleToSliderSpacing: CGFloat = 12
        static let sliderToLabelsSpacing: CGFloat = 4
    }

    // MARK: - UI Elements

    private lazy var intensityTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var intensitySlider: SummitSlider = {
        let slider = SummitSlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        slider.addTarget(self, action: #selector(intensitySliderChanged), for: .valueChanged)
        slider.addTarget(self, action: #selector(intensitySliderReleased), for: .touchUpInside)
        slider.addTarget(self, action: #selector(intensitySliderReleased), for: .touchUpOutside)
        return slider
    }()

    private lazy var intensityLeftLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var intensityCenterLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var intensityRightLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        return label
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
        addSubview(intensityTitleLabel)
        addSubview(intensitySlider)
        addSubview(intensityLeftLabel)
        addSubview(intensityCenterLabel)
        addSubview(intensityRightLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        intensityTitleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        intensitySlider.snp.makeConstraints { make in
            make.top.equalTo(intensityTitleLabel.snp.bottom).offset(Layout.titleToSliderSpacing)
            make.left.right.equalToSuperview()
        }

        intensityLeftLabel.snp.makeConstraints { make in
            make.left.equalTo(intensitySlider)
            make.top.equalTo(intensitySlider.snp.bottom).offset(Layout.sliderToLabelsSpacing)
            make.bottom.equalToSuperview()
        }

        intensityCenterLabel.snp.makeConstraints { make in
            make.centerX.equalTo(intensitySlider)
            make.top.equalTo(intensitySlider.snp.bottom).offset(Layout.sliderToLabelsSpacing)
        }

        intensityRightLabel.snp.makeConstraints { make in
            make.right.equalTo(intensitySlider)
            make.top.equalTo(intensitySlider.snp.bottom).offset(Layout.sliderToLabelsSpacing)
        }
    }

    // MARK: - Actions

    @objc private func intensitySliderChanged() {
        emotionIntensity = Double(intensitySlider.value)
        if let emotion = currentEmotion {
            delegate?.didChangeIntensity(self, emotion: emotion, intensity: emotionIntensity)
        }
    }

    @objc private func intensitySliderReleased() {
        // Snap to nearest discrete position: 0.0, 0.5, 1.0
        let currentValue = intensitySlider.value
        let snappedValue: Float

        if currentValue < 0.25 {
            snappedValue = 0.0
        } else if currentValue < 0.75 {
            snappedValue = 0.5
        } else {
            snappedValue = 1.0
        }

        intensitySlider.setValue(snappedValue, animated: true)
        emotionIntensity = Double(snappedValue)
        if let emotion = currentEmotion {
            delegate?.didChangeIntensity(self, emotion: emotion, intensity: emotionIntensity)
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
        intensityLeftLabel.text = labels.left
        intensityCenterLabel.text = labels.center
        intensityRightLabel.text = labels.right
    }

    /// Get the currently selected intensity value
    /// - Returns: Intensity value between 0.0 and 1.0
    func getIntensity() -> Double {
        return emotionIntensity
    }
}
