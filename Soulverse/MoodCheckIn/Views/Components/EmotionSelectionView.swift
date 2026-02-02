//
//  EmotionSelectionView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import SnapKit
import UIKit

/// Delegate protocol for emotion selection events
protocol EmotionSelectionViewDelegate: AnyObject {
    func didUpdateEmotions(_ view: EmotionSelectionView, emotions: [EmotionType])
    func didReachMaximumSelection(_ view: EmotionSelectionView)
}

/// A view that prompts the user to select an emotion
/// Contains a prompt label and emotion tags view
class EmotionSelectionView: UIView {

    // MARK: - Properties

    weak var delegate: EmotionSelectionViewDelegate?

    private var selectedEmotions: [EmotionType] = []  // Max 2 emotions
    private let maximumEmotions = 2

    // MARK: - Layout Constants

    private enum Layout {
        static let emotionTagsHeight: CGFloat = 164
        static let promptToTagsSpacing: CGFloat = 16
    }

    // MARK: - UI Elements

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0

        let mainText = NSLocalizedString("mood_checkin_naming_prompt", comment: "")
        let guideText = NSLocalizedString("mood_checkin_naming_prompt_guide", comment: "")
        let fullText = mainText + " " + guideText

        let mainFont = UIFont.projectFont(ofSize: 16, weight: .regular)
        let italicDescriptor = mainFont.fontDescriptor.withSymbolicTraits(.traitItalic) ?? mainFont.fontDescriptor
        let italicFont = UIFont(descriptor: italicDescriptor, size: 16)

        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: mainFont,
                .foregroundColor: UIColor.themeTextPrimary
            ]
        )

        let italicRange = (fullText as NSString).range(of: guideText)
        attributedString.addAttribute(.font, value: italicFont, range: italicRange)

        label.attributedText = attributedString
        return label
    }()

    private lazy var emotionTagsView: SoulverseTagsView = {
        let config = SoulverseTagsViewConfig(
            horizontalSpacing: 8, verticalSpacing: 16, itemHeight: 48)
        let view = SoulverseTagsView(config: config)
        view.selectionMode = .multi
        view.delegate = self
        return view
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupEmotionTags()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(promptLabel)
        addSubview(emotionTagsView)

        setupConstraints()
    }

    private func setupConstraints() {
        promptLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        emotionTagsView.snp.makeConstraints { make in
            make.top.equalTo(promptLabel.snp.bottom).offset(Layout.promptToTagsSpacing)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.emotionTagsHeight)
        }
    }

    private func setupEmotionTags() {
        let emotions = EmotionType.allCases.map { emotion in
            SoulverseTagsItemData(title: emotion.displayName, isSelected: false)
        }
        emotionTagsView.setItems(emotions)
    }

    // MARK: - Public Methods

    /// Get the currently selected emotions (ordered by tag view sequence)
    /// - Returns: Array of selected emotions (max 2)
    func getSelectedEmotions() -> [EmotionType] {
        return sortedSelectedEmotions()
    }

    // MARK: - Private Methods

    /// Sort selected emotions by their index in EmotionType.allCases (tag view order)
    private func sortedSelectedEmotions() -> [EmotionType] {
        let allEmotions = Array(EmotionType.allCases)
        return selectedEmotions.sorted { emotion1, emotion2 in
            let index1 = allEmotions.firstIndex(of: emotion1) ?? 0
            let index2 = allEmotions.firstIndex(of: emotion2) ?? 0
            return index1 < index2
        }
    }

    /// Update the visual selection state of emotion tags
    private func updateTagSelectionState() {
        let allEmotions = Array(EmotionType.allCases)
        let updatedItems = allEmotions.map { emotion in
            SoulverseTagsItemData(
                title: emotion.displayName,
                isSelected: selectedEmotions.contains(emotion)
            )
        }

        // Synchronously update to override SoulverseTagsView's single-selection behavior
        // This ensures the correct multi-selection state is applied immediately
        emotionTagsView.setItems(updatedItems)
    }
}

// MARK: - SoulverseTagsViewDelegate
extension EmotionSelectionView: SoulverseTagsViewDelegate {
    func soulverseTagsView(
        _ view: SoulverseTagsView, didUpdateSelectedItems items: [SoulverseTagsItemData]
    ) {
        let selectedCount = items.filter { $0.isSelected }.count

        if selectedCount <= maximumEmotions {
            // Valid selection
            // Map items back to EmotionType
            let allEmotions = EmotionType.allCases
            let currentSelected = items.filter { $0.isSelected }.compactMap { item in
                allEmotions.first { $0.displayName == item.title }
            }

            self.selectedEmotions = currentSelected
            delegate?.didUpdateEmotions(self, emotions: sortedSelectedEmotions())

        } else {
            // Exceeded maximum - Revert
            // Restore the view's items to match the previously valid `selectedEmotions`
            updateTagSelectionState()

            // Notify delegate of max reach
            delegate?.didReachMaximumSelection(self)
        }
    }
}
