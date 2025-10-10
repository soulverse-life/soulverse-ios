//
//  OnboardingServiceFactory.swift
//  Soulverse
//

import Foundation

/// Factory for creating onboarding services
/// In production, this will create real service implementations
/// In debug/testing, this can create mock implementations
final class OnboardingServiceFactory {

    // MARK: - Configuration

    private let useMockServices: Bool

    // MARK: - Initialization

    #if DEBUG
    init(useMockServices: Bool = true) {
        self.useMockServices = useMockServices
    }
    #else
    init(useMockServices: Bool = false) {
        self.useMockServices = useMockServices
    }
    #endif

    // MARK: - Service Creation

    func makeAuthenticationService(sessionService: OnboardingSessionServiceProtocol) -> OnboardingAuthenticationServiceProtocol {
        #if DEBUG
        if useMockServices {
            return DebugOnboardingAuthenticationService(sessionService: sessionService)
        }
        #endif

        // TODO: Return real authentication service when ready
        // return RealOnboardingAuthenticationService(sessionService: sessionService)
        fatalError("Real authentication service not implemented yet. Use mock services in debug mode.")
    }

    func makeDataService() -> OnboardingDataServiceProtocol {
        #if DEBUG
        if useMockServices {
            return DebugOnboardingDataService()
        }
        #endif

        // TODO: Return real data service when ready
        // return RealOnboardingDataService()
        fatalError("Real data service not implemented yet. Use mock services in debug mode.")
    }

    func makeSessionService() -> OnboardingSessionServiceProtocol {
        #if DEBUG
        if useMockServices {
            return DebugOnboardingSessionService()
        }
        #endif

        // TODO: Return real session service when ready
        // return RealOnboardingSessionService()
        fatalError("Real session service not implemented yet. Use mock services in debug mode.")
    }
}

// MARK: - Debug-Only Mock Implementations

#if DEBUG

/// Debug implementation of authentication service
/// This simulates successful authentication for UI testing
final class DebugOnboardingAuthenticationService: OnboardingAuthenticationServiceProtocol {

    private let sessionService: OnboardingSessionServiceProtocol
    private let simulatedDelay: TimeInterval

    init(sessionService: OnboardingSessionServiceProtocol, simulatedDelay: TimeInterval = 1.0) {
        self.sessionService = sessionService
        self.simulatedDelay = simulatedDelay
    }

    func authenticateWithGoogle(completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        print("[Debug Auth] Simulating Google sign-in...")
        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedDelay) {
            print("[Debug Auth] Google sign-in successful")
            completion(.success(()))
        }
    }

    func authenticateWithApple(completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        print("[Debug Auth] Simulating Apple sign-in...")
        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedDelay) {
            print("[Debug Auth] Apple sign-in successful")
            completion(.success(()))
        }
    }
}

/// Debug implementation of data service
/// This simulates successful data submission for UI testing
final class DebugOnboardingDataService: OnboardingDataServiceProtocol {

    private let simulatedDelay: TimeInterval

    init(simulatedDelay: TimeInterval = 1.5) {
        self.simulatedDelay = simulatedDelay
    }

    func submitOnboardingData(_ data: OnboardingUserData, completion: @escaping (Result<Void, OnboardingDataError>) -> Void) {
        print("[Debug API] Submitting onboarding data...")
        logOnboardingData(data)

        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedDelay) {
            print("[Debug API] Onboarding data submitted successfully")
            completion(.success(()))
        }
    }

    private func logOnboardingData(_ data: OnboardingUserData) {
        print("  ├─ Birthday: \(data.birthday?.description ?? "N/A")")
        print("  ├─ Gender: \(data.gender?.rawValue ?? "N/A")")
        print("  ├─ Planet Name: \(data.planetName ?? "N/A")")
        print("  ├─ EmoPet Name: \(data.emoPetName ?? "N/A")")
        print("  └─ Topics: \(data.selectedTopics.map { $0.rawValue }.joined(separator: ", "))")
    }
}

/// Debug implementation of session service
/// This uses UserDefaults for simple persistence during UI testing
final class DebugOnboardingSessionService: OnboardingSessionServiceProtocol {

    private enum UserDefaultsKey {
        static let isAuthenticated = "debug_onboarding_is_authenticated"
        static let hasCompletedOnboarding = "debug_onboarding_has_completed"
    }

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
        print("[Debug Session] Onboarding marked as completed")
    }

    func clearSession() {
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.isAuthenticated)
        UserDefaults.standard.removeObject(forKey: UserDefaultsKey.hasCompletedOnboarding)
        print("[Debug Session] Session cleared")
    }
}

#endif
