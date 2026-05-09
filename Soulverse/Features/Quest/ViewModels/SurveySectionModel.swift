//
//  SurveySectionModel.swift
//  Soulverse
//
//  ViewModel types for the Quest tab Survey section. Composed by
//  `SurveySectionComposer` from `QuestStateModel` + recent submissions.
//

import Foundation

/// Single card in the PendingSurveyDeck.
struct PendingSurveyCardModel: Equatable {
    let surveyType: QuestSurveyType
    let eligibleSince: Date
    let titleKey: String
    let bodyKey: String
}

/// Deck-of-cards container; first card is "front".
struct PendingSurveyDeckModel: Equatable {
    let cards: [PendingSurveyCardModel]   // sorted oldest-eligibleSince first

    var frontCard: PendingSurveyCardModel? { cards.first }
    var stackedBehindCount: Int { max(0, cards.count - 1) }
    var moreBadgeCount: Int { cards.count >= 3 ? cards.count - 2 : 0 }
    var isEmpty: Bool { cards.isEmpty }
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
    case composed(deck: PendingSurveyDeckModel, results: [RecentResultCardModel])
}
