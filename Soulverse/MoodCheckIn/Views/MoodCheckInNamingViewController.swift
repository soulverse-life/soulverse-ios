//
//  MoodCheckInNamingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class MoodCheckInNamingViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInNamingViewControllerDelegate?

    private var selectedEmotion: EmotionType?
    private var emotionIntensity: Double = 0.5

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
        bar.setProgress(currentStep: 2)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Naming"
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var colorDisplayView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.backgroundColor = .yellow
        return view
    }()

    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = "You choose yellow"
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.text = "What emotion does this color bring to your mind?"
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var emotionTagsView: SoulverseTagsView = {
        let config = SoulverseTagsViewConfig(horizontalSpacing: 12, verticalSpacing: 12, itemHeight: 44)
        let view = SoulverseTagsView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var intensityTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Joy Intensity"
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
        return slider
    }()

    private lazy var intensityLeftLabel: UILabel = {
        let label = UILabel()
        label.text = "Serenity"
        label.font = .projectFont(ofSize: 12, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var intensityCenterLabel: UILabel = {
        let label = UILabel()
        label.text = "Joy"
        label.font = .projectFont(ofSize: 12, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var intensityRightLabel: UILabel = {
        let label = UILabel()
        label.text = "Ecstasy"
        label.font = .projectFont(ofSize: 12, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        return label
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(title: "Continue", style: .primary, delegate: self)
        button.isEnabled = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupEmotionTags()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(colorDisplayView)
        view.addSubview(colorLabel)
        view.addSubview(promptLabel)
        view.addSubview(emotionTagsView)
        view.addSubview(intensityTitleLabel)
        view.addSubview(intensitySlider)
        view.addSubview(intensityLeftLabel)
        view.addSubview(intensityCenterLabel)
        view.addSubview(intensityRightLabel)
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

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }

        colorDisplayView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(40)
            make.top.equalTo(titleLabel.snp.bottom).offset(24)
            make.width.height.equalTo(30)
        }

        colorLabel.snp.makeConstraints { make in
            make.left.equalTo(colorDisplayView.snp.right).offset(12)
            make.centerY.equalTo(colorDisplayView)
        }

        promptLabel.snp.makeConstraints { make in
            make.top.equalTo(colorDisplayView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(40)
        }

        emotionTagsView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(140)
        }

        intensityTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(emotionTagsView.snp.bottom).offset(24)
            make.left.equalToSuperview().inset(40)
        }

        intensitySlider.snp.makeConstraints { make in
            make.top.equalTo(intensityTitleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(40)
        }

        intensityLeftLabel.snp.makeConstraints { make in
            make.left.equalTo(intensitySlider)
            make.top.equalTo(intensitySlider.snp.bottom).offset(4)
        }

        intensityCenterLabel.snp.makeConstraints { make in
            make.centerX.equalTo(intensitySlider)
            make.top.equalTo(intensitySlider.snp.bottom).offset(4)
        }

        intensityRightLabel.snp.makeConstraints { make in
            make.right.equalTo(intensitySlider)
            make.top.equalTo(intensitySlider.snp.bottom).offset(4)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupEmotionTags() {
        let emotions = EmotionType.allCases.map { emotion in
            SoulverseTagsItemData(title: emotion.displayName, isSelected: false)
        }
        emotionTagsView.setItems(emotions)
    }

    func setSelectedColor(_ color: UIColor) {
        colorDisplayView.backgroundColor = color
        // You could also update the label text to show the color name
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
    }

    @objc private func intensitySliderChanged() {
        emotionIntensity = Double(intensitySlider.value)
    }

    private func updateIntensityLabels() {
        guard let emotion = selectedEmotion else { return }

        intensityTitleLabel.text = "\(emotion.displayName) Intensity"

        let labels = emotion.intensityLabels
        intensityLeftLabel.text = labels.left
        intensityCenterLabel.text = labels.center
        intensityRightLabel.text = labels.right
    }
}

// MARK: - SoulverseTagsViewDelegate

extension MoodCheckInNamingViewController: SoulverseTagsViewDelegate {
    func soulverseTagsView(_ view: SoulverseTagsView, didSelectItemAt index: Int) {
        let emotions = Array(EmotionType.allCases)
        selectedEmotion = emotions[index]
        updateIntensityLabels()
        continueButton.isEnabled = true
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInNamingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let emotion = selectedEmotion else { return }
        delegate?.didSelectEmotion(self, emotion: emotion, intensity: emotionIntensity)
    }
}
