//
//  FirestoreQuestService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreQuestService: QuestServiceProtocol {

    static let shared = FirestoreQuestService()

    private let db = Firestore.firestore()

    private init() {}

    private func stateDocument(uid: String) -> DocumentReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.questState)
            .document(FirestoreCollection.questStateDocId)
    }

    // MARK: - Listen

    func listen(uid: String, onUpdate: @escaping (QuestStateModel) -> Void) -> QuestListenerToken {
        let registration = stateDocument(uid: uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print("[FirestoreQuestService] listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            // Doc may briefly not exist for a fresh user before onUserCreated runs.
            let data = snapshot.data() ?? [:]
            let state = QuestStateModel.fromDictionary(data)
            DispatchQueue.main.async { onUpdate(state) }
        }
        return QuestListenerToken { registration.remove() }
    }

    // MARK: - Write timezone (only client-writable fields)

    func writeTimezone(
        uid: String,
        offsetMinutes: Int,
        notificationHour: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "timezoneOffsetMinutes": offsetMinutes,
            "notificationHour": notificationHour
        ]
        // Use setData(merge:) so the call works even before the doc has been
        // created by Plan 1's onUserCreated trigger (race on first sign-in).
        stateDocument(uid: uid).setData(payload, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
