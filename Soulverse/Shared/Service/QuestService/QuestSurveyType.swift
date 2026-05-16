//
//  QuestSurveyType.swift
//  Soulverse
//
//  Named with the `Quest` prefix to avoid collision with
//  `AppCoordinator.SurveyType` (UI-feedback survey enum).
//

import Foundation

enum QuestSurveyType: String, Codable, CaseIterable {
    case importanceCheckIn = "importance_check_in"
    case eightDim = "8dim"
    case stateOfChange = "state_of_change"
    case satisfactionCheckIn = "satisfaction_check_in"
}

extension QuestSurveyType {

    var pendingDescriptionKey: String {
        switch self {
        case .importanceCheckIn:   return "quest_pending_card_importance_description"
        case .eightDim:            return "quest_pending_card_8dim_description"
        case .stateOfChange:       return "quest_pending_card_soc_description"
        case .satisfactionCheckIn: return "quest_pending_card_satisfaction_description"
        }
    }

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
