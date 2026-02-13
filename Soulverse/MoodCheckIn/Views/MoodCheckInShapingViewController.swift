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
    private var promptResponseCache: [PromptOption: String] = [:]
    private var recordedEmotion: RecordedEmotion?

    // MARK: - View-specific Constants

    private let currentStep: Int = 3
    private let headerToTextFieldSpacing: CGFloat = 16

    // MARK: - UI Elements - Scroll View

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private lazy var contentView: UIView = {
        let view = UIView()
        return view
    }()

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
        label.text = NSLocalizedString("mood_checkin_shaping_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .semibold)
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

    private lazy var feelingLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var promptSelectionSection: PromptSelectionView = {
        let view = PromptSelectionView()
        view.delegate = self
        return view
    }()

    private lazy var promptHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_shaping_text_header", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var textField: UITextView = {
        let textView = UITextView()
        textView.font = .projectFont(ofSize: 14, weight: .regular)
        textView.textColor = .themeTextTertiary // Placeholder color initially
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.themeTextTertiary.cgColor
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.delegate = self
        return textView
    }()

    private lazy var continueButton: SoulverseButton = {
        let buttonTitle = NSLocalizedString("mood_checkin_continue", comment: "")
        let button = SoulverseButton(title: buttonTitle, style: .primary, delegate: self)
        button.isEnabled = true
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
        setupScrollView()
        setupHeaderSection()
        setupContentSections()
        setupResponseSection()
        setupContinueButton()
        setupConstraints()
    }

    private func setupNavigationBar() {
        view.addSubview(backButton)
        view.addSubview(progressBar)
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
    }

    private func setupHeaderSection() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    }

    private func setupContentSections() {
        contentView.addSubview(feelingLabel)
        contentView.addSubview(promptSelectionSection)
    }

    private func setupResponseSection() {
        contentView.addSubview(promptHeaderLabel)
        contentView.addSubview(textField)
    }

    private func setupContinueButton() {
        view.addSubview(continueButton)
    }

    private func setupConstraints() {
        setupNavigationConstraints()
        setupScrollViewConstraints()
        setupHeaderConstraints()
        setupSectionConstraints()
        setupResponseConstraints()
        setupContinueButtonConstraints()
    }

    private func setupNavigationConstraints() {
        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(MoodCheckInLayout.navigationTopOffset)
            make.left.equalToSuperview().offset(MoodCheckInLayout.navigationLeftOffset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.width.equalTo(ViewComponentConstants.progressViewWidth)
        }
    }

    private func setupScrollViewConstraints() {
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(continueButton.snp.top)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
    }

    private func setupHeaderConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(MoodCheckInLayout.titleTopOffset)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(MoodCheckInLayout.titleToSubtitleSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }
    }

    private func setupSectionConstraints() {
        feelingLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        promptSelectionSection.snp.makeConstraints { make in
            make.top.equalTo(feelingLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }
    }

    private func setupResponseConstraints() {
        promptHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(promptSelectionSection.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(promptHeaderLabel.snp.bottom).offset(headerToTextFieldSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.height.equalTo(MoodCheckInLayout.textFieldHeight)
            make.bottom.equalToSuperview().offset(-MoodCheckInLayout.sectionSpacing)
        }
    }

    private func setupContinueButtonConstraints() {
        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MoodCheckInLayout.bottomPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }


    // MARK: - Public Methods

    func setSelectedColorAndEmotion(color: UIColor, emotion: RecordedEmotion) {
        recordedEmotion = emotion
        updateFeelingLabel(emotionName: emotion.displayName, color: color)
    }

    // MARK: - Private Methods

    private func updateFeelingLabel(emotionName: String, color: UIColor) {
        let prefix = NSLocalizedString("mood_checkin_shaping_feeling_prefix", comment: "")
        let fullText = "\(prefix)    \(emotionName)"

        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.projectFont(ofSize: 17, weight: .regular),
                .foregroundColor: UIColor.themeTextPrimary
            ]
        )

        // Blend color with white to create opaque color that looks like alpha on white
        let displayColor = blendColorWithWhite(color)

        let emotionRange = (fullText as NSString).range(of: emotionName)
        if emotionRange.location != NSNotFound {
            attributedString.addAttributes([
                .foregroundColor: displayColor,
                .font: UIFont.projectFont(ofSize: 20, weight: .semibold)
            ], range: emotionRange)
        }

        feelingLabel.attributedText = attributedString
    }

    /// Blends a color with white based on its alpha component
    /// Result looks the same as the original color rendered on white background
    private func blendColorWithWhite(_ color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        // Blend formula: result = color * alpha + white * (1 - alpha)
        let blendedR = r * a + 1.0 * (1 - a)
        let blendedG = g * a + 1.0 * (1 - a)
        let blendedB = b * a + 1.0 * (1 - a)

        return UIColor(red: blendedR, green: blendedG, blue: blendedB, alpha: 1.0)
    }

    /// Returns the current text from the text field only if it represents user-typed content
    /// (not placeholder text). Returns nil if the text field is showing placeholder.
    private func currentUserText() -> String? {
        if textField.textColor == .themeTextTertiary {
            return nil
        }
        return textField.text
    }

    private func updatePlaceholder() {
        guard let prompt = selectedPrompt else {
            // No prompt selected - clear the text field
            textField.text = ""
            textField.textColor = .themeTextTertiary
            promptResponse = ""
            return
        }

        // Check if there's a cached response for this prompt
        if let cachedText = promptResponseCache[prompt], !cachedText.isEmpty {
            textField.text = cachedText
            textField.textColor = .themeTextPrimary
            promptResponse = cachedText
        } else {
            textField.text = prompt.placeholderText
            textField.textColor = .themeTextTertiary
            promptResponse = ""
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

}

// MARK: - PromptSelectionViewDelegate

extension MoodCheckInShapingViewController: PromptSelectionViewDelegate {
    func didUpdatePromptSelection(_ view: PromptSelectionView, prompt: PromptOption?) {
        // Save current text to cache for the old prompt before switching
        if let oldPrompt = selectedPrompt, let userText = currentUserText() {
            if userText.isEmpty {
                promptResponseCache.removeValue(forKey: oldPrompt)
            } else {
                promptResponseCache[oldPrompt] = userText
            }
        }

        selectedPrompt = prompt
        updatePlaceholder()
    }
}

// MARK: - UITextViewDelegate

extension MoodCheckInShapingViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .themeTextTertiary {
            // Text field is showing placeholder - check cache first
            if let prompt = selectedPrompt, let cachedText = promptResponseCache[prompt], !cachedText.isEmpty {
                textView.text = cachedText
            } else if let prompt = selectedPrompt {
                textView.text = prompt.displayName + " "
            } else {
                textView.text = ""
            }
            textView.textColor = .themeTextPrimary
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        promptResponse = textView.text
        // Update cache as user types
        if let prompt = selectedPrompt {
            promptResponseCache[prompt] = textView.text
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            // Remove from cache and show placeholder
            if let prompt = selectedPrompt {
                promptResponseCache.removeValue(forKey: prompt)
                textView.text = prompt.placeholderText
                textView.textColor = .themeTextTertiary
            }
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInShapingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        // Ensure promptResponse reflects the current state
        if let prompt = selectedPrompt, let userText = currentUserText() {
            promptResponse = userText
        }
        // Prompt and response are optional - user can skip this step
        let response: String? = promptResponse.isEmpty ? nil : promptResponse
        delegate?.didComplete(self, prompt: selectedPrompt, response: response)
    }
}
