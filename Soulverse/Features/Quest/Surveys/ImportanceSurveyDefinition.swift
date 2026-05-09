//
//  ImportanceSurveyDefinition.swift
//  Soulverse
//
//  32-question Importance Check-In survey. Computes 8 wellness category means
//  and picks the highest-mean category as the focus dimension.
//
//  Question wording sourced from wellness assessment doc (Google Doc
//  19wH1834cHdwyIuFfT3YkXOHaXOrES78S).
//
//  Server-side scoring (Plan 1) re-runs the same tie-breaker logic, but the
//  client's computed.topCategory is the source of truth for what's submitted.
//

import Foundation

enum ImportanceSurveyDefinition {

    static let kind: QuestSurveyType = .importanceCheckIn
    static let titleKey = "quest_survey_importance_title"
    static let questionCount = 32

    /// Build the SurveyDefinition.
    static func make() -> SurveyDefinition {
        let questions = SurveyDefinition.questions(prefix: "quest_survey_importance", count: questionCount)
        return SurveyDefinition(
            kind: kind,
            titleKey: titleKey,
            scale: .importance,
            questions: questions,
            score: scoreFunction
        )
    }

    /// Pure scoring function — table-driven from wellness doc formulas.
    /// Q indices are 1-based to match the wellness doc.
    static func categoryMeans(from values: [Int]) -> [WellnessDimension: Double] {
        precondition(values.count == questionCount, "Importance survey requires \(questionCount) responses")

        // Convert to 1-based access.
        func q(_ i: Int) -> Double { Double(values[i - 1]) }

        let physical:      Double = (q(2) + q(3) + q(4) + q(5) + q(15) + q(16)) / 6
        let emotional:     Double = (q(6) + q(7) + q(8) + q(12) + q(14)) / 5
        let social:        Double = (q(19) + q(20) + q(21)) / 3
        let intellectual:  Double = (q(9) + q(10) + q(11) + q(27) + q(28)) / 5
        let spiritual:     Double = (q(7) + q(8) + q(32)) / 3
        let occupational:  Double = q(18) / 1
        let environmental: Double = (q(22) + q(23) + q(30) + q(31)) / 4
        let financial:     Double = (q(17) + q(24) + q(25) + q(26)) / 4

        return [
            .physical: physical, .emotional: emotional, .social: social,
            .intellectual: intellectual, .spiritual: spiritual,
            .occupational: occupational, .environmental: environmental,
            .financial: financial
        ]
    }

    /// Predetermined order used as the level-3 tie-breaker (matches wellness doc).
    private static let priorityOrder: [WellnessDimension] = [
        .physical, .emotional, .social, .intellectual,
        .spiritual, .occupational, .environmental, .financial
    ]

    /// Three-level tie-breaker:
    /// 1. unique highest mean
    /// 2. mood-check-in topic count (passed in by caller; defaults to all-zeros for client-side previews)
    /// 3. predetermined priority order
    static func pickFocus(
        categoryMeans means: [WellnessDimension: Double],
        moodTopicCounts: [WellnessDimension: Int] = [:]
    ) -> (dimension: WellnessDimension, tieBreakerLevel: Int) {

        let dims: [WellnessDimension] = priorityOrder
        let maxMean = dims.compactMap { means[$0] }.max() ?? 0
        let tiedAtMax = dims.filter { (means[$0] ?? 0) == maxMean }

        if tiedAtMax.count == 1 {
            return (tiedAtMax[0], 1)
        }

        // Level 2: among tied, highest mood-check-in topic count
        let maxCount = tiedAtMax.map { moodTopicCounts[$0] ?? 0 }.max() ?? 0
        let tiedAtCount = tiedAtMax.filter { (moodTopicCounts[$0] ?? 0) == maxCount }

        if tiedAtCount.count == 1 {
            return (tiedAtCount[0], 2)
        }

        // Level 3: predetermined order
        for dim in priorityOrder where tiedAtCount.contains(dim) {
            return (dim, 3)
        }
        // Unreachable
        return (.physical, 3)
    }

    static let scoreFunction: ([SurveyResponse]) throws -> SurveyComputedResult = { responses in
        guard responses.count == questionCount else {
            throw SurveyDefinition.ScoringError.wrongResponseCount(expected: questionCount, actual: responses.count)
        }
        let values = responses.map { $0.value }
        let means = categoryMeans(from: values)
        let pick = pickFocus(categoryMeans: means)
        return .importance(
            categoryMeans: means,
            topCategory: pick.dimension,
            tieBreakerLevel: pick.tieBreakerLevel
        )
    }
}
