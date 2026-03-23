//
//  FirestoreJournalService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreJournalService: JournalServiceProtocol {

    static let shared = FirestoreJournalService()

    private let db = Firestore.firestore()

    private typealias Field = JournalModel.CodingKeys
    private typealias CheckInField = MoodCheckInModel.CodingKeys

    private init() {}

    enum ServiceError: LocalizedError {
        case documentNotFound
        case notLoggedIn

        var errorDescription: String? {
            switch self {
            case .documentNotFound:
                return "Journal document not found"
            case .notLoggedIn:
                return "User is not logged in"
            }
        }
    }

    /// Returns the journals subcollection reference for a user.
    private func journalsCollection(uid: String) -> CollectionReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.journals)
    }

    /// Returns the mood_checkins document reference for a user.
    private func checkInDocument(uid: String, checkinId: String) -> DocumentReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.moodCheckIns)
            .document(checkinId)
    }

    // MARK: - Submit Journal

    /// Creates a new journal document and sets the linked check-in's journalId in a batch write.
    /// Returns the auto-generated journal document ID on success.
    func submitJournal(
        uid: String,
        checkinId: String,
        title: String?,
        content: String?,
        prompt: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let journalRef = journalsCollection(uid: uid).document()
        let checkinRef = checkInDocument(uid: uid, checkinId: checkinId)

        let timezoneOffset = TimeZone.current.secondsFromGMT() / 60

        var fields: [String: Any] = [
            Field.checkinId.rawValue: checkinId,
            Field.timezoneOffsetMinutes.rawValue: timezoneOffset,
            Field.createdAt.rawValue: FieldValue.serverTimestamp(),
            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]

        if let title = title {
            fields[Field.title.rawValue] = title
        }
        if let content = content {
            fields[Field.content.rawValue] = content
        }
        if let prompt = prompt {
            fields[Field.prompt.rawValue] = prompt
        }

        let batch = db.batch()
        batch.setData(fields, forDocument: journalRef)
        batch.updateData([
            CheckInField.journalId.rawValue: journalRef.documentID,
            CheckInField.updatedAt.rawValue: FieldValue.serverTimestamp()
        ], forDocument: checkinRef)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(journalRef.documentID))
            }
        }
    }

    // MARK: - Fetch Journal by ID

    /// Fetches a single journal document by its ID.
    func fetchJournal(
        uid: String,
        journalId: String,
        completion: @escaping (Result<JournalModel, Error>) -> Void
    ) {
        journalsCollection(uid: uid).document(journalId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists,
                  let journal = try? snapshot.data(as: JournalModel.self) else {
                completion(.failure(ServiceError.documentNotFound))
                return
            }

            completion(.success(journal))
        }
    }

    // MARK: - Fetch Journal by Check-In ID

    /// Fetches the journal linked to a specific check-in (0 or 1 result).
    func fetchJournal(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<JournalModel?, Error>) -> Void
    ) {
        journalsCollection(uid: uid)
            .whereField(Field.checkinId.rawValue, isEqualTo: checkinId)
            .limit(to: 1)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success(nil))
                    return
                }

                let journal = documents.first.flatMap { try? $0.data(as: JournalModel.self) }
                completion(.success(journal))
            }
    }

    // MARK: - Fetch Journals by Date Range

    /// Fetches journals within a date range, ordered by createdAt descending.
    func fetchJournals(
        uid: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[JournalModel], Error>) -> Void
    ) {
        journalsCollection(uid: uid)
            .whereField(Field.createdAt.rawValue, isGreaterThanOrEqualTo: Timestamp(date: startDate))
            .whereField(Field.createdAt.rawValue, isLessThan: Timestamp(date: endDate))
            .order(by: Field.createdAt.rawValue, descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                let journals = documents.compactMap { doc in
                    try? doc.data(as: JournalModel.self)
                }
                completion(.success(journals))
            }
    }

    // MARK: - Update Journal

    /// Updates a journal's title and/or content.
    func updateJournal(
        uid: String,
        journalId: String,
        title: String?,
        content: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var updates: [String: Any] = [
            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]

        if let title = title {
            updates[Field.title.rawValue] = title
        }
        if let content = content {
            updates[Field.content.rawValue] = content
        }

        journalsCollection(uid: uid).document(journalId).updateData(updates) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Delete Journal

    /// Deletes a journal document and clears the linked check-in's journalId in a batch write.
    func deleteJournal(
        uid: String,
        journalId: String,
        checkinId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let journalRef = journalsCollection(uid: uid).document(journalId)
        let checkinRef = checkInDocument(uid: uid, checkinId: checkinId)

        let batch = db.batch()
        batch.deleteDocument(journalRef)
        batch.updateData([
            CheckInField.journalId.rawValue: FieldValue.delete(),
            CheckInField.updatedAt.rawValue: FieldValue.serverTimestamp()
        ], forDocument: checkinRef)

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
