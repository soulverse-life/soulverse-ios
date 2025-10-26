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
        bar.setProgress(currentStep: 3)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Shaping"
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Emotions are subjective.\nThrough language and metaphor, you can better\nsense, understand and converse with them"
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var colorDisplayView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 15
        view.backgroundColor = .yellow
        return view
    }()

    private lazy var emotionLabel: UILabel = {
        let label = UILabel()
        label.text = "Joy"
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var promptInstructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose a prompt"
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var promptTagsView: SoulverseTagsView = {
        let config = SoulverseTagsViewConfig(horizontalSpacing: 12, verticalSpacing: 12, itemHeight: 44)
        let view = SoulverseTagsView(config: config)
        view.delegate = self
        return view
    }()

    private lazy var promptHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "It feels like"
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.isHidden = true
        return label
    }()

    private lazy var textField: UITextView = {
        let textView = UITextView()
        textView.font = .projectFont(ofSize: 14, weight: .regular)
        textView.textColor = .themeTextDisabled
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        textView.delegate = self
        textView.isHidden = true
        return textView
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
        setupPromptTags()
    }

    // MARK: - Setup

    private func setupView() {
        view.backgroundColor = .white
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(colorDisplayView)
        view.addSubview(emotionLabel)
        view.addSubview(promptInstructionLabel)
        view.addSubview(promptTagsView)
        view.addSubview(promptHeaderLabel)
        view.addSubview(textField)
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
            make.top.equalTo(progressBar.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(40)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(40)
        }

        colorDisplayView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(40)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.width.height.equalTo(30)
        }

        emotionLabel.snp.makeConstraints { make in
            make.left.equalTo(colorDisplayView.snp.right).offset(12)
            make.centerY.equalTo(colorDisplayView)
        }

        promptInstructionLabel.snp.makeConstraints { make in
            make.top.equalTo(colorDisplayView.snp.bottom).offset(24)
            make.left.equalToSuperview().inset(40)
        }

        promptTagsView.snp.makeConstraints { make in
            make.top.equalTo(promptInstructionLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(140)
        }

        promptHeaderLabel.snp.makeConstraints { make in
            make.top.equalTo(promptTagsView.snp.bottom).offset(24)
            make.left.equalToSuperview().inset(40)
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(promptHeaderLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(120)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupPromptTags() {
        let prompts = PromptOption.allCases.map { prompt in
            SoulverseTagsItemData(title: prompt.displayName, isSelected: false)
        }
        promptTagsView.setItems(prompts)
    }

    func setSelectedColorAndEmotion(color: UIColor, emotion: EmotionType) {
        colorDisplayView.backgroundColor = color
        emotionLabel.text = emotion.displayName
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
    }

    private func updatePlaceholder() {
        guard let prompt = selectedPrompt else { return }

        promptHeaderLabel.text = prompt.displayName
        promptHeaderLabel.isHidden = false

        textField.text = prompt.placeholderText
        textField.textColor = .themeTextDisabled
        textField.isHidden = false
    }

    private func validateInput() {
        let hasText = !promptResponse.isEmpty && promptResponse != selectedPrompt?.placeholderText
        continueButton.isEnabled = hasText
    }
}

// MARK: - SoulverseTagsViewDelegate

extension MoodCheckInShapingViewController: SoulverseTagsViewDelegate {
    func soulverseTagsView(_ view: SoulverseTagsView, didSelectItemAt index: Int) {
        let prompts = Array(PromptOption.allCases)
        selectedPrompt = prompts[index]
        updatePlaceholder()
        validateInput()
    }
}

// MARK: - UITextViewDelegate

extension MoodCheckInShapingViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .themeTextDisabled {
            textView.text = ""
            textView.textColor = .themeTextPrimary
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
                textView.textColor = .themeTextDisabled
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
