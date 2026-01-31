//
//  SoulverseTopicList.swift
//  Soulverse
//

import UIKit
import SnapKit

// MARK: - Delegate Protocol

protocol SoulverseTopicListDelegate: AnyObject {
    func topicList(_ topicList: SoulverseTopicList, didSelectTopic topic: Topic)
    func topicList(_ topicList: SoulverseTopicList, didDeselectTopic topic: Topic)
    func topicList(_ topicList: SoulverseTopicList, didUpdateSelection selectedTopics: [Topic])
}

// MARK: - Default Implementation

extension SoulverseTopicListDelegate {
    func topicList(_ topicList: SoulverseTopicList, didSelectTopic topic: Topic) {}
    func topicList(_ topicList: SoulverseTopicList, didDeselectTopic topic: Topic) {}
}

// MARK: - SoulverseTopicList

class SoulverseTopicList: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let numberOfColumns = 2
        static let cardHeight: CGFloat = 80
        static let horizontalSpacing: CGFloat = 8
        static let verticalSpacing: CGFloat = 8
    }

    // MARK: - Properties

    weak var delegate: SoulverseTopicListDelegate?

    /// Number of topics that can be selected. 1 = single selection, 2+ = multi selection with limit
    private let targetSelectedCount: Int
    private var topicCards: [TopicCardView] = []
    private(set) var selectedTopics: [Topic] = []

    // MARK: - Initialization

    /// Creates a topic list with the specified selection limit
    /// - Parameter targetSelectedCount: Maximum number of topics that can be selected. Default is 1 (single selection)
    init(targetSelectedCount: Int = 1) {
        self.targetSelectedCount = max(1, targetSelectedCount)
        super.init(frame: .zero)
        setupGrid()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    /// Pre-select topics programmatically
    func setSelectedTopics(_ topics: [Topic]) {
        // Clear current selection
        topicCards.forEach { $0.isCardSelected = false }
        selectedTopics.removeAll()

        // Select up to targetSelectedCount topics
        let topicsToSelect = Array(topics.prefix(targetSelectedCount))
        for topic in topicsToSelect {
            if let index = Topic.allCases.firstIndex(of: topic), index < topicCards.count {
                topicCards[index].isCardSelected = true
                selectedTopics.append(topic)
            }
        }

        delegate?.topicList(self, didUpdateSelection: selectedTopics)
    }

    /// Clear all selections
    func clearSelection() {
        topicCards.forEach { $0.isCardSelected = false }
        selectedTopics.removeAll()
        delegate?.topicList(self, didUpdateSelection: selectedTopics)
    }

    // MARK: - Private Methods

    private func setupGrid() {
        let topics = Topic.allCases

        for (index, topic) in topics.enumerated() {
            let card = TopicCardView(topic: topic)
            card.tag = index
            card.isUserInteractionEnabled = true

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
            card.addGestureRecognizer(tapGesture)

            addSubview(card)

            let row = index / Layout.numberOfColumns
            let column = index % Layout.numberOfColumns

            card.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(CGFloat(row) * (Layout.cardHeight + Layout.verticalSpacing))
                make.height.equalTo(Layout.cardHeight)

                if column == 0 {
                    // Left column
                    make.left.equalToSuperview()
                    make.right.equalTo(snp.centerX).offset(-Layout.horizontalSpacing / 2)
                } else {
                    // Right column
                    make.left.equalTo(snp.centerX).offset(Layout.horizontalSpacing / 2)
                    make.right.equalToSuperview()
                }
            }

            topicCards.append(card)
        }
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view as? TopicCardView else { return }
        let topic = Topic.allCases[card.tag]
        handleTap(on: card, for: topic)
    }

    private func handleTap(on card: TopicCardView, for topic: Topic) {
        if targetSelectedCount == 1 {
            // Single selection mode: deselect all others, select this one
            topicCards.forEach { $0.isCardSelected = false }
            card.isCardSelected = true
            selectedTopics = [topic]
            delegate?.topicList(self, didSelectTopic: topic)
        } else {
            // Multi selection mode with limit
            if card.isCardSelected {
                // Deselect
                card.isCardSelected = false
                selectedTopics.removeAll { $0 == topic }
                delegate?.topicList(self, didDeselectTopic: topic)
            } else {
                // Check if we can select more
                if selectedTopics.count < targetSelectedCount {
                    card.isCardSelected = true
                    selectedTopics.append(topic)
                    delegate?.topicList(self, didSelectTopic: topic)
                }
                // If at limit, do nothing (user must deselect one first)
            }
        }

        delegate?.topicList(self, didUpdateSelection: selectedTopics)
    }

    // MARK: - Intrinsic Content Size

    override var intrinsicContentSize: CGSize {
        let topics = Topic.allCases
        let rowCount = (topics.count + Layout.numberOfColumns - 1) / Layout.numberOfColumns
        let height = CGFloat(rowCount) * Layout.cardHeight + CGFloat(rowCount - 1) * Layout.verticalSpacing
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}
