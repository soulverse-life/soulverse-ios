//
//  EmotionSelectionView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

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
        static let emotionTagsHeight: CGFloat = 180
        static let promptToTagsSpacing: CGFloat = 16
    }

    // MARK: - UI Elements

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_naming_emotion_prompt", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 0
        return label
    }()

    private lazy var emotionTagsView: SoulverseTagsView = {
        let config = SoulverseTagsViewConfig(horizontalSpacing: 12, verticalSpacing: 12, itemHeight: 44)
        let view = SoulverseTagsView(config: config)
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
    func soulverseTagsView(_ view: SoulverseTagsView, didSelectItemAt index: Int) {
        let emotions = Array(EmotionType.allCases)
        let tappedEmotion = emotions[index]

        // Check if already selected (deselect)
        if let existingIndex = selectedEmotions.firstIndex(of: tappedEmotion) {
            selectedEmotions.remove(at: existingIndex)

            // Update UI and notify delegate
            updateTagSelectionState()
            delegate?.didUpdateEmotions(self, emotions: sortedSelectedEmotions())
        }
        // Check if can add more (max 2)
        else if selectedEmotions.count < maximumEmotions {
            selectedEmotions.append(tappedEmotion)

            // Update UI and notify delegate
            updateTagSelectionState()
            delegate?.didUpdateEmotions(self, emotions: sortedSelectedEmotions())
        }
        // Already at maximum, prevent selection
        else {
            // Revert to correct selection state (SoulverseTagsView just selected the tapped item, we need to undo it)
            updateTagSelectionState()

            // Show feedback to user
            delegate?.didReachMaximumSelection(self)
        }
    }
}
