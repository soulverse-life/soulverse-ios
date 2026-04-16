//
//  StaySafeSectionViewModel.swift
//  Soulverse
//

import Foundation

struct StaySafeSectionViewModel {
    var action: String
    let maxCharacters: Int = 100

    init(action: String = "") {
        self.action = action
    }

    init(from items: [SafetyAction]) {
        self.action = items.sorted(by: { $0.sortOrder < $1.sortOrder }).first?.text ?? ""
    }

    var hasContent: Bool {
        !action.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toSectionData() -> EmotionalBundleSectionData {
        return .staySafe([SafetyAction(text: action, sortOrder: 0)])
    }
}
