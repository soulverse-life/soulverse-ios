//
//  SurveyContent.swift
//  Soulverse
//
//  Survey question + response model used by all 4 Quest surveys.
//

import Foundation

/// One question with a localization key. The displayed text is resolved via
/// NSLocalizedString at render time. The questionKey is also persisted in
/// each submission's response payload (per design spec §4.3 — self-describing
/// response data).
struct SurveyQuestion: Equatable {
    let questionKey: String

    var text: String {
        NSLocalizedString(questionKey, comment: "Survey question")
    }
}

/// Response scale variant. Drives the labels shown beneath each question.
enum SurveyResponseScale {
    /// Importance Check-In: Not important → Extremely important
    case importance
    /// Satisfaction Check-In: Very dissatisfied → Very satisfied
    case satisfaction
    /// 8-Dim survey: Not true for me → Very true for me
    case agreement
    /// State-of-Change: Never → Always
    case frequency

    var optionKeys: [String] {
        switch self {
        case .importance:
            return (1...5).map { "quest_importance_response_\($0)" }
        case .satisfaction:
            return (1...5).map { "quest_satisfaction_response_\($0)" }
        case .agreement, .frequency:
            // 8-Dim and State-of-Change share a 5-point shared scale.
            return (1...5).map { "quest_survey_response_\($0)" }
        }
    }
}

/// One user-given response to one question. Snapshot of the rendered text
/// per spec §4.3 — keeps response data self-describing.
struct SurveyResponse: Equatable {
    let questionKey: String
    let questionText: String
    let value: Int   // 1..5
}
