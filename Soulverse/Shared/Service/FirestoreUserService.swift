//
//  FirestoreUserService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreUserService {

    private static let db = Firestore.firestore()
    private static let usersCollection = "users"

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
                    "email": email,
                    "displayName": displayName,
                    "platform": platform,
                    "hasCompletedOnboarding": false,
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp()
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
                    "email": email,
                    "displayName": displayName,
                    "updatedAt": FieldValue.serverTimestamp()
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
            "hasCompletedOnboarding": true,
            "updatedAt": FieldValue.serverTimestamp()
        ]

        if let birthday = data.birthday {
            fields["birthday"] = Timestamp(date: birthday)
        }
        if let gender = data.gender {
            fields["gender"] = gender.rawValue
        }
        if let planetName = data.planetName {
            fields["planetName"] = planetName
        }
        if let emoPetName = data.emoPetName {
            fields["emoPetName"] = emoPetName
        }
        if let topic = data.selectedTopic {
            fields["selectedTopic"] = topic.rawValue
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
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        db.collection(usersCollection).document(uid).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data() else {
                completion(.failure(NSError(
                    domain: "FirestoreUserService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "User document not found"]
                )))
                return
            }

            completion(.success(data))
        }
    }

    // MARK: - Update FCM Token

    static func updateFCMToken(uid: String, token: String) {
        db.collection(usersCollection).document(uid).updateData([
            "fcmToken": token,
            "updatedAt": FieldValue.serverTimestamp()
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
