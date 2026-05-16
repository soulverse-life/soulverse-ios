//
//  FirestoreSurveyService.swift
//  Soulverse
//
//  Write-once survey submissions per design spec §4.3.
//  Path: users/{uid}/survey_submissions/{submissionId}.
//

import Foundation
import FirebaseFirestore

/// One observed survey submission (mirror of a Firestore doc) produced by
/// `observeRecentSubmissions`. Used downstream by `QuestViewModel.from` to
/// build the recent-result cards.
struct RecentSurveySubmission: Equatable {
    let submissionId: String
    let surveyType: QuestSurveyType
    let submittedAt: Date
    let dimension: Topic?    // 8-Dim only
    let stage: Int?          // 8-Dim or SoC
    let stageKey: String?
}

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

    private static func meansDict(_ means: [Topic: Double]) -> [String: Double] {
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

    /// Observes the user's most recent survey submissions for the
    /// RecentResultCardList. Returns a registration the caller cancels on teardown.
    @discardableResult
    static func observeRecentSubmissions(
        uid: String,
        windowDays: Int = 60,
        onChange: @escaping ([RecentSurveySubmission]) -> Void
    ) -> ListenerRegistration {
        let cutoff = Date().addingTimeInterval(-Double(windowDays) * 86_400)
        return db.collection("users").document(uid)
            .collection("survey_submissions")
            .whereField("submittedAt", isGreaterThan: cutoff)
            .order(by: "submittedAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { snap, _ in
                let docs = snap?.documents ?? []
                let items: [RecentSurveySubmission] = docs.compactMap { doc in
                    let d = doc.data()
                    guard let typeRaw = d["surveyType"] as? String,
                          let type = QuestSurveyType(rawValue: typeRaw),
                          let ts = d["submittedAt"] as? Timestamp else { return nil }
                    let payload = d["payload"] as? [String: Any] ?? [:]
                    let computed = payload["computed"] as? [String: Any] ?? [:]
                    let dim: Topic? = {
                        let raw = (payload["dimension"] as? String) ?? (d["dimension"] as? String)
                        return raw.flatMap(Topic.init(rawValue:))
                    }()
                    let stage = computed["stage"] as? Int
                    let stageKey = computed["stageKey"] as? String
                    return RecentSurveySubmission(
                        submissionId: doc.documentID,
                        surveyType: type,
                        submittedAt: ts.dateValue(),
                        dimension: dim,
                        stage: stage,
                        stageKey: stageKey
                    )
                }
                onChange(items)
            }
    }
}
