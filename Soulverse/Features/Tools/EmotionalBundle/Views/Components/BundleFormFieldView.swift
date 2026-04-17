//
//  BundleFormFieldView.swift
//  Soulverse
//
//  Created on 2026/4/16.
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
        static let redFlagMaxCharacters: Int = 200
    }

    // MARK: - Properties

    var onTextChanged: ((String) -> Void)?
    private var maxCharacters: Int = Layout.defaultMaxCharacters

    // MARK: - UI Elements

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .medium)
        label.textColor = .themeTextPrimary
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

        // Re-create textField with proper title and placeholder
        textField.removeFromSuperview()
        textField = SoulverseTextField(
            title: title,
            placeholder: placeholder,
            type: .general,
            delegate: self
        )

        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.leading.trailing.equalToSuperview()
        }

        // Bring character count label to front
        bringSubviewToFront(characterCountLabel)
    }

    // MARK: - Character Limit Handling

    private func updateCharacterCount(for text: String) {
        let count = text.count

        if count >= maxCharacters {
            characterCountLabel.text = "\(count)/\(maxCharacters)"
            characterCountLabel.isHidden = false
            textField.updateStatus(status: .errorWithoutMessage)
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
            // Text exceeds limit — the delegate will be informed with truncated text
            let truncated = String(text.prefix(maxCharacters))
            onTextChanged?(truncated)
            updateCharacterCount(for: truncated)
            return
        }

        updateCharacterCount(for: text)
        onTextChanged?(text)
    }

    func textFieldDidBeginEditing(_ textField: SoulverseTextField) {
        if let text = textField.text {
            updateCharacterCount(for: text)
        }
    }

    func textFieldDidEndEditing(_ textField: SoulverseTextField) {
        characterCountLabel.isHidden = true
        if let text = textField.text, text.count < maxCharacters {
            textField.updateStatus(status: .normal)
        }
    }

    func textFieldShouldReturn(_ textField: SoulverseTextField) {
        // Default: dismiss keyboard
    }
}
