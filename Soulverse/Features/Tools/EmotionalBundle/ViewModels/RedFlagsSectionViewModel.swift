//
//  RedFlagsSectionViewModel.swift
//  Soulverse
//

import Foundation

struct RedFlagsSectionViewModel {
    var redFlags: [String]  // Fixed count: 2
    let maxCharacters: Int = 200

    init(redFlags: [String] = ["", ""]) {
        self.redFlags = redFlags
    }

    init(from items: [RedFlagItem]) {
        var flags = items.sorted(by: { $0.sortOrder < $1.sortOrder }).map(\.text)
        while flags.count < 2 { flags.append("") }
        self.redFlags = Array(flags.prefix(2))
    }

    var isValid: Bool {
        !redFlags[0].trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasContent: Bool {
        redFlags.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func toSectionData() -> EmotionalBundleSectionData {
        let items = redFlags.enumerated().map { index, text in
            RedFlagItem(text: text, sortOrder: index)
        }
        return .redFlags(items)
    }
}
