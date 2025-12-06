//
//  MoodCheckInShapingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

class MoodCheckInShapingViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInShapingViewControllerDelegate?

    private var selectedPrompt: PromptOption?
    private var promptResponse: String = ""
    private var selectedEmotions: [(emotion: EmotionType, intensity: Double)] = []

    // MARK: - Layout Constants

    private enum Layout {
        enum Spacing {
            static let horizontal: CGFloat = 40
            static let sectionVertical: CGFloat = 24
            static let titleTopOffset: CGFloat = 24
            static let headerToTextField: CGFloat = 8
        }

        enum Size {
            static let progressSteps: Int = 6
            static let currentStep: Int = 3
            static let textFieldHeight: CGFloat = 120
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
        label.text = NSLocalizedString("mood_checkin_shaping_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_shaping_subtitle", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - UI Elements - Content Sections

    private lazy var colorEmotionSection: ColorEmotionSummaryView = {
        let view = ColorEmotionSummaryView()
        return view
    }()

    private lazy var promptSelectionSection: PromptSelectionView = {
        let view = PromptSelectionView()
        view.delegate = self
        return view
    }()

    private lazy var promptHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.isHidden = true
        return label
    }()

    private lazy var textField: UITextView = {
        let textView = UITextView()
        textView.font = .projectFont(ofSize: 14, weight: .regular)
        textView.textColor = .lightGray // Placeholder color initially
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.delegate = self
        textView.isHidden = true
        return textView
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
        setupHeaderSection()
        setupContentSections()
        setupResponseSection()
        setupContinueButton()
        setupConstraints()
    }

    private func setupNavigationBar() {
        view.addSubview(backButton)
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
    }

    private func setupHeaderSection() {
        // Header elements (title, subtitle) added in setupNavigationBar for layout order
    }

    private func setupContentSections() {
        view.addSubview(colorEmotionSection)
        view.addSubview(promptSelectionSection)
    }

    private func setupResponseSection() {
        view.addSubview(promptHeaderLabel)
        view.addSubview(textField)
    }

    private func setupContinueButton() {
        view.addSubview(continueButton)
    }

    private func setupConstraints() {
        setupNavigationConstraints()
        setupHeaderConstraints()
        setupSectionConstraints()
        setupResponseConstraints()
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

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }
    }

    private func setupHeaderConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(Layout.Spacing.titleTopOffset)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }
    }

    private func setupSectionConstraints() {
        colorEmotionSection.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }

        promptSelectionSection.snp.makeConstraints { make in
            make.top.equalTo(colorEmotionSection.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
        }
    }

    private func setupResponseConstraints() {
        promptHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(promptSelectionSection.snp.bottom).offset(Layout.Spacing.sectionVertical)
            make.left.equalToSuperview().inset(Layout.Spacing.horizontal)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(promptHeaderLabel.snp.bottom).offset(Layout.Spacing.headerToTextField)
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
            make.height.equalTo(Layout.Size.textFieldHeight)
        }
    }

    private func setupContinueButtonConstraints() {
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.Spacing.horizontal)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }


    // MARK: - Public Methods

    func setSelectedColorAndEmotions(color: UIColor, emotions: [(emotion: EmotionType, intensity: Double)]) {
        selectedEmotions = emotions
        colorEmotionSection.configure(color: color, emotions: emotions)
    }

    // MARK: - Private Methods

    private func updatePlaceholder() {
        guard let prompt = selectedPrompt else { return }

        promptHeaderLabel.text = prompt.displayName
        promptHeaderLabel.isHidden = false

        textField.text = prompt.placeholderText
        textField.textColor = .lightGray
        textField.isHidden = false
    }

    private func validateInput() {
        let hasText = !promptResponse.isEmpty && promptResponse != selectedPrompt?.placeholderText
        continueButton.isEnabled = hasText
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
    }
}

// MARK: - PromptSelectionViewDelegate

extension MoodCheckInShapingViewController: PromptSelectionViewDelegate {
    func didSelectPrompt(_ view: PromptSelectionView, prompt: PromptOption) {
        selectedPrompt = prompt
        updatePlaceholder()
        validateInput()
    }
}

// MARK: - UITextViewDelegate

extension MoodCheckInShapingViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .lightGray {
            textView.text = ""
            textView.textColor = .primaryBlack
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        promptResponse = textView.text
        validateInput()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            if let prompt = selectedPrompt {
                textView.text = prompt.placeholderText
                textView.textColor = .lightGray
            }
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInShapingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let prompt = selectedPrompt, !promptResponse.isEmpty else { return }
        delegate?.didComplete(self, prompt: prompt, response: promptResponse)
    }
}
