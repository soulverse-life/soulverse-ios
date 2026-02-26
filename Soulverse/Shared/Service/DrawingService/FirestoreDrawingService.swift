//
//  FirestoreDrawingService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore
import UIKit

final class FirestoreDrawingService {

    private static let db = Firestore.firestore()

    private typealias Field = DrawingModel.CodingKeys

    enum ServiceError: LocalizedError {
        case documentNotFound
        case notLoggedIn

        var errorDescription: String? {
            switch self {
            case .documentNotFound:
                return "Drawing document not found"
            case .notLoggedIn:
                return NSLocalizedString("drawing_save_not_logged_in",
                                         comment: "Error when user is not logged in")
            }
        }
    }

    /// Returns the drawings subcollection reference for a user.
    private static func drawingsCollection(uid: String) -> CollectionReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.drawings)
    }

    // MARK: - Submit Drawing

    /// Uploads image + recording to Storage in parallel, then creates Firestore document.
    /// Cleans up orphaned Storage files on partial failure.
    /// Returns the auto-generated drawing document ID on success.
    static func submitDrawing(
        uid: String,
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let isFromCheckIn = checkinId != nil

        // Generate document ID first so Storage paths use the same ID
        let docRef = drawingsCollection(uid: uid).document()
        let drawingId = docRef.documentID

        // Step 1: Upload image and recording in parallel
        let group = DispatchGroup()
        var imageURL: String?
        var recordingURL: String?
        var uploadError: Error?

        group.enter()
        FirebaseStorageService.uploadDrawingImage(uid: uid, drawingId: drawingId, image: image) { result in
            switch result {
            case .success(let url):
                imageURL = url
            case .failure(let error):
                uploadError = uploadError ?? error
            }
            group.leave()
        }

        group.enter()
        FirebaseStorageService.uploadDrawingRecording(uid: uid, drawingId: drawingId, recordingData: recordingData) { result in
            switch result {
            case .success(let url):
                recordingURL = url
            case .failure(let error):
                uploadError = uploadError ?? error
            }
            group.leave()
        }

        group.notify(queue: .global()) {
            // If either upload failed, clean up any successful uploads (best-effort)
            if let error = uploadError {
                FirebaseStorageService.deleteDrawingFiles(uid: uid, drawingId: drawingId) { _ in }
                completion(.failure(error))
                return
            }

            guard let imageURL = imageURL, let recordingURL = recordingURL else {
                completion(.failure(ServiceError.documentNotFound))
                return
            }

            // Step 2: Create Firestore document
            let timezoneOffset = TimeZone.current.secondsFromGMT() / 60

            var fields: [String: Any] = [
                Field.isFromCheckIn.rawValue: isFromCheckIn,
                Field.imageURL.rawValue: imageURL,
                Field.recordingURL.rawValue: recordingURL,
                Field.timezoneOffsetMinutes.rawValue: timezoneOffset,
                Field.createdAt.rawValue: FieldValue.serverTimestamp(),
                Field.updatedAt.rawValue: FieldValue.serverTimestamp()
            ]

            if let checkinId = checkinId {
                fields[Field.checkinId.rawValue] = checkinId
            }
            if let promptUsed = promptUsed {
                fields[Field.promptUsed.rawValue] = promptUsed
            }

            docRef.setData(fields) { error in
                if let error = error {
                    // Firestore write failed — clean up Storage files (best-effort)
                    FirebaseStorageService.deleteDrawingFiles(uid: uid, drawingId: drawingId) { _ in }
                    completion(.failure(error))
                } else {
                    completion(.success(drawingId))
                }
            }
        }
    }

    // MARK: - Fetch Drawings by Date Range

    /// Fetches drawings within a date range, ordered by createdAt descending.
    static func fetchDrawings(
        uid: String,
        from startDate: Date,
        to endDate: Date? = nil,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    ) {
        var query: Query = drawingsCollection(uid: uid)
            .whereField(Field.createdAt.rawValue, isGreaterThanOrEqualTo: Timestamp(date: startDate))

        if let endDate = endDate {
            query = query.whereField(Field.createdAt.rawValue, isLessThan: Timestamp(date: endDate))
        }

        query
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

                let drawings = documents.compactMap { doc in
                    try? doc.data(as: DrawingModel.self)
                }
                completion(.success(drawings))
            }
    }

    // MARK: - Fetch Drawings by Check-In ID

    /// Fetches all drawings linked to a specific check-in.
    static func fetchDrawings(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    ) {
        drawingsCollection(uid: uid)
            .whereField(Field.checkinId.rawValue, isEqualTo: checkinId)
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

                let drawings = documents.compactMap { doc in
                    try? doc.data(as: DrawingModel.self)
                }
                completion(.success(drawings))
            }
    }

    // MARK: - Delete Drawing

    /// Deletes a drawing document and its associated Storage files.
    static func deleteDrawing(
        uid: String,
        drawingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Delete Firestore document first
        drawingsCollection(uid: uid).document(drawingId).delete { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            // Then delete Storage files (best-effort)
            FirebaseStorageService.deleteDrawingFiles(uid: uid, drawingId: drawingId) { _ in
                // Storage cleanup is best-effort; report success regardless
                completion(.success(()))
            }
        }
    }
}
