//
//  EvaluationOption.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum EvaluationOption: String, CaseIterable {
    case acceptAsPartOfLife
    case letItBe
    case tryToPushAway
    case resistOrFight
    case feelUnsure

    /// Localization key for the evaluation option
    private var localizationKey: String {
        switch self {
        case .acceptAsPartOfLife: return "mood_checkin_evaluating_option_accept"
        case .letItBe: return "mood_checkin_evaluating_option_let_it_be"
        case .tryToPushAway: return "mood_checkin_evaluating_option_resist"
        case .resistOrFight: return "mood_checkin_evaluating_option_dont_know"
        case .feelUnsure: return "mood_checkin_evaluating_option_conflicted"
        }
    }

    /// Display name for the evaluation option
    var displayName: String {
        return NSLocalizedString(localizationKey, comment: "")
    }
}
