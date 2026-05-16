//
//  QuestStateModel.swift
//  Soulverse
//
//  Mirrors the server-maintained aggregate doc at
//  users/{uid}/quest_state/state. Plan 1 owns writes for all fields except
//  `timezoneOffsetMinutes` and `notificationHour` (client-writable per
//  Security Rules; see Plan 1 §7.2).
//

import Foundation
import FirebaseFirestore

struct QuestStateModel {

    // Day counter & quest progression
    var distinctCheckInDays: Int
    var lastDistinctDayKey: String?
    var questCompletedAt: Date?

    // Focus dimension & UX state
    var focusDimension: Topic?
    var focusDimensionAssignedAt: Date?

    // Server-derived pending surveys
    var pendingSurveys: [QuestSurveyType]
    var surveyEligibleSinceMap: [String: Date]

    // Survey submission timestamps (denormalized, read-only on client)
    var importanceCheckInSubmittedAt: Date?
    var lastEightDimSubmittedAt: Date?
    var lastEightDimDimension: Topic?
    var lastStateOfChangeSubmittedAt: Date?
    var lastStateOfChangeStage: Int?
    var satisfactionCheckInSubmittedAt: Date?

    // Cron query optimization (client-writable)
    var notificationHour: Int
    var timezoneOffsetMinutes: Int

    static func initial() -> QuestStateModel {
        return QuestStateModel(
            distinctCheckInDays: 0,
            lastDistinctDayKey: nil,
            questCompletedAt: nil,
            focusDimension: nil,
            focusDimensionAssignedAt: nil,
            pendingSurveys: [],
            surveyEligibleSinceMap: [:],
            importanceCheckInSubmittedAt: nil,
            lastEightDimSubmittedAt: nil,
            lastEightDimDimension: nil,
            lastStateOfChangeSubmittedAt: nil,
            lastStateOfChangeStage: nil,
            satisfactionCheckInSubmittedAt: nil,
            notificationHour: 0,
            timezoneOffsetMinutes: 0
        )
    }

    static func fromDictionary(_ data: [String: Any]) -> QuestStateModel {
        let pending: [QuestSurveyType] = (data["pendingSurveys"] as? [String] ?? [])
            .compactMap { QuestSurveyType(rawValue: $0) }

        var eligibleMap: [String: Date] = [:]
        if let raw = data["surveyEligibleSinceMap"] as? [String: Timestamp] {
            for (key, value) in raw { eligibleMap[key] = value.dateValue() }
        }

        return QuestStateModel(
            distinctCheckInDays: data["distinctCheckInDays"] as? Int ?? 0,
            lastDistinctDayKey: data["lastDistinctDayKey"] as? String,
            questCompletedAt: (data["questCompletedAt"] as? Timestamp)?.dateValue(),
            focusDimension: (data["focusDimension"] as? String).flatMap(Topic.init(rawValue:)),
            focusDimensionAssignedAt: (data["focusDimensionAssignedAt"] as? Timestamp)?.dateValue(),
            pendingSurveys: pending,
            surveyEligibleSinceMap: eligibleMap,
            importanceCheckInSubmittedAt: (data["importanceCheckInSubmittedAt"] as? Timestamp)?.dateValue(),
            lastEightDimSubmittedAt: (data["lastEightDimSubmittedAt"] as? Timestamp)?.dateValue(),
            lastEightDimDimension: (data["lastEightDimDimension"] as? String).flatMap(Topic.init(rawValue:)),
            lastStateOfChangeSubmittedAt: (data["lastStateOfChangeSubmittedAt"] as? Timestamp)?.dateValue(),
            lastStateOfChangeStage: data["lastStateOfChangeStage"] as? Int,
            satisfactionCheckInSubmittedAt: (data["satisfactionCheckInSubmittedAt"] as? Timestamp)?.dateValue(),
            notificationHour: data["notificationHour"] as? Int ?? 0,
            timezoneOffsetMinutes: data["timezoneOffsetMinutes"] as? Int ?? 0
        )
    }
}
