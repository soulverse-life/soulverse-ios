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
        static let accessorySize: CGFloat = 20
        static let accessoryContainerSize: CGFloat = 44
    }

    // MARK: - Properties

    var onTextChanged: ((String) -> Void)?
    private var maxCharacters: Int = Layout.defaultMaxCharacters
    private var originalText: String = ""
    private var hasBeenModified: Bool = false

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .medium)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var textField: SoulverseTextField = {
        let field = SoulverseTextField(
            title: "",
            placeholder: "",
            type: .general,
            delegate: self
        )
        return field
    }()

    private let characterCountLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.counterFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        label.isHidden = true
        return label
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .themeTextSecondary
        button.frame = CGRect(x: 0, y: 0, width: Layout.accessoryContainerSize, height: Layout.accessoryContainerSize)
        button.addTarget(self, action: #selector(clearText), for: .touchUpInside)
        return button
    }()

    private lazy var modifiedIndicator: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = .themePrimary
        imageView.contentMode = .scaleAspectFit
        let container = UIView(frame: CGRect(x: 0, y: 0, width: Layout.accessoryContainerSize, height: Layout.accessoryContainerSize))
        imageView.frame = CGRect(
            x: (Layout.accessoryContainerSize - Layout.accessorySize) / 2,
            y: (Layout.accessoryContainerSize - Layout.accessorySize) / 2,
            width: Layout.accessorySize,
            height: Layout.accessorySize
        )
        container.addSubview(imageView)
        return imageView
    }()

    private lazy var modifiedContainer: UIView = {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: Layout.accessoryContainerSize, height: Layout.accessoryContainerSize))
        let imageView = UIImageView(image: UIImage(systemName: "checkmark"))
        imageView.tintColor = .themePrimary
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(
            x: (Layout.accessoryContainerSize - Layout.accessorySize) / 2,
            y: (Layout.accessoryContainerSize - Layout.accessorySize) / 2,
            width: Layout.accessorySize,
            height: Layout.accessorySize
        )
        container.addSubview(imageView)
        return container
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
        addSubview(textField)
        addSubview(characterCountLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }

        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.leading.trailing.equalToSuperview()
        }

        characterCountLabel.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(Layout.counterTopSpacing)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Public Interface

    var text: String {
        return textField.text ?? ""
    }

    func showError() {
        textField.updateStatus(status: .errorWithoutMessage)
    }

    // MARK: - Configuration

    func configure(
        title: String,
        placeholder: String,
        text: String? = nil,
        maxCharacters: Int = Layout.defaultMaxCharacters,
        keyboardType: UIKeyboardType = .default
    ) {
        titleLabel.text = title
        self.maxCharacters = maxCharacters
        self.originalText = text ?? ""

        // Re-create textField with placeholder
        textField.removeFromSuperview()
        textField = SoulverseTextField(
            title: "",
            placeholder: placeholder,
            type: .general,
            delegate: self
        )
        textField.hideInternalTitle()
        textField.keyboardType = keyboardType

        if let text = text, !text.isEmpty {
            textField.text = text
            hasBeenModified = false
            updateRightAccessory(isFocused: false)
        }

        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.leading.trailing.equalToSuperview()
        }

        // Bring character count label to front
        bringSubviewToFront(characterCountLabel)
    }

    // MARK: - Right Accessory Management

    private func updateRightAccessory(isFocused: Bool) {
        let currentText = textField.text ?? ""

        if currentText.isEmpty {
            // State 1: No input — no right icon
            textField.setRightAccessoryView(nil)
        } else if isFocused {
            // State 2: Has input + focused — show clear button
            textField.setRightAccessoryView(clearButton)
        } else if hasBeenModified {
            // State 3: Has been modified — show checkmark
            textField.setRightAccessoryView(modifiedContainer)
        } else {
            // Has original text, not modified — show checkmark (pre-existing data)
            textField.setRightAccessoryView(modifiedContainer)
        }
    }

    @objc private func clearText() {
        textField.text = ""
        hasBeenModified = true
        updateRightAccessory(isFocused: true)
        onTextChanged?("")
    }

    // MARK: - Character Limit Handling

    private func updateCharacterCount(for text: String) {
        let count = text.count

        if count >= maxCharacters {
            characterCountLabel.text = "\(count)/\(maxCharacters)"
            characterCountLabel.isHidden = false
            textField.updateStatus(status: .errorWithMessage("\(count)/\(maxCharacters)"))
        } else {
            characterCountLabel.isHidden = true
            textField.updateStatus(status: .highlight)
        }
    }
}

// MARK: - SoulverseTextFieldDelegate

extension BundleFormFieldView: SoulverseTextFieldDelegate {

    func editingChanged(_ textField: SoulverseTextField) {
        guard let text = textField.text else { return }

        // Enforce character limit
        if text.count > maxCharacters {
            let truncated = String(text.prefix(maxCharacters))
            onTextChanged?(truncated)
            updateCharacterCount(for: truncated)
            return
        }

        hasBeenModified = (text != originalText)
        updateCharacterCount(for: text)
        updateRightAccessory(isFocused: true)
        onTextChanged?(text)
    }

    func textFieldDidBeginEditing(_ textField: SoulverseTextField) {
        if let text = textField.text {
            updateCharacterCount(for: text)
        }
        updateRightAccessory(isFocused: true)
    }

    func textFieldDidEndEditing(_ textField: SoulverseTextField) {
        characterCountLabel.isHidden = true
        if let text = textField.text, text.count < maxCharacters {
            textField.updateStatus(status: .normal)
        }
        updateRightAccessory(isFocused: false)
    }

    func textFieldShouldReturn(_ textField: SoulverseTextField) {
        // Default: dismiss keyboard
    }
}
