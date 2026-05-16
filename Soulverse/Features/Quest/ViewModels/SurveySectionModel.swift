//
//  SurveySectionModel.swift
//  Soulverse
//

import Foundation

struct PendingSurveyCardModel: Equatable {
    let surveyType: QuestSurveyType
    let eligibleSince: Date
    let descriptionKey: String
}

struct RecentResultCardModel: Equatable {
    let surveyType: QuestSurveyType
    let submissionId: String
    let submittedAt: Date
    let titleKey: String
    let summaryKey: String
}

enum SurveySectionModel: Equatable {
    case hidden
    case composed(pending: PendingSurveyCardModel?, results: [RecentResultCardModel])
}
