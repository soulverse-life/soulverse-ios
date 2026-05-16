//
//  QuestMockData.swift
//  Soulverse
//
//  Synthetic fixtures for the Quest tab UI. Used by QuestViewController
//  when `DevConstants.usingMockData == true` — lets us preview the radar,
//  survey deck, and other surfaces without seeding Firestore.
//
//  KEEP OUT OF PRODUCTION PATHS. Anything in this file is read only when
//  the dev flag is on; nothing here should be referenced from
//  production code.
//

import Foundation

extension EightDimensionsRenderModel {
    /// Focus dimension = Physical, State-of-Change stage = 2. Other seven
    /// dimensions render as never-assessed (lock icons at the vertices).
    static var mockPhysicalStage2: EightDimensionsRenderModel {
        var axes: [DimensionAxisState] = Array(repeating: .neverAssessed, count: Topic.allCases.count)
        if let physicalIndex = Topic.allCases.firstIndex(of: .physical) {
            axes[physicalIndex] = .currentFocusWithSoC(stage: 2)
        }
        return EightDimensionsRenderModel(
            axes: axes,
            stateOfChangeIndicator: StateOfChangeIndicatorModel(
                activeStage: 2,
                stageLabelKeys: StateOfChangeIndicatorModel.defaultLabelKeys,
                stageMessageKey: "quest_stage_soc_2_message"
            ),
            isCardLocked: false
        )
    }
}

extension SurveySectionModel {
    /// User past day 7 with one pending Importance survey and one
    /// recently-submitted State-of-Change result.
    static var mockEngagedUser: SurveySectionModel {
        let now = Date()
        let day: TimeInterval = 86_400

        let pending: [PendingSurveyCardModel] = [
            PendingSurveyCardModel(
                surveyType: .importanceCheckIn,
                eligibleSince: now.addingTimeInterval(-3 * day),
                descriptionKey: "quest_pending_card_importance_description"
            )
        ]

        let results: [RecentResultCardModel] = [
            RecentResultCardModel(
                surveyType: .stateOfChange,
                submissionId: "mock-soc-1",
                submittedAt: now.addingTimeInterval(-5 * day),
                titleKey: "quest_result_card_soc_title",
                summaryKey: "quest_stage_soc_2_label"
            )
        ]

        return .composed(pending: pending, results: results)
    }
}
