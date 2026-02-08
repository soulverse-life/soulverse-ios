//
//  UserModel.swift
//  Soulverse
//

import Foundation

struct UserModel: Codable {
    let uid: String
    let email: String
    let displayName: String
    let platform: String
    var birthday: Date?
    var gender: String?
    var planetName: String?
    var emoPetName: String?
    var selectedTopic: String?
    var hasCompletedOnboarding: Bool
    var fcmToken: String?
    var createdAt: Date
    var updatedAt: Date
}
