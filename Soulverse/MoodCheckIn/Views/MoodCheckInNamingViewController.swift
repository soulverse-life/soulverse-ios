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

    // MARK: - Layout Constants

    private enum Layout {
        enum Spacing {
            static let horizontal: CGFloat = 40
            static let sectionVertical: CGFloat = 24
            static let titleTopOffset: CGFloat = 40
        }

        enum Size {
            static let progressSteps: Int = 6
            static let currentStep: Int = 2
        }
    }

    // MARK: - UI Elements - Navigation

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
        let bar = SoulverseProgressBar(totalSteps: Layout.Size.progressSteps)
        bar.setProgress(currentStep: Layout.Size.currentStep)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_naming_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .semibold)
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
        stack.spacing = Layout.Spacing.sectionVertical
        return stack
    }()

    private var intensityViews: [EmotionType: IntensitySelectionView] = [:]

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
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
    }

    private func setupContentSections() {
        view.addSubview(colorSummarySection)
        view.addSubview(emotionSelectionSection)
        view.addSubview(intensityContainer)
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
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }
    }

    private func setupProgressBarConstraints() {
        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
    }

    private func setupTitleConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(Layout.Spacing.titleTopOffset)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }
    }

    private func setupSectionConstraints() {
        colorSummarySection.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }

        emotionSelectionSection.snp.makeConstraints { make in
            make.top.equalTo(colorSummarySection.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }

        intensityContainer.snp.makeConstraints { make in
            make.top.equalTo(emotionSelectionSection.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }
    }

    private func setupContinueButtonConstraints() {
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
            make.top.greaterThanOrEqualTo(intensityContainer.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
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

    private func updateIntensityViews(for emotions: [EmotionType]) {
        // Remove views for deselected emotions
        for (emotion, view) in intensityViews where !emotions.contains(emotion) {
            view.removeFromSuperview()
            intensityViews.removeValue(forKey: emotion)
        }

        // Add views for newly selected emotions
        for emotion in emotions where intensityViews[emotion] == nil {
            let intensityView = IntensitySelectionView()
            intensityView.delegate = self
            intensityView.configure(emotion: emotion)

            intensityViews[emotion] = intensityView
        }

        // Rebuild stack view in correct order
        intensityContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for emotion in emotions {
            if let view = intensityViews[emotion] {
                intensityContainer.addArrangedSubview(view)
            }
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

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
    }
}

// MARK: - EmotionSelectionViewDelegate

extension MoodCheckInNamingViewController: EmotionSelectionViewDelegate {
    func didUpdateEmotions(_ view: EmotionSelectionView, emotions: [EmotionType]) {
        // Update view state with new emotions (preserve existing intensities, default 0.5 for new)
        var newEmotionsData: [(emotion: EmotionType, intensity: Double)] = []

        for emotion in emotions {
            // Find existing intensity or use default
            let existingIntensity = viewState.selectedEmotions.first(where: { $0.emotion == emotion })?.intensity ?? 0.5
            newEmotionsData.append((emotion: emotion, intensity: existingIntensity))
        }

        viewState.selectedEmotions = newEmotionsData

        // Update intensity views
        updateIntensityViews(for: emotions)
    }

    func didReachMaximumSelection(_ view: EmotionSelectionView) {
        shakeEmotionTags()
    }
}

// MARK: - IntensitySelectionViewDelegate

extension MoodCheckInNamingViewController: IntensitySelectionViewDelegate {
    func didChangeIntensity(_ view: IntensitySelectionView, emotion: EmotionType, intensity: Double) {
        // Update the intensity for the specific emotion
        if let index = viewState.selectedEmotions.firstIndex(where: { $0.emotion == emotion }) {
            viewState.selectedEmotions[index].intensity = intensity
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInNamingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard !viewState.selectedEmotions.isEmpty else { return }
        delegate?.didSelectEmotions(self, emotions: viewState.selectedEmotions)
    }
}

// MARK: - ViewState

private extension MoodCheckInNamingViewController {
    struct ViewState {
        var selectedColor: UIColor = .yellow
        var selectedEmotions: [(emotion: EmotionType, intensity: Double)] = []

        var canContinue: Bool {
            return !selectedEmotions.isEmpty && selectedEmotions.count <= 2
        }
    }
}
