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
        static let fieldBorderWidth: CGFloat = 1
        static let fieldFontSize: CGFloat = 15
        static let fieldHorizontalPadding: CGFloat = 16
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
        view.layer.borderWidth = Layout.fieldBorderWidth
        view.layer.borderColor = UIColor.disableGray.cgColor
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

    private lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.font = .projectFont(ofSize: Layout.fieldFontSize, weight: .regular)
        textField.textColor = .themeTextPrimary
        textField.autocapitalizationType = .none
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        return textField
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
        fieldContainer.addSubview(inputTextField)
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

        inputTextField.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
            make.top.equalTo(inlineLabel.snp.bottom).offset(Layout.inlineLabelToInputSpacing)
        }

        clearButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview()
            make.width.equalTo(Layout.accessoryContainerWidth)
            make.height.equalTo(Layout.accessoryContainerWidth)
        }

        modifiedIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
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
        return inputTextField.text ?? ""
    }

    func showError() {
        updateBorderColor(for: .error)
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

        inlineLabel.isHidden = true

        inputTextField.keyboardType = keyboardType
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.themeTextDisabled]
        )

        if let text = text, !text.isEmpty {
            inputTextField.text = text
            hasBeenModified = false
        }

        // Update field height
        fieldContainer.snp.updateConstraints { make in
            make.height.equalTo(fieldHeight)
        }

        // Without inline label, center the text field vertically
        inputTextField.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
        }

        updateRightAccessory(isFocused: false)
    }

    /// Configure as a labeled field (inline label inside the field container, e.g., "Name" above "Stephy")
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

        inlineLabel.text = inlineTitle
        inlineLabel.isHidden = false

        inputTextField.keyboardType = keyboardType
        inputTextField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.themeTextDisabled]
        )

        if let text = text, !text.isEmpty {
            inputTextField.text = text
            hasBeenModified = false
        }

        // Update field height
        fieldContainer.snp.updateConstraints { make in
            make.height.equalTo(Layout.singleLineHeight)
        }

        // With inline label, stack vertically
        inputTextField.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(Layout.fieldHorizontalPadding)
            make.trailing.equalTo(clearButton.snp.leading)
            make.top.equalTo(inlineLabel.snp.bottom).offset(Layout.inlineLabelToInputSpacing)
        }

        updateRightAccessory(isFocused: false)
    }

    // MARK: - Right Accessory Management

    private func updateRightAccessory(isFocused: Bool) {
        let currentText = inputTextField.text ?? ""

        if currentText.isEmpty {
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
        inputTextField.text = ""
        hasBeenModified = true
        updateRightAccessory(isFocused: true)
        onTextChanged?("")
    }

    // MARK: - Border State

    private func updateBorderColor(for status: FieldStatus) {
        switch status {
        case .normal:
            fieldContainer.layer.borderColor = UIColor.disableGray.cgColor
        case .focused:
            fieldContainer.layer.borderColor = UIColor.themePrimary.cgColor
        case .error:
            fieldContainer.layer.borderColor = UIColor.primaryOrange.cgColor
        }
    }

    private enum FieldStatus {
        case normal, focused, error
    }

    // MARK: - Character Limit Handling

    private func updateCharacterCount(for text: String) {
        let count = text.count

        if count >= maxCharacters {
            characterCountLabel.text = "\(count)/\(maxCharacters)"
            characterCountLabel.isHidden = false
            updateBorderColor(for: .error)
        } else {
            characterCountLabel.isHidden = true
            updateBorderColor(for: .focused)
        }
    }

    // MARK: - Actions

    @objc private func editingChanged() {
        guard let text = inputTextField.text else { return }

        if text.count > maxCharacters {
            let truncated = String(text.prefix(maxCharacters))
            inputTextField.text = truncated
            onTextChanged?(truncated)
            updateCharacterCount(for: truncated)
            return
        }

        hasBeenModified = (text != originalText)
        updateCharacterCount(for: text)
        updateRightAccessory(isFocused: true)
        onTextChanged?(text)
    }
}

// MARK: - UITextFieldDelegate

extension BundleFormFieldView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateBorderColor(for: .focused)
        if let text = textField.text {
            updateCharacterCount(for: text)
        }
        updateRightAccessory(isFocused: true)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        characterCountLabel.isHidden = true
        updateBorderColor(for: .normal)
        updateRightAccessory(isFocused: false)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
