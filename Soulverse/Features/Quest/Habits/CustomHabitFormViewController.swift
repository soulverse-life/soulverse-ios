//
//  CustomHabitFormViewController.swift
//  Soulverse
//

import UIKit
import SnapKit

final class CustomHabitFormViewController: UIViewController {
    private enum Layout {
        static let formInset: CGFloat = 24
        static let fieldSpacing: CGFloat = 16
        static let saveButtonHeight: CGFloat = 48
    }

    private let viewModel = CustomHabitFormViewModel()

    private let nameField = UITextField()
    private let unitField = UITextField()
    private let inc1Field = UITextField()
    private let inc2Field = UITextField()
    private let inc3Field = UITextField()
    private let saveButton = UIButton(type: .system)
    private let previewLabel = UILabel()

    var onSave: ((_ name: String, _ unit: String, _ increments: [Int]) -> Void)?
    var onCancel: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themePrimary
        title = NSLocalizedString("quest_habit_form_title", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )

        configureField(nameField, placeholderKey: "quest_habit_form_name_placeholder")
        configureField(unitField, placeholderKey: "quest_habit_form_unit_placeholder")
        for field in [inc1Field, inc2Field, inc3Field] {
            field.keyboardType = .numberPad
            field.placeholder = "0"
            field.borderStyle = .roundedRect
            field.textAlignment = .center
        }

        saveButton.setTitle(NSLocalizedString("quest_habit_form_save", comment: ""), for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.setTitleColor(.themeButtonPrimaryText, for: .normal)
        saveButton.setTitleColor(.themeButtonDisabledText, for: .disabled)
        saveButton.backgroundColor = .themeButtonPrimaryBackground
        saveButton.layer.cornerRadius = 24
        saveButton.isEnabled = false
        saveButton.addAction(UIAction { [weak self] _ in self?.saveTapped() }, for: .touchUpInside)

        previewLabel.font = .preferredFont(forTextStyle: .footnote)
        previewLabel.textColor = .themeTextSecondary
        previewLabel.numberOfLines = 0
        previewLabel.text = NSLocalizedString("quest_habit_form_preview_invalid", comment: "")

        let incrementRow = UIStackView(arrangedSubviews: [inc1Field, inc2Field, inc3Field])
        incrementRow.axis = .horizontal
        incrementRow.distribution = .fillEqually
        incrementRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [nameField, unitField, incrementRow, previewLabel, saveButton])
        stack.axis = .vertical
        stack.spacing = Layout.fieldSpacing
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(Layout.formInset)
        }
        saveButton.snp.makeConstraints { make in
            make.height.equalTo(Layout.saveButtonHeight)
        }

        nameField.addAction(UIAction { [weak self] _ in self?.recompute() }, for: .editingChanged)
        unitField.addAction(UIAction { [weak self] _ in
            self?.applyUnitSuggestions()
            self?.recompute()
        }, for: .editingChanged)
        for field in [inc1Field, inc2Field, inc3Field] {
            field.addAction(UIAction { [weak self] _ in self?.recompute() }, for: .editingChanged)
        }
    }

    private func configureField(_ field: UITextField, placeholderKey: String) {
        field.placeholder = NSLocalizedString(placeholderKey, comment: "")
        field.borderStyle = .roundedRect
        field.font = .preferredFont(forTextStyle: .body)
    }

    private func applyUnitSuggestions() {
        let unit = unitField.text ?? ""
        guard inc1Field.text?.isEmpty ?? true,
              inc2Field.text?.isEmpty ?? true,
              inc3Field.text?.isEmpty ?? true,
              let suggestions = viewModel.suggestedIncrements(forUnit: unit)
        else { return }
        inc1Field.text = String(suggestions[0])
        inc2Field.text = String(suggestions[1])
        inc3Field.text = String(suggestions[2])
    }

    private func recompute() {
        let increments = [inc1Field.text, inc2Field.text, inc3Field.text]
            .compactMap { $0 }
            .compactMap(Int.init)
        viewModel.update(
            name: nameField.text ?? "",
            unit: unitField.text ?? "",
            increments: increments
        )
        saveButton.isEnabled = viewModel.isValid

        previewLabel.text = viewModel.isValid
            ? String(
                format: NSLocalizedString("quest_habit_form_preview_format", comment: ""),
                nameField.text ?? "",
                increments.map { "+\($0)" }.joined(separator: " "),
                unitField.text ?? ""
              )
            : NSLocalizedString("quest_habit_form_preview_invalid", comment: "")
    }

    private func saveTapped() {
        guard viewModel.isValid else { return }
        onSave?(
            nameField.text ?? "",
            unitField.text ?? "",
            [inc1Field, inc2Field, inc3Field].compactMap { $0.text }.compactMap(Int.init)
        )
    }

    @objc private func cancelTapped() { onCancel?() }
}
