//
//  FirestoreMoodCheckInService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreMoodCheckInService {

    private static let db = Firestore.firestore()

    private typealias Field = MoodCheckInModel.CodingKeys

    enum ServiceError: LocalizedError {
        case userNotLoggedIn
        case documentNotFound

        var errorDescription: String? {
            switch self {
            case .userNotLoggedIn:
                return "User is not logged in"
            case .documentNotFound:
                return "Mood check-in document not found"
            }
        }
    }

    /// Returns the mood_checkins subcollection reference for a user.
    private static func checkInsCollection(uid: String) -> CollectionReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.moodCheckIns)
    }

    // MARK: - Submit Mood Check-In

    /// Creates a new mood check-in document in Firestore.
    /// Returns the auto-generated document ID on success.
    static func submitMoodCheckIn(
        uid: String,
        data: MoodCheckInData,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let docRef = checkInsCollection(uid: uid).document()

        let timezoneOffset = TimeZone.current.secondsFromGMT() / 60

        var fields: [String: Any] = [
            Field.colorHex.rawValue: data.colorHexString ?? "",
            Field.colorIntensity.rawValue: data.colorIntensity,
            Field.emotion.rawValue: data.recordedEmotion?.uniqueKey ?? "",
            Field.topic.rawValue: data.selectedTopic?.rawValue ?? "",
            Field.evaluation.rawValue: data.evaluation?.rawValue ?? "",
            Field.timezoneOffsetMinutes.rawValue: timezoneOffset,
            Field.createdAt.rawValue: FieldValue.serverTimestamp(),
            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]

        if let journal = data.journal {
            fields[Field.journal.rawValue] = journal
        }

        docRef.setData(fields) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(docRef.documentID))
            }
        }
    }

    // MARK: - Fetch Latest Check-Ins

    /// Fetches the latest N mood check-ins for a user, ordered by createdAt descending.
    static func fetchLatestCheckIns(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    ) {
        checkInsCollection(uid: uid)
            .order(by: Field.createdAt.rawValue, descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let checkIns = documents.compactMap { doc in
                    try? doc.data(as: MoodCheckInModel.self)
                }
                completion(.success(checkIns))
            }
    }

    // MARK: - Fetch Check-Ins by Date Range

    /// Fetches mood check-ins within a date range, ordered by createdAt ascending.
    static func fetchCheckIns(
        uid: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    ) {
        checkInsCollection(uid: uid)
            .whereField(Field.createdAt.rawValue, isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField(Field.createdAt.rawValue, isLessThan: Timestamp(date: endDate))
            .order(by: Field.createdAt.rawValue, descending: false)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let checkIns = documents.compactMap { doc in
                    try? doc.data(as: MoodCheckInModel.self)
                }
                completion(.success(checkIns))
            }
    }

    // MARK: - Delete Check-In

    /// Deletes a mood check-in document.
    static func deleteCheckIn(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        checkInsCollection(uid: uid).document(checkinId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
