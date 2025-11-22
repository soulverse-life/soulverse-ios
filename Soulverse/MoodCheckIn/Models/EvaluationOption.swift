//
//  EvaluationOption.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum EvaluationOption: String, CaseIterable {
    case acceptAsPartOfLife = "I accept it as part of my life"
    case letItBe = "I let it be, even if it's not easy"
    case tryToPushAway = "I try to push it away or hide it"
    case resistOrFight = "I resist it or fight against it"
    case feelUnsure = "I feel unsure or conflicted about it"

    /// Display name for the evaluation option
    var displayName: String {
        return rawValue
    }
}
