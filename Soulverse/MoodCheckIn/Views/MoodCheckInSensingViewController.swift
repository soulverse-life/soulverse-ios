//
//  MoodCheckInSensingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class MoodCheckInSensingViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInSensingViewControllerDelegate?

    /// Indicates if this is the first screen (Pet screen was skipped)
    var isFirstScreen: Bool = false

    private var selectedColor: UIColor = .yellow
    private var selectedIntensity: Double = 0.5 // Default to middle intensity

    // MARK: - UI Elements

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: "naviconBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .center
            button.imageView?.clipsToBounds = false
            button.clipsToBounds = false
        } else {
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            button.tintColor = .themeTextPrimary
        }
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var progressBar: SoulverseProgressBar = {
        let bar = SoulverseProgressBar(totalSteps: MoodCheckInLayout.totalSteps)
        bar.setProgress(currentStep: 1)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_sensing_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_sensing_instruction", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var colorGradientSlider: ColorGradientSliderView = {
        let slider = ColorGradientSliderView()
        slider.delegate = self
        return slider
    }()

    private lazy var intensityLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_sensing_intensity", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var intensityCircles: IntensityCircleSelectorView = {
        let view = IntensityCircleSelectorView()
        view.delegate = self
        return view
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(title: "Continue", style: .primary, delegate: self)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        // Initialize circles with default color
        intensityCircles.updateColor(selectedColor)
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(colorGradientSlider)
        view.addSubview(intensityLabel)
        view.addSubview(intensityCircles)
        view.addSubview(continueButton)


        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(MoodCheckInLayout.navigationTopOffset)
            make.left.equalToSuperview().offset(MoodCheckInLayout.navigationLeftOffset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.width.equalTo(ViewComponentConstants.onboardingProgressViewWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(MoodCheckInLayout.titleTopOffset)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        colorGradientSlider.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.height.equalTo(MoodCheckInLayout.colorSliderHeight)
        }

        intensityLabel.snp.makeConstraints { make in
            make.top.equalTo(colorGradientSlider.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        intensityCircles.snp.makeConstraints { make in
            make.top.equalTo(intensityLabel.snp.bottom).offset(MoodCheckInLayout.titleToSubtitleSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.height.equalTo(MoodCheckInLayout.intensityCirclesHeight)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MoodCheckInLayout.bottomPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        if isFirstScreen {
            // If this is the first screen, back button acts as close button
            delegate?.didTapClose(self)
        } else {
            // Otherwise, normal back behavior
            delegate?.didTapBack(self)
        }
    }
}

// MARK: - ColorGradientSliderViewDelegate

extension MoodCheckInSensingViewController: ColorGradientSliderViewDelegate {
    func didSelectColor(_ view: ColorGradientSliderView, color: UIColor, position: Double) {
        // Update selected color and update circle colors (but not selection)
        selectedColor = color
        intensityCircles.updateColor(color)
    }
}

// MARK: - IntensityCircleSelectorViewDelegate

extension MoodCheckInSensingViewController: IntensityCircleSelectorViewDelegate {
    func didSelectIntensity(_ view: IntensityCircleSelectorView, intensity: Double) {
        // Update selected intensity when user taps a circle
        selectedIntensity = intensity
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInSensingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        // Pass both the selected color and the selected intensity
        delegate?.didSelectColor(self, color: selectedColor, intensity: selectedIntensity)
    }
}
