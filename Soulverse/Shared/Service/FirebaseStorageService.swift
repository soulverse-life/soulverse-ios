//
//  FirebaseStorageService.swift
//  Soulverse
//

import Foundation
import FirebaseStorage
import UIKit

final class FirebaseStorageService {

    private static let storage = Storage.storage()

    enum StorageError: LocalizedError {
        case imageConversionFailed
        case downloadURLFailed

        var errorDescription: String? {
            switch self {
            case .imageConversionFailed:
                return "Failed to convert image to PNG data"
            case .downloadURLFailed:
                return "Failed to retrieve download URL"
            }
        }
    }

    // MARK: - Upload Drawing Image

    /// Uploads a rendered drawing image (PNG) to Firebase Storage.
    /// Path: users/{uid}/drawings/{drawingId}/image.png
    static func uploadDrawingImage(
        uid: String,
        drawingId: String,
        image: UIImage,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let imageData = image.pngData() else {
            completion(.failure(StorageError.imageConversionFailed))
            return
        }

        let path = "users/\(uid)/drawings/\(drawingId)/image.png"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"

        ref.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(StorageError.downloadURLFailed))
                }
            }
        }
    }

    // MARK: - Upload Drawing Recording

    /// Uploads PKDrawing binary data to Firebase Storage.
    /// Path: users/{uid}/drawings/{drawingId}/recording.pkd
    static func uploadDrawingRecording(
        uid: String,
        drawingId: String,
        recordingData: Data,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let path = "users/\(uid)/drawings/\(drawingId)/recording.pkd"
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "application/octet-stream"

        ref.putData(recordingData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let url = url {
                    completion(.success(url.absoluteString))
                } else {
                    completion(.failure(StorageError.downloadURLFailed))
                }
            }
        }
    }

    // MARK: - Delete Drawing Files

    /// Deletes all files for a drawing (image, recording, thumbnail).
    /// Silently ignores files that don't exist.
    static func deleteDrawingFiles(
        uid: String,
        drawingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let basePath = "users/\(uid)/drawings/\(drawingId)"
        let fileNames = ["image.png", "recording.pkd", "thumbnail.png"]
        let group = DispatchGroup()
        var firstError: Error?

        for fileName in fileNames {
            group.enter()
            let ref = storage.reference().child("\(basePath)/\(fileName)")
            ref.delete { error in
                // Ignore "object not found" errors (file may not exist)
                if let error = error as NSError?,
                   error.domain == StorageErrorDomain,
                   StorageErrorCode(rawValue: error.code) == .objectNotFound {
                    // File doesn't exist, that's OK
                } else if let error = error, firstError == nil {
                    firstError = error
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
