//
//  EightDimSurveyDefinition.swift
//  Soulverse
//
//  10-question 8-Dim survey, run per-dimension. Score = total/10, range 1.0-5.0.
//  Three stages: 1 (1.0-2.4), 2 (2.5-3.7), 3 (3.8-5.0). Stage names per
//  dimension are localized via key conventions.
//

import Foundation

enum EightDimSurveyDefinition {

    static let kind: QuestSurveyType = .eightDim
    static let titleKey = "quest_survey_8dim_title"
    static let questionCount = 10

    static func make(dimension: WellnessDimension) -> SurveyDefinition {
        let questions = SurveyDefinition.questions(
            prefix: "quest_survey_8dim_\(dimension.rawValue)",
            count: questionCount
        )
        return SurveyDefinition(
            kind: kind,
            titleKey: titleKey,
            scale: .agreement,
            questions: questions,
            score: { responses in try score(dimension: dimension, responses: responses) }
        )
    }

    /// Map mean score to a 1-3 stage.
    static func stage(forMean mean: Double) -> Int {
        switch mean {
        case ..<2.5:    return 1
        case 2.5..<3.8: return 2
        default:        return 3
        }
    }

    static func score(dimension: WellnessDimension, responses: [SurveyResponse]) throws -> SurveyComputedResult {
        guard responses.count == questionCount else {
            throw SurveyDefinition.ScoringError.wrongResponseCount(expected: questionCount, actual: responses.count)
        }
        let total = responses.map { $0.value }.reduce(0, +)
        let mean = Double(total) / Double(questionCount)
        let stageNum = stage(forMean: mean)
        let stageKey = "quest_stage_8dim_\(dimension.rawValue)_\(stageNum)_label"
        let messageKey = "quest_stage_8dim_\(dimension.rawValue)_\(stageNum)_message"
        return .eightDim(
            dimension: dimension,
            totalScore: total,
            meanScore: mean,
            stage: stageNum,
            stageKey: stageKey,
            messageKey: messageKey
        )
    }
}
