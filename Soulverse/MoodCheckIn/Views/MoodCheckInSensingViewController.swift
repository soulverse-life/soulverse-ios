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

    private var selectedColor: UIColor = .yellow
    private var colorIntensity: Float = 0.5

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
        label.text = "Take a moment to notice your mood and\nbegin your emotional journey."
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Sensing"
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Use a color to describe your feeling today"
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
        label.text = "How strong the feeling?"
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var intensityCircles: IntensityCircleSelectorView = {
        let view = IntensityCircleSelectorView()
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
        updateIntensityCircles()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(subtitleLabel)
        view.addSubview(titleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(colorGradientSlider)
        view.addSubview(intensityLabel)
        view.addSubview(intensityCircles)
        view.addSubview(continueButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(44)
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
            make.height.equalTo(30)
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
        delegate?.moodCheckInSensingViewControllerDidTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.moodCheckInSensingViewControllerDidTapClose(self)
    }

    private func updateIntensityCircles() {
        intensityCircles.update(intensity: colorIntensity, color: selectedColor)
    }
}

// MARK: - ColorGradientSliderViewDelegate

extension MoodCheckInSensingViewController: ColorGradientSliderViewDelegate {
    func colorGradientSliderView(_ view: ColorGradientSliderView, didSelectColor color: UIColor, at position: Float) {
        selectedColor = color
        colorIntensity = position
        updateIntensityCircles()
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInSensingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        delegate?.moodCheckInSensingViewController(self, didSelectColor: selectedColor, intensity: colorIntensity)
    }
}
