//
//  QuestViewModel.swift
//  Soulverse
//
//  Framework-agnostic view model derived from QuestStateModel +
//  client-only signals (didCheckInToday, customHabitExists). All fields are
//  pure functions of inputs; no side effects.
//

import Foundation

// MARK: - Main ViewModel

struct QuestViewModel {

    // Loading
    var isLoading: Bool

    // Source state
    var state: QuestStateModel

    // Derived: ProgressSection
    var progressSectionVisible: Bool
    var dayPillText: String
    var stage: QuestStage
    var currentDot: Int                // 0..21
    var dailyCheckInCTAVisible: Bool

    // Derived: 8-Dim card lock state
    var eightDimensionsLocked: Bool
    var eightDimensionsLockedHint: String

    // Derived: Custom habit slot
    var customHabitLocked: Bool
    var customHabitLockedHint: String
    var customHabitSlotVisible: Bool

    // Derived: Survey section visibility (consumed by Plan 4)
    var surveySectionVisible: Bool

    // Derived: Plan 5 — Survey section composed state + 8-Dim render model
    var surveySection: SurveySectionModel
    var eightDimensions: EightDimensionsRenderModel

    // MARK: - Stable unlock thresholds

    static let eightDimensionsUnlockDay = 7
    static let customHabitUnlockDay = 14
    static let questCompleteDay = 21
    static let surveySectionUnlockDay = 7

    // MARK: - Initial / loading

    static func loading() -> QuestViewModel {
        return QuestViewModel.from(
            state: .initial(),
            didCheckInToday: false,
            customHabitExists: false,
            isLoading: true
        )
    }

    // MARK: - Pure factory

    static func from(
        state: QuestStateModel,
        didCheckInToday: Bool,
        customHabitExists: Bool,
        recentSubmissions: [RecentSurveySubmission] = [],
        isLoading: Bool = false
    ) -> QuestViewModel {

        let days = state.distinctCheckInDays
        let stage = QuestStage.from(distinctCheckInDays: days)
        let progressVisible = days < questCompleteDay

        let pillFormat = NSLocalizedString(
            "quest_progress_day_pill",
            comment: "Day-N pill text on Quest progress section, e.g. 'Day 5 of 21'"
        )
        let pillText = String(format: pillFormat, days, questCompleteDay)

        let eightDimLocked = days < eightDimensionsUnlockDay
        let eightDimHint = LockedCardHint.copy(
            currentDay: days,
            unlockDay: eightDimensionsUnlockDay,
            featureName: NSLocalizedString(
                "quest_locked_feature_8dim",
                comment: "Verb-phrase: '… see your 8 Dimensions.'"
            )
        )

        let customHabitLocked = days < customHabitUnlockDay
        let customHabitHint = LockedCardHint.copy(
            currentDay: days,
            unlockDay: customHabitUnlockDay,
            featureName: NSLocalizedString(
                "quest_locked_feature_custom_habit",
                comment: "Verb-phrase: '… add your own habit.'"
            )
        )

        let customHabitSlotVisible = !customHabitExists

        let surveySection = SurveySectionComposer.compose(
            state: state, recentSubmissions: recentSubmissions
        )
        let eightDimensions = EightDimensionsRenderModelBuilder.build(state: state)

        return QuestViewModel(
            isLoading: isLoading,
            state: state,
            progressSectionVisible: progressVisible,
            dayPillText: pillText,
            stage: stage,
            currentDot: min(days, questCompleteDay),
            dailyCheckInCTAVisible: progressVisible && !didCheckInToday,
            eightDimensionsLocked: eightDimLocked,
            eightDimensionsLockedHint: eightDimHint,
            customHabitLocked: customHabitLocked,
            customHabitLockedHint: customHabitHint,
            customHabitSlotVisible: customHabitSlotVisible,
            surveySectionVisible: days >= surveySectionUnlockDay,
            surveySection: surveySection,
            eightDimensions: eightDimensions
        )
    }
}
