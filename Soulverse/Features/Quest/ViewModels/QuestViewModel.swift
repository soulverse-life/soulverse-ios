//
//  QuestViewModel.swift
//  Soulverse
//
//  Framework-agnostic view model derived from QuestStateModel +
//  client-only signals (didCheckInToday, customHabitExists). All fields are
//  pure functions of inputs; no side effects.
//

import Foundation

// MARK: - Radar / Line chart data (used by QuestRadarChartView; Plan 5 will refactor)

struct RadarChartMetric {
    let label: String
    let value: Double
    let maxValue: Double

    var normalizedValue: Double {
        return min(value / maxValue, 1.0)
    }
}

struct QuestRadarData {
    let metrics: [RadarChartMetric]
    let title: String

    init(title: String, metrics: [RadarChartMetric]) {
        self.title = title
        self.metrics = metrics
    }
}

struct StageProgressPoint {
    let stage: Int
    let value: Double
    let date: Date
}

struct QuestLineData {
    let points: [StageProgressPoint]
    let title: String
    let maxStage: Int

    init(title: String, points: [StageProgressPoint]) {
        self.title = title
        self.points = points.sorted { $0.stage < $1.stage }
        self.maxStage = points.map { $0.stage }.max() ?? 0
    }
}

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

    // Plan 5 will reintroduce a focused-axis radar field; until then the
    // existing QuestRadarChartView stays consumer-less in this plan.
    var radarChartData: QuestRadarData?
    var lineChartData: QuestLineData?

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
            radarChartData: nil,
            lineChartData: nil
        )
    }
}
