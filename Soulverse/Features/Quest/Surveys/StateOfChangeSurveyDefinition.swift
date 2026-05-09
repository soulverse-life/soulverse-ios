//
//  StateOfChangeSurveyDefinition.swift
//  Soulverse
//
//  15-question State-of-Change readiness survey. Computes 5 substage means
//  (Precontemplation/Contemplation/Preparation/Action/Maintenance), a
//  Readiness Index, and maps to a 1-of-5 stage with friendly user-facing
//  labels (Considering/Planning/Preparing/Doing/Sustaining).
//

import Foundation

enum StateOfChangeSurveyDefinition {

    static let kind: QuestSurveyType = .stateOfChange
    static let titleKey = "quest_survey_soc_title"
    static let questionCount = 15

    static func make(dimension: WellnessDimension) -> SurveyDefinition {
        let questions = SurveyDefinition.questions(prefix: "quest_survey_soc", count: questionCount)
        return SurveyDefinition(
            kind: kind,
            titleKey: titleKey,
            scale: .frequency,
            questions: questions,
            score: { responses in try score(dimension: dimension, responses: responses) }
        )
    }

    /// Substage question groupings (1-based indices, per wellness doc).
    static let precontemplationQs = [2, 9, 15]
    static let contemplationQs    = [4, 11, 14]
    static let preparationQs      = [6, 10, 12]
    static let actionQs           = [3, 7, 8]
    static let maintenanceQs      = [1, 5, 13]

    /// Readiness Index thresholds → 1-of-5 stage.
    static func stage(forIndex index: Double) -> Int {
        switch index {
        case ..<9.1:   return 1   // Considering
        case 9.1..<13.1:  return 2   // Planning
        case 13.1..<17.1: return 3   // Preparing
        case 17.1..<21.1: return 4   // Doing
        default:           return 5   // Sustaining
        }
    }

    static func score(dimension: WellnessDimension, responses: [SurveyResponse]) throws -> SurveyComputedResult {
        guard responses.count == questionCount else {
            throw SurveyDefinition.ScoringError.wrongResponseCount(expected: questionCount, actual: responses.count)
        }
        let values = responses.map { $0.value }
        func mean(of indices: [Int]) -> Double {
            indices.map { Double(values[$0 - 1]) }.reduce(0, +) / Double(indices.count)
        }

        let pc = mean(of: precontemplationQs)
        let c  = mean(of: contemplationQs)
        let p  = mean(of: preparationQs)
        let a  = mean(of: actionQs)
        let m  = mean(of: maintenanceQs)

        let readinessIndex = pc * 1 + c * 2 + p * 3 + a * 4 + m * 5
        let stageNum = stage(forIndex: readinessIndex)

        return .stateOfChange(
            substageMeans: [
                "precontemplation": pc,
                "contemplation":    c,
                "preparation":      p,
                "action":           a,
                "maintenance":      m
            ],
            readinessIndex: readinessIndex,
            stage: stageNum,
            stageKey: "quest_stage_soc_\(stageNum)_label",
            stageMessageKey: "quest_stage_soc_\(stageNum)_message"
        )
    }
}
