//
//  OnboardingSessionServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol OnboardingSessionServiceProtocol {
    var isUserAuthenticated: Bool { get }
    var hasUserCompletedOnboarding: Bool { get }
    func markOnboardingAsCompleted()
    func clearSession()
}
