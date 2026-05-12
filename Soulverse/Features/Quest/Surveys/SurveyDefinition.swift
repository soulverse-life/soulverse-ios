//
//  SurveyDefinition.swift
//  Soulverse
//
//  Per-survey metadata: questions, response scale, scoring function, result
//  presenter.
//

import Foundation

/// Computed result of a survey submission. The shape varies by surveyType.
enum SurveyComputedResult {
    case importance(categoryMeans: [Topic: Double], topCategory: Topic, tieBreakerLevel: Int)
    case eightDim(dimension: Topic, totalScore: Int, meanScore: Double, stage: Int, stageKey: String, messageKey: String)
    case stateOfChange(substageMeans: [String: Double], readinessIndex: Double, stage: Int, stageKey: String, stageMessageKey: String)
    case satisfaction(categoryMeans: [Topic: Double], topCategory: Topic, lowestCategory: Topic)
}

/// One survey definition: questions + scoring.
struct SurveyDefinition {
    let kind: QuestSurveyType
    let titleKey: String
    let scale: SurveyResponseScale
    let questions: [SurveyQuestion]
    /// Score the user's responses. Throws if responses don't match the
    /// definition's question count.
    let score: ([SurveyResponse]) throws -> SurveyComputedResult

    enum ScoringError: Error {
        case wrongResponseCount(expected: Int, actual: Int)
    }

    /// Lookup table — used by the SurveyViewController router.
    static func definition(for kind: QuestSurveyType, dimension: Topic? = nil) -> SurveyDefinition {
        switch kind {
        case .importanceCheckIn:   return ImportanceSurveyDefinition.make()
        case .eightDim:            return EightDimSurveyDefinition.make(dimension: dimension ?? .emotional)
        case .stateOfChange:       return StateOfChangeSurveyDefinition.make(dimension: dimension ?? .emotional)
        case .satisfactionCheckIn: return SatisfactionSurveyDefinition.make()
        }
    }
}

// MARK: - Helpers

extension SurveyDefinition {
    /// Convenience to build a Q1...QN list of SurveyQuestion structs.
    static func questions(prefix: String, count: Int) -> [SurveyQuestion] {
        (1...count).map { i in
            SurveyQuestion(questionKey: "\(prefix)_q\(String(format: "%02d", i))_text")
        }
    }
}
