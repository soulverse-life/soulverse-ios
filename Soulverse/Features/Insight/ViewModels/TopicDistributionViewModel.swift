//
//  TopicDistributionViewModel.swift
//  Soulverse
//

import Foundation

struct TopicDistributionViewModel {
    let title: String
    let items: [TopicDistributionItem]

    struct TopicDistributionItem {
        let topic: Topic
        let count: Int
        let percentage: Double  // 0.0 to 1.0, relative to the max count
    }
}

// MARK: - Factory from Firestore Data

extension TopicDistributionViewModel {
    /// Build from mood check-in data. Fixed order: Topic.allCases
    static func from(checkIns: [MoodCheckInModel]) -> TopicDistributionViewModel {
        // Count occurrences of each topic
        var topicCounts: [Topic: Int] = [:]
        for topic in Topic.allCases {
            topicCounts[topic] = 0
        }
        for checkIn in checkIns {
            if let topic = Topic(rawValue: checkIn.topic) {
                topicCounts[topic, default: 0] += 1
            }
        }

        let maxCount = topicCounts.values.max() ?? 1

        let items = Topic.allCases.map { topic in
            let count = topicCounts[topic] ?? 0
            let percentage = maxCount > 0 ? Double(count) / Double(maxCount) : 0.0
            return TopicDistributionItem(topic: topic, count: count, percentage: percentage)
        }

        return TopicDistributionViewModel(
            title: NSLocalizedString("insight_dimensions_title", comment: ""),
            items: items
        )
    }
}
