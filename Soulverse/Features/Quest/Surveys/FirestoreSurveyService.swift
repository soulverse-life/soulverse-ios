//
//  FirestoreSurveyService.swift
//  Soulverse
//
//  Write-once survey submissions per design spec §4.3.
//  Path: users/{uid}/survey_submissions/{submissionId}.
//

import Foundation
import FirebaseFirestore

enum FirestoreSurveyService {

    private static var db: Firestore { Firestore.firestore() }

    /// Encode a SurveyComputedResult into the Firestore payload shape that
    /// Cloud Functions (Plan 1) expects.
    static func encodePayload(
        responses: [SurveyResponse],
        result: SurveyComputedResult
    ) -> [String: Any] {
        let responsesArray = responses.map { resp -> [String: Any] in
            [
                "questionKey":  resp.questionKey,
                "questionText": resp.questionText,
                "value":        resp.value
            ]
        }

        switch result {
        case let .importance(means, top, level):
            return [
                "responses": responsesArray,
                "computed": [
                    "categoryMeans":   meansDict(means),
                    "topCategory":     top.rawValue,
                    "tieBreakerLevel": level
                ]
            ]
        case let .eightDim(dimension, total, mean, stage, stageKey, messageKey):
            return [
                "dimension": dimension.rawValue,
                "responses": responsesArray,
                "computed": [
                    "totalScore": total,
                    "meanScore":  mean,
                    "stage":      stage,
                    "stageKey":   stageKey,
                    "messageKey": messageKey
                ]
            ]
        case let .stateOfChange(means, index, stage, stageKey, stageMessageKey):
            return [
                "responses": responsesArray,
                "computed": [
                    "substageMeans":    means,
                    "readinessIndex":   index,
                    "stage":            stage,
                    "stageKey":         stageKey,
                    "stageMessageKey":  stageMessageKey
                ]
            ]
        case let .satisfaction(means, top, lowest):
            return [
                "responses": responsesArray,
                "computed": [
                    "categoryMeans":   meansDict(means),
                    "topCategory":     top.rawValue,
                    "lowestCategory":  lowest.rawValue
                ]
            ]
        }
    }

    private static func meansDict(_ means: [WellnessDimension: Double]) -> [String: Double] {
        var out: [String: Double] = [:]
        for (k, v) in means { out[k.rawValue] = v }
        return out
    }

    /// Submits a survey. Per spec §7.2, submittedAt is server-stamped at
    /// rule-validation time (rule asserts request.resource.data.submittedAt
    /// == request.time).
    static func submit(
        uid: String,
        kind: QuestSurveyType,
        responses: [SurveyResponse],
        result: SurveyComputedResult,
        appVersion: String,
        submittedFromQuestDay: Int,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let submissionId = UUID().uuidString
        let payload = encodePayload(responses: responses, result: result)

        let doc: [String: Any] = [
            "submissionId":          submissionId,
            "surveyType":            kind.rawValue,
            "submittedAt":           FieldValue.serverTimestamp(),
            "appVersion":            appVersion,
            "submittedFromQuestDay": submittedFromQuestDay,
            "payload":               payload
        ]

        db.collection("users").document(uid)
            .collection("survey_submissions").document(submissionId)
            .setData(doc) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(submissionId))
                }
            }
    }
}
