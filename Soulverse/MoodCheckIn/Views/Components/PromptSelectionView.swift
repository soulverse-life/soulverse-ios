//
//  PromptSelectionView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import SnapKit
import UIKit

/// Delegate protocol for prompt selection events
protocol PromptSelectionViewDelegate: AnyObject {
    /// Called when a prompt is selected or deselected
    /// - Parameters:
    ///   - view: The PromptSelectionView
    ///   - prompt: The selected prompt, or nil if deselected
    func didUpdatePromptSelection(_ view: PromptSelectionView, prompt: PromptOption?)
}

/// A view that prompts the user to select a prompt option
/// Contains a prompt label and prompt tags view
class PromptSelectionView: UIView {

    // MARK: - Properties

    weak var delegate: PromptSelectionViewDelegate?

    // MARK: - Layout Constants

    private enum Layout {
        static let instructionToTagsSpacing: CGFloat = 16
    }

    // MARK: - UI Elements

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_shaping_pick_prompt", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var promptTagsView: SoulverseTagsView = {
        let config = SoulverseTagsViewConfig(
            horizontalSpacing: 8, verticalSpacing: 16, itemHeight: 48)
        let view = SoulverseTagsView(config: config)
        view.selectionMode = .single
        view.delegate = self
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupPromptTags()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(instructionLabel)
        addSubview(promptTagsView)

        setupConstraints()
    }

    private func setupConstraints() {
        instructionLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        promptTagsView.snp.makeConstraints { make in
            make.top.equalTo(instructionLabel.snp.bottom).offset(Layout.instructionToTagsSpacing)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func setupPromptTags() {
        let prompts = PromptOption.allCases.map { prompt in
            SoulverseTagsItemData(title: prompt.displayName, isSelected: false)
        }
        promptTagsView.setItems(prompts)
    }
}

// MARK: - SoulverseTagsViewDelegate

extension PromptSelectionView: SoulverseTagsViewDelegate {
    func soulverseTagsView(
        _ view: SoulverseTagsView, didUpdateSelectedItems items: [SoulverseTagsItemData]
    ) {
        guard let selectedItem = items.first else {
            // No selection - prompt was deselected
            delegate?.didUpdatePromptSelection(self, prompt: nil)
            return
        }

        // Find the prompt option that matches the selected item's title
        let prompt = PromptOption.allCases.first { $0.displayName == selectedItem.title }
        delegate?.didUpdatePromptSelection(self, prompt: prompt)
    }
}
