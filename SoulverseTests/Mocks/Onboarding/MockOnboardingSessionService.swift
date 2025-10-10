//
//  MockOnboardingSessionService.swift
//  Soulverse
//

import Foundation

final class MockOnboardingSessionService: OnboardingSessionServiceProtocol {

    // MARK: - Constants

    private enum UserDefaultsKey {
        static let isAuthenticated = "mock_onboarding_is_authenticated"
        static let hasCompletedOnboarding = "mock_onboarding_has_completed"
    }

    // MARK: - OnboardingSessionServiceProtocol

    var isUserAuthenticated: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKey.isAuthenticated)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.isAuthenticated)
        }
    }

    var hasUserCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultsKey.hasCompletedOnboarding)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.hasCompletedOnboarding)
        }
    }

    func markOnboardingAsCompleted() {
        hasUserCompletedOnboarding = true
        isUserAuthenticated = true
        print("[Mock Session] Onboarding marked as completed")
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.hasCompletedOnboarding)
        print("[Mock Session] Session cleared")
    }
}
