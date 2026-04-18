//
//  BundleFormFieldView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class BundleFormFieldView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let titleFontSize: CGFloat = 14
        static let counterFontSize: CGFloat = 12
        static let titleBottomSpacing: CGFloat = 8
        static let counterTopSpacing: CGFloat = 4
        static let defaultMaxCharacters: Int = 100
        static let singleLineHeight: CGFloat = 60
        static let multiLineHeight: CGFloat = 80
        static let fieldCornerRadius: CGFloat = 8
        static let fieldFontSize: CGFloat = 15
        static let fieldHorizontalPadding: CGFloat = 16
        static let fieldVerticalPadding: CGFloat = 12
        static let inlineLabelFontSize: CGFloat = 12
        static let inlineLabelTopPadding: CGFloat = 10
        static let inlineLabelToInputSpacing: CGFloat = 2
        static let accessorySize: CGFloat = 20
        static let accessoryContainerWidth: CGFloat = 40
    }

    // MARK: - Properties

    var onTextChanged: ((String) -> Void)?
    private var maxCharacters: Int = Layout.defaultMaxCharacters
    private var originalText: String = ""
    private var hasBeenModified: Bool = false
    private var fieldHeight: CGFloat = Layout.singleLineHeight
    private var hasInlineLabel: Bool = false
    private var placeholderText: String = ""

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .medium)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var fieldContainer: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.fieldCornerRadius
        view.clipsToBounds = true
        view.backgroundColor = .groupAreaBackgroundBlack
        return view
    }()

    private lazy var inlineLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.inlineLabelFontSize, weight: .regular)
        label.textColor = .themeTextDisabled
        label.isHidden = true
        return label
    }()

    private lazy var inputTextView: UITextView = {
        let textView = UITextView()
        textView.font = .projectFont(ofSize: Layout.fieldFontSize, weight: .regular)
        textView.textColor = .themeTextPrimary
        textView.backgroundColor = .clear
        textView.autocapitalizationType = .none
        textView.delegate = self
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isScrollEnabled = true
        textView.showsVerticalScrollIndicator = false
        return textView
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .themeTextSecondary
        button.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    private lazy var modifiedIcon: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = .themePrimary
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        return imageView
    }()

    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.counterFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        label.isHidden = true
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
        addSubview(titleLabel)
        addSubview(fieldContainer)
        addSubview(characterCountLabel)

        fieldContainer.addSubview(inlineLabel)
        fieldContainer.addSubview(inputTextView)
        fieldContainer.addSubview(clearButton)
        fieldContainer.addSubview(modifiedIcon)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        fieldContainer.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.singleLineHeight)
        }

        inlineLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.inlineLabelTopPadding)
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
        }

        inputTextView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.fieldVerticalPadding)
            make.bottom.equalToSuperview().offset(-Layout.fieldVerticalPadding)
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
        }

        clearButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.fieldVerticalPadding)
            make.trailing.equalToSuperview()
            make.width.equalTo(Layout.accessoryContainerWidth)
            make.height.equalTo(Layout.accessoryContainerWidth)
        }

        modifiedIcon.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.fieldVerticalPadding)
            make.trailing.equalToSuperview().inset(Layout.fieldHorizontalPadding)
            make.width.height.equalTo(Layout.accessorySize)
        }

        characterCountLabel.snp.makeConstraints { make in
            make.top.equalTo(fieldContainer.snp.bottom).offset(Layout.counterTopSpacing)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Public Interface

    var text: String {
        return inputTextView.text ?? ""
    }

    func showError() {
        // Could add visual feedback here if needed
    }

    // MARK: - Configuration

    /// Configure as a simple text field with external title label
    func configure(
        title: String,
        placeholder: String,
        text: String? = nil,
        maxCharacters: Int = Layout.defaultMaxCharacters,
        keyboardType: UIKeyboardType = .default,
        fieldHeight: CGFloat = Layout.singleLineHeight
    ) {
        titleLabel.text = title
        titleLabel.isHidden = title.isEmpty
        self.maxCharacters = maxCharacters
        self.originalText = text ?? ""
        self.fieldHeight = fieldHeight
        self.hasInlineLabel = false
        self.placeholderText = placeholder

        inlineLabel.isHidden = true

        inputTextView.keyboardType = keyboardType

        if let text = text, !text.isEmpty {
            inputTextView.text = text
            inputTextView.textColor = .themeTextPrimary
        } else {
            inputTextView.text = placeholder
            inputTextView.textColor = .themeTextDisabled
        }

        // Update field height
        fieldContainer.snp.updateConstraints { make in
            make.height.equalTo(fieldHeight)
        }

        // Without inline label, use full vertical space
        inputTextView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(Layout.fieldVerticalPadding)
            make.bottom.equalToSuperview().offset(-Layout.fieldVerticalPadding)
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
        }

        updateRightAccessory(isFocused: false)
    }

    /// Configure as a labeled field (inline label inside the field container)
    func configureLabeled(
        inlineTitle: String,
        placeholder: String,
        text: String? = nil,
        maxCharacters: Int = Layout.defaultMaxCharacters,
        keyboardType: UIKeyboardType = .default
    ) {
        titleLabel.text = ""
        titleLabel.isHidden = true
        self.maxCharacters = maxCharacters
        self.originalText = text ?? ""
        self.fieldHeight = Layout.singleLineHeight
        self.hasInlineLabel = true
        self.placeholderText = placeholder

        inlineLabel.text = inlineTitle
        inlineLabel.isHidden = false

        inputTextView.keyboardType = keyboardType

        if let text = text, !text.isEmpty {
            inputTextView.text = text
            inputTextView.textColor = .themeTextPrimary
        } else {
            inputTextView.text = placeholder
            inputTextView.textColor = .themeTextDisabled
        }

        // Update field height
        fieldContainer.snp.updateConstraints { make in
            make.height.equalTo(Layout.singleLineHeight)
        }

        // With inline label, stack vertically
        inputTextView.snp.remakeConstraints { make in
            make.top.equalTo(inlineLabel.snp.bottom).offset(Layout.inlineLabelToInputSpacing)
            make.bottom.equalToSuperview().offset(-Layout.fieldVerticalPadding)
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
        }

        updateRightAccessory(isFocused: false)
    }

    // MARK: - Placeholder Management

    private var isShowingPlaceholder: Bool {
        return inputTextView.textColor == .themeTextDisabled && inputTextView.text == placeholderText
    }

    private func showPlaceholder() {
        inputTextView.text = placeholderText
        inputTextView.textColor = .themeTextDisabled
    }

    private func hidePlaceholder() {
        if isShowingPlaceholder {
            inputTextView.text = ""
            inputTextView.textColor = .themeTextPrimary
        }
    }

    // MARK: - Right Accessory Management

    private func updateRightAccessory(isFocused: Bool) {
        let hasContent = !isShowingPlaceholder && !(inputTextView.text ?? "").isEmpty

        if !hasContent {
            clearButton.isHidden = true
            modifiedIcon.isHidden = true
        } else if isFocused {
            clearButton.isHidden = false
            modifiedIcon.isHidden = true
        } else {
            clearButton.isHidden = true
            modifiedIcon.isHidden = false
        }
    }

    @objc private func clearText() {
        hasBeenModified = true
        showPlaceholder()
        updateRightAccessory(isFocused: true)
        onTextChanged?("")
    }

    // MARK: - Character Limit Handling

    private func updateCharacterCount(for text: String) {
        let count = text.count

        if count >= maxCharacters {
            characterCountLabel.text = "\(count)/\(maxCharacters)"
            characterCountLabel.isHidden = false
        } else {
            characterCountLabel.isHidden = true
        }
    }
}

// MARK: - UITextViewDelegate

extension BundleFormFieldView: UITextViewDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        hidePlaceholder()
        updateRightAccessory(isFocused: true)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        let text = textView.text ?? ""
        if text.isEmpty {
            showPlaceholder()
        }
        characterCountLabel.isHidden = true
        updateRightAccessory(isFocused: false)
    }

    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else { return }

        if text.count > maxCharacters {
            let truncated = String(text.prefix(maxCharacters))
            textView.text = truncated
            onTextChanged?(truncated)
            updateCharacterCount(for: truncated)
            return
        }

        hasBeenModified = (text != originalText)
        updateCharacterCount(for: text)
        updateRightAccessory(isFocused: true)
        onTextChanged?(text)
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // For single-line fields (not multiline), treat return as done
        if fieldHeight <= Layout.singleLineHeight && text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
