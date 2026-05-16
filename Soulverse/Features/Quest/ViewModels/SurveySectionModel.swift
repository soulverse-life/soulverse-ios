//
//  SurveySectionModel.swift
//  Soulverse
//
//  ViewModel types for the Quest tab Survey section. Composed inline by
//  `QuestViewModel.from` from `QuestStateModel` + recent submissions, with
//  per-survey-type localization keys sourced from `QuestSurveyType`.
//

import Foundation

/// One pending survey. The view renders this as a card with a fixed
/// title ("Survey") + per-survey-type description + fixed "Take Survey" CTA.
struct PendingSurveyCardModel: Equatable {
    let surveyType: QuestSurveyType
    let eligibleSince: Date
    /// Localization key for the description body. Varies per survey type
    /// (the title and CTA are universal and rendered by the view directly).
    let descriptionKey: String
}

/// One submission summarized for display in the recent-results list.
struct RecentResultCardModel: Equatable {
    let surveyType: QuestSurveyType
    let submissionId: String
    let submittedAt: Date
    let titleKey: String
    let summaryKey: String
}

/// The Survey section's full composed state.
enum SurveySectionModel: Equatable {
    case hidden                     // distinctCheckInDays < 7
    case composed(pending: [PendingSurveyCardModel], results: [RecentResultCardModel])
}
