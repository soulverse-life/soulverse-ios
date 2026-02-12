//
//  UserModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

struct UserModel: Codable {
    @DocumentID var uid: String?
    let email: String
    let displayName: String
    let platform: String
    var birthday: Date?
    var gender: String?
    var planetName: String?
    var emoPetName: String?
    var selectedTopic: String?
    var hasCompletedOnboarding: Bool?
    var fcmToken: String?
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case uid
        case email
        case displayName
        case platform
        case birthday
        case gender
        case planetName
        case emoPetName
        case selectedTopic
        case hasCompletedOnboarding
        case fcmToken
        case createdAt
        case updatedAt
    }
}
