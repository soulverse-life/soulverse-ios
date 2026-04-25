//
//  FeelCalmSectionViewModel.swift
//  Soulverse
//

import Foundation

struct FeelCalmSectionViewModel {
    var activities: [String]  // Fixed count: 3
    let maxCharacters: Int = 100

    init(activities: [String] = ["", "", ""]) {
        self.activities = activities
    }

    init(from items: [CalmActivity]) {
        var acts = items.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.text)
        while acts.count < 3 { acts.append("") }
        self.activities = Array(acts.prefix(3))
    }

    var isValid: Bool {
        !activities[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasContent: Bool {
        activities.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func toSectionData() -> EmotionalBundleSectionData {
        let items = activities.enumerated().map { index, text in
            CalmActivity(text: text, sortOrder: index)
        }
        return .feelCalm(items)
    }
}
