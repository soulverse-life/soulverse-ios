//
//  SatisfactionSurveyDefinition.swift
//  Soulverse
//
//  32-question Satisfaction Check-In survey. Same 8-category averaging as
//  Importance, but with satisfaction-scale wording. Surfaces topCategory
//  (most satisfied area) + lowestCategory (room for growth).
//
//  Has NO effect on focusDimension — Satisfaction is observational, not
//  directional (per design D24).
//

import Foundation

enum SatisfactionSurveyDefinition {

    static let kind: QuestSurveyType = .satisfactionCheckIn
    static let titleKey = "quest_survey_satisfaction_title"
    static let questionCount = 32

    static func make() -> SurveyDefinition {
        let questions = SurveyDefinition.questions(
            prefix: "quest_survey_satisfaction",
            count: questionCount
        )
        return SurveyDefinition(
            kind: kind,
            titleKey: titleKey,
            scale: .satisfaction,
            questions: questions,
            score: scoreFunction
        )
    }

    static let scoreFunction: ([SurveyResponse]) throws -> SurveyComputedResult = { responses in
        guard responses.count == questionCount else {
            throw SurveyDefinition.ScoringError.wrongResponseCount(expected: questionCount, actual: responses.count)
        }
        let values = responses.map { $0.value }
        let means = ImportanceSurveyDefinition.categoryMeans(from: values)
        let max = means.values.max() ?? 0
        let min = means.values.min() ?? 0
        let priorityOrder: [Topic] = [
            .physical, .emotional, .social, .intellectual,
            .spiritual, .occupational, .environment, .financial
        ]
        let top = priorityOrder.first(where: { (means[$0] ?? 0) == max }) ?? .physical
        let lowest = priorityOrder.first(where: { (means[$0] ?? 0) == min }) ?? .physical

        return .satisfaction(
            categoryMeans: means,
            topCategory: top,
            lowestCategory: lowest
        )
    }
}
