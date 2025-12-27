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
    func didSelectPrompt(_ view: PromptSelectionView, prompt: PromptOption)
}

/// A view that prompts the user to select a prompt option
/// Contains a prompt label and prompt tags view
class PromptSelectionView: UIView {

    // MARK: - Properties

    weak var delegate: PromptSelectionViewDelegate?

    private var selectedPrompt: PromptOption?

    // MARK: - Layout Constants

    private enum Layout {
        static let promptTagsHeight: CGFloat = 180
        static let instructionToTagsSpacing: CGFloat = 16
    }

    // MARK: - UI Elements

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_shaping_choose_prompt", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var promptTagsView: SoulverseTagsView = {
        let config = SoulverseTagsViewConfig(
            horizontalSpacing: 12, verticalSpacing: 12, itemHeight: 44)
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
            make.height.equalTo(Layout.promptTagsHeight)
        }
    }

    private func setupPromptTags() {
        let prompts = PromptOption.allCases.map { prompt in
            SoulverseTagsItemData(title: prompt.displayName, isSelected: false)
        }
        promptTagsView.setItems(prompts)
    }

    // MARK: - Public Methods

    /// Get the currently selected prompt
    /// - Returns: The selected prompt option, or nil if none selected
    func getSelectedPrompt() -> PromptOption? {
        return selectedPrompt
    }
}

// MARK: - SoulverseTagsViewDelegate

extension PromptSelectionView: SoulverseTagsViewDelegate {
    func soulverseTagsView(
        _ view: SoulverseTagsView, didUpdateSelectedItems items: [SoulverseTagsItemData]
    ) {
        guard let selectedItem = items.first else {
            selectedPrompt = nil
            return
        }

        // Find the prompt option that matches the selected item's title
        if let prompt = PromptOption.allCases.first(where: { $0.displayName == selectedItem.title })
        {
            selectedPrompt = prompt
            delegate?.didSelectPrompt(self, prompt: prompt)
        }
    }
}
