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
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var progressBar: SoulverseProgressBar = {
        let bar = SoulverseProgressBar(totalSteps: 6)
        bar.setProgress(currentStep: 1)
        return bar
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_sensing_subtitle", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
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
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(progressBar)
        view.addSubview(subtitleLabel)
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(colorGradientSlider)
        view.addSubview(intensityLabel)
        view.addSubview(intensityCircles)
        view.addSubview(continueButton)

        // If this is NOT the first screen, show the close button
        if !isFirstScreen {
            view.addSubview(closeButton)
        }

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        if !isFirstScreen {
            closeButton.snp.makeConstraints { make in
                make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
                make.right.equalToSuperview().offset(-16)
                make.width.height.equalTo(44)
            }
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(40)
        }

        instructionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }

        colorGradientSlider.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(28)
        }

        intensityLabel.snp.makeConstraints { make in
            make.top.equalTo(colorGradientSlider.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }

        intensityCircles.snp.makeConstraints { make in
            make.top.equalTo(intensityLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(60)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
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

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
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
