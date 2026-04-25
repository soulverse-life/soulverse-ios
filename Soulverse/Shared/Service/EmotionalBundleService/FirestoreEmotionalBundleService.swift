//
//  FirestoreEmotionalBundleService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreEmotionalBundleService: EmotionalBundleServiceProtocol {

    static let shared = FirestoreEmotionalBundleService()
    private let db = Firestore.firestore()
    private init() {}

    private func bundleRef(uid: String) -> DocumentReference {
        db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.emotionalBundle)
            .document("default")
    }

    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void) {
        bundleRef(uid: uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let snapshot = snapshot, snapshot.exists else {
                completion(.success(nil))
                return
            }
            do {
                let bundle = try snapshot.data(as: EmotionalBundleModel.self)
                completion(.success(bundle))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void) {
        let fields: [String: Any]
        do {
            fields = try encodeSection(data)
        } catch {
            completion(.failure(error))
            return
        }

        let ref = bundleRef(uid: uid)
        var updateFields = fields
        updateFields["updatedAt"] = FieldValue.serverTimestamp()
        updateFields["version"] = 1

        // Check if document exists to set createdAt only on first write
        ref.getDocument { [weak self] snapshot, _ in
            guard self != nil else { return }
            if snapshot == nil || !snapshot!.exists {
                updateFields["createdAt"] = FieldValue.serverTimestamp()
            }
            ref.setData(updateFields, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    private func encodeSection(_ data: EmotionalBundleSectionData) throws -> [String: Any] {
        let encoder = Firestore.Encoder()
        switch data {
        case .redFlags(let items):
            return ["redFlags": try items.map { try encoder.encode($0) }]
        case .supportMe(let items):
            return ["supportMe": try items.map { try encoder.encode($0) }]
        case .feelCalm(let items):
            return ["feelCalm": try items.map { try encoder.encode($0) }]
        case .staySafe(let items):
            return ["staySafe": try items.map { try encoder.encode($0) }]
        case .professionalSupport(let items):
            return ["professionalSupport": try items.map { try encoder.encode($0) }]
        }
    }
}
