//
//  FirestoreUserService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreUserService {

    private static let db = Firestore.firestore()
    private static let usersCollection = "users"

    private typealias Field = UserModel.CodingKeys

    enum ServiceError: LocalizedError {
        case documentNotFound

        var errorDescription: String? {
            switch self {
            case .documentNotFound:
                return "User document not found"
            }
        }
    }

    // MARK: - Create or Update User

    static func createOrUpdateUser(
        uid: String,
        email: String,
        displayName: String,
        platform: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        let docRef = db.collection(usersCollection).document(uid)

        docRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let isNewUser = !(snapshot?.exists ?? false)

            if isNewUser {
                let data: [String: Any] = [
                    Field.email.rawValue: email,
                    Field.displayName.rawValue: displayName,
                    Field.platform.rawValue: platform,
                    Field.hasCompletedOnboarding.rawValue: false,
                    Field.createdAt.rawValue: FieldValue.serverTimestamp(),
                    Field.updatedAt.rawValue: FieldValue.serverTimestamp()
                ]
                docRef.setData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(true))
                    }
                }
            } else {
                let data: [String: Any] = [
                    Field.email.rawValue: email,
                    Field.displayName.rawValue: displayName,
                    Field.updatedAt.rawValue: FieldValue.serverTimestamp()
                ]
                docRef.updateData(data) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(false))
                    }
                }
            }
        }
    }

    // MARK: - Submit Onboarding Data

    static func submitOnboardingData(
        uid: String,
        data: OnboardingUserData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        var fields: [String: Any] = [
            Field.hasCompletedOnboarding.rawValue: true,
            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]

        if let birthday = data.birthday {
            fields[Field.birthday.rawValue] = Timestamp(date: birthday)
        }
        if let gender = data.gender {
            fields[Field.gender.rawValue] = gender.rawValue
        }
        if let planetName = data.planetName {
            fields[Field.planetName.rawValue] = planetName
        }
        if let emoPetName = data.emoPetName {
            fields[Field.emoPetName.rawValue] = emoPetName
        }
        if let topic = data.selectedTopic {
            fields[Field.selectedTopic.rawValue] = topic.rawValue
        }

        db.collection(usersCollection).document(uid).updateData(fields) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                User.shared.hasCompletedOnboarding = true
                User.shared.emoPetName = data.emoPetName
                User.shared.planetName = data.planetName
                completion(.success(()))
            }
        }
    }

    // MARK: - Fetch User Profile

    static func fetchUserProfile(
        uid: String,
        completion: @escaping (Result<UserModel, Error>) -> Void
    ) {
        db.collection(usersCollection).document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                completion(.failure(ServiceError.documentNotFound))
                return
            }

            do {
                let profile = try snapshot.data(as: UserModel.self)
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Update FCM Token

    static func updateFCMToken(uid: String, token: String) {
        db.collection(usersCollection).document(uid).updateData([
            Field.fcmToken.rawValue: token,
            Field.updatedAt.rawValue: FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("[Firestore] Failed to update FCM token: \(error.localizedDescription)")
            } else {
                print("[Firestore] FCM token updated successfully")
            }
        }
    }

    // MARK: - Delete User

    static func deleteUser(
        uid: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        db.collection(usersCollection).document(uid).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - Check New User

    static func isNewUser(
        uid: String,
        completion: @escaping (Result<Bool, Error>) -> Void
    ) {
        db.collection(usersCollection).document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            completion(.success(!(snapshot?.exists ?? false)))
        }
    }
}
