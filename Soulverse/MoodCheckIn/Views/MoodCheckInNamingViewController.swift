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

    private var viewState = ViewState() {
        didSet { updateContinueButton() }
    }

    // MARK: - View-specific Constants

    private let currentStep: Int = 2

    // MARK: - UI Elements - Navigation

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
        bar.setProgress(currentStep: currentStep)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_naming_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    // MARK: - UI Elements - Content Sections

    private lazy var colorSummarySection: ColorSummaryView = {
        let view = ColorSummaryView()
        return view
    }()

    private lazy var emotionSelectionSection: EmotionSelectionView = {
        let view = EmotionSelectionView()
        view.delegate = self
        return view
    }()

    private lazy var intensityContainer: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = MoodCheckInLayout.sectionSpacing
        return stack
    }()

    private var intensityViews: [EmotionType: IntensitySelectionView] = [:]

    /// Label showing combined emotion formula (e.g., "Joy + Trust = Love")
    private lazy var combinedEmotionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.alpha = 0
        return label
    }()

    private lazy var continueButton: SoulverseButton = {
        let buttonTitle = NSLocalizedString("mood_checkin_continue", comment: "")
        let button = SoulverseButton(title: buttonTitle, style: .primary, delegate: self)
        button.isEnabled = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        setupNavigationBar()
        setupContentSections()
        setupContinueButton()
        setupConstraints()
    }

    private func setupNavigationBar() {
        view.addSubview(backButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
    }

    private func setupContentSections() {
        view.addSubview(colorSummarySection)
        view.addSubview(emotionSelectionSection)
        view.addSubview(intensityContainer)
        view.addSubview(combinedEmotionLabel)
    }

    private func setupContinueButton() {
        view.addSubview(continueButton)
    }

    private func setupConstraints() {
        setupNavigationConstraints()
        setupProgressBarConstraints()
        setupTitleConstraints()
        setupSectionConstraints()
        setupContinueButtonConstraints()
    }

    private func setupNavigationConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(MoodCheckInLayout.navigationTopOffset)
            make.left.equalToSuperview().offset(MoodCheckInLayout.navigationLeftOffset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }
    }

    private func setupProgressBarConstraints() {
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.width.equalTo(ViewComponentConstants.progressViewWidth)
        }
    }

    private func setupTitleConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(MoodCheckInLayout.titleTopOffset)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }
    }

    private func setupSectionConstraints() {
        colorSummarySection.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        emotionSelectionSection.snp.makeConstraints { make in
            make.top.equalTo(colorSummarySection.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        intensityContainer.snp.makeConstraints { make in
            make.top.equalTo(emotionSelectionSection.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        combinedEmotionLabel.snp.makeConstraints { make in
            make.top.equalTo(emotionSelectionSection.snp.bottom).offset(MoodCheckInLayout.sectionSpacing * 3)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }
    }

    private func setupContinueButtonConstraints() {
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.top.greaterThanOrEqualTo(intensityContainer.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.top.greaterThanOrEqualTo(combinedEmotionLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MoodCheckInLayout.bottomPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    // MARK: - Public Methods

    func setSelectedColor(_ color: UIColor) {
        viewState.selectedColor = color
        colorSummarySection.configure(color: color)
    }

    // MARK: - Private Methods

    private func updateContinueButton() {
        continueButton.isEnabled = viewState.canContinue
    }

    private func updateIntensitySection() {
        // Clear existing intensity views
        intensityContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        intensityViews.removeAll()

        let emotionCount = viewState.selectedEmotions.count

        // Single emotion: show intensity selector, hide combined label
        if emotionCount == 1, let emotion = viewState.selectedEmotions.first {
            let intensityView = IntensitySelectionView()
            intensityView.delegate = self
            intensityView.configure(emotion: emotion)

            intensityViews[emotion] = intensityView
            intensityContainer.addArrangedSubview(intensityView)

            UIView.animate(withDuration: AnimationConstant.defaultDuration) {
                self.intensityContainer.alpha = 1
                self.combinedEmotionLabel.alpha = 0
            }
            return
        }

        // Two emotions: hide intensity selector, show combined emotion formula
        if emotionCount == 2, let resolvedEmotion = viewState.resolvedEmotion,
           let sources = resolvedEmotion.sourceEmotions {
            let formula = "\(sources.0.displayName) + \(sources.1.displayName) = \(resolvedEmotion.displayName)"
            combinedEmotionLabel.text = formula

            UIView.animate(withDuration: AnimationConstant.defaultDuration) {
                self.intensityContainer.alpha = 0
                self.combinedEmotionLabel.alpha = 1
            }
            return
        }

        // No selection or invalid: hide both
        UIView.animate(withDuration: AnimationConstant.defaultDuration) {
            self.intensityContainer.alpha = 0
            self.combinedEmotionLabel.alpha = 0
        }
    }

    private func shakeEmotionTags() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.values = [-10, 10, -10, 10, -5, 5, 0]
        animation.duration = 0.4
        emotionSelectionSection.layer.add(animation, forKey: "shake")
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }
}

// MARK: - EmotionSelectionViewDelegate

extension MoodCheckInNamingViewController: EmotionSelectionViewDelegate {
    func didUpdateEmotions(_ view: EmotionSelectionView, emotions: [EmotionType]) {
        viewState.selectedEmotions = emotions

        // Reset intensity to default when selection changes
        viewState.intensity = 0.5

        // Update intensity section visibility
        updateIntensitySection()
    }

    func didReachMaximumSelection(_ view: EmotionSelectionView) {
        shakeEmotionTags()
    }

    func didSelectOppositeEmotion(_ view: EmotionSelectionView) {
        shakeEmotionTags()
    }
}

// MARK: - IntensitySelectionViewDelegate

extension MoodCheckInNamingViewController: IntensitySelectionViewDelegate {
    func didChangeIntensity(_ view: IntensitySelectionView, emotion: EmotionType, intensity: Double) {
        viewState.intensity = intensity
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInNamingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let recordedEmotion = viewState.resolvedEmotion else { return }
        delegate?.didSelectEmotion(self, emotion: recordedEmotion)
    }
}

// MARK: - ViewState

private extension MoodCheckInNamingViewController {
    struct ViewState {
        var selectedColor: UIColor = .yellow
        var selectedEmotions: [EmotionType] = []
        var intensity: Double = 0.5  // Only used for single emotion selection

        var canContinue: Bool {
            // Must have 1-2 emotions AND the combination must be resolvable
            return resolvedEmotion != nil
        }

        /// Whether intensity selector should be shown (only for single emotion)
        var shouldShowIntensity: Bool {
            return selectedEmotions.count == 1
        }

        /// Resolve the final RecordedEmotion based on current selection
        var resolvedEmotion: RecordedEmotion? {
            switch selectedEmotions.count {
            case 1:
                return RecordedEmotion.from(primary: selectedEmotions[0], intensity: intensity)
            case 2:
                return RecordedEmotion.from(emotion1: selectedEmotions[0], emotion2: selectedEmotions[1])
            default:
                return nil
            }
        }
    }
}
