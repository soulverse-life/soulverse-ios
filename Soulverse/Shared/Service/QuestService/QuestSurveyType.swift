//
//  QuestSurveyType.swift
//  Soulverse
//
//  Onboarding Quest survey types. Renamed from `SurveyType` to avoid
//  collision with `AppCoordinator.SurveyType` (UI-feedback survey enum).
//
//  Localization keys for the Survey section's card copy live as
//  computed properties on the type itself — keeps presentation knowledge
//  attached to the entity it describes.
//

import Foundation

enum QuestSurveyType: String, Codable, CaseIterable {
    case importanceCheckIn = "importance_check_in"
    case eightDim = "8dim"
    case stateOfChange = "state_of_change"
    case satisfactionCheckIn = "satisfaction_check_in"
}

extension QuestSurveyType {

    /// Description body for the pending survey card. Title ("Survey") and
    /// CTA ("Take Survey") are universal and rendered by the view directly.
    var pendingDescriptionKey: String {
        switch self {
        case .importanceCheckIn:   return "quest_pending_card_importance_description"
        case .eightDim:            return "quest_pending_card_8dim_description"
        case .stateOfChange:       return "quest_pending_card_soc_description"
        case .satisfactionCheckIn: return "quest_pending_card_satisfaction_description"
        }
    }

    /// Title for a recent-result card. The 8-Dim variant interpolates the
    /// submission's dimension into the key; falls back to a generic key when
    /// the dimension is missing.
    func resultTitleKey(dimension: Topic?) -> String {
        switch self {
        case .importanceCheckIn:   return "quest_result_card_importance_title"
        case .eightDim:
            if let dim = dimension {
                return "quest_result_card_8dim_\(dim.rawValue)_title"
            }
            return "quest_result_card_8dim_title"
        case .stateOfChange:       return "quest_result_card_soc_title"
        case .satisfactionCheckIn: return "quest_result_card_satisfaction_title"
        }
    }

    /// Summary line for a recent-result card. 8-Dim interpolates dimension +
    /// stage; SoC interpolates stage into the shared `quest_stage_soc_*_label`
    /// keys. Generic fallbacks when those parts are missing.
    func resultSummaryKey(dimension: Topic?, stage: Int?) -> String {
        switch self {
        case .importanceCheckIn:   return "quest_result_card_importance_summary"
        case .eightDim:
            if let dim = dimension, let stage = stage {
                return "quest_result_card_8dim_\(dim.rawValue)_stage_\(stage)"
            }
            return "quest_result_card_8dim_summary"
        case .stateOfChange:
            if let stage = stage {
                return "quest_stage_soc_\(stage)_label"
            }
            return "quest_result_card_soc_summary"
        case .satisfactionCheckIn: return "quest_result_card_satisfaction_summary"
        }
    }
}
