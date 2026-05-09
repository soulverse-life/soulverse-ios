//
//  SurveySectionComposer.swift
//  Soulverse
//
//  Pure-function composer that turns `QuestStateModel` + a recent-submissions
//  array into a `SurveySectionModel`. Framework-agnostic — no UIKit, no
//  Firestore. Per spec §6.5.
//

import Foundation

/// One observed survey submission (mirror of Firestore doc).
struct RecentSurveySubmission: Equatable {
    let submissionId: String
    let surveyType: QuestSurveyType
    let submittedAt: Date
    let dimension: WellnessDimension?    // 8-Dim only
    let stage: Int?                      // 8-Dim or SoC
    let stageKey: String?
}

enum SurveySectionComposer {

    static let unlockDay = 7

    static func compose(
        state: QuestStateModel,
        recentSubmissions: [RecentSurveySubmission]
    ) -> SurveySectionModel {
        guard state.distinctCheckInDays >= unlockDay else { return .hidden }

        // Pending deck — sorted oldest-eligibleSince first.
        let cards: [PendingSurveyCardModel] = state.pendingSurveys
            .compactMap { type -> PendingSurveyCardModel? in
                guard let since = state.surveyEligibleSinceMap[type.rawValue] else { return nil }
                return PendingSurveyCardModel(
                    surveyType: type,
                    eligibleSince: since,
                    titleKey: titleKey(for: type, focus: state.focusDimension),
                    bodyKey: bodyKey(for: type)
                )
            }
            .sorted { $0.eligibleSince < $1.eligibleSince }

        let deck = PendingSurveyDeckModel(cards: cards)

        // Recent results — most recent first, capped to 5.
        let results: [RecentResultCardModel] = recentSubmissions
            .sorted { $0.submittedAt > $1.submittedAt }
            .prefix(5)
            .map(makeRecentResult(from:))

        return .composed(deck: deck, results: results)
    }

    // MARK: - Localization key helpers

    static func titleKey(for type: QuestSurveyType, focus: WellnessDimension?) -> String {
        switch type {
        case .importanceCheckIn:   return "quest_pending_card_importance_title"
        case .eightDim:
            // Per-dimension title; falls back to generic if no focus.
            if let focus = focus {
                return "quest_pending_card_8dim_\(focus.rawValue)_title"
            }
            return "quest_pending_card_8dim_title"
        case .stateOfChange:       return "quest_pending_card_soc_title"
        case .satisfactionCheckIn: return "quest_pending_card_satisfaction_title"
        }
    }

    static func bodyKey(for type: QuestSurveyType) -> String {
        switch type {
        case .importanceCheckIn:   return "quest_pending_card_importance_body"
        case .eightDim:            return "quest_pending_card_8dim_body"
        case .stateOfChange:       return "quest_pending_card_soc_body"
        case .satisfactionCheckIn: return "quest_pending_card_satisfaction_body"
        }
    }

    static func makeRecentResult(from sub: RecentSurveySubmission) -> RecentResultCardModel {
        let titleKey: String
        let summaryKey: String
        switch sub.surveyType {
        case .importanceCheckIn:
            titleKey = "quest_result_card_importance_title"
            summaryKey = "quest_result_card_importance_summary"
        case .eightDim:
            if let dim = sub.dimension, let stage = sub.stage {
                titleKey = "quest_result_card_8dim_\(dim.rawValue)_title"
                summaryKey = "quest_result_card_8dim_\(dim.rawValue)_stage_\(stage)"
            } else {
                titleKey = "quest_result_card_8dim_title"
                summaryKey = "quest_result_card_8dim_summary"
            }
        case .stateOfChange:
            titleKey = "quest_result_card_soc_title"
            if let stage = sub.stage {
                summaryKey = "quest_stage_soc_\(stage)_label"
            } else {
                summaryKey = "quest_result_card_soc_summary"
            }
        case .satisfactionCheckIn:
            titleKey = "quest_result_card_satisfaction_title"
            summaryKey = "quest_result_card_satisfaction_summary"
        }
        return RecentResultCardModel(
            surveyType: sub.surveyType,
            submissionId: sub.submissionId,
            submittedAt: sub.submittedAt,
            titleKey: titleKey,
            summaryKey: summaryKey
        )
    }
}
