//
//  OnboardingUserData.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import Foundation

struct OnboardingUserData {
    var isSignedIn: Bool = false
    var birthday: Date?
    var gender: GenderOption?
    var planetName: String?
    var emoPetName: String?
    var selectedTopic: Topic?

    var isComplete: Bool {
        return isSignedIn &&
               birthday != nil &&
               gender != nil &&
               planetName != nil &&
               emoPetName != nil
    }
}