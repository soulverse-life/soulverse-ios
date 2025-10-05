//
//  MockOnboardingAuthenticationService.swift
//  Soulverse
//

import Foundation

final class MockOnboardingAuthenticationService: OnboardingAuthenticationServiceProtocol {

    // MARK: - Properties

    private let sessionService: OnboardingSessionServiceProtocol
    private let simulatedDelay: TimeInterval

    // MARK: - Initialization

    init(sessionService: OnboardingSessionServiceProtocol, simulatedDelay: TimeInterval = 1.0) {
        self.sessionService = sessionService
        self.simulatedDelay = simulatedDelay
    }

    // MARK: - OnboardingAuthenticationServiceProtocol

    func authenticateWithGoogle(completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        print("[Mock Auth] Simulating Google sign-in...")

        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedDelay) {
            // Simulate successful authentication
            print("[Mock Auth] Google sign-in successful")
            completion(.success(()))
        }
    }

    func authenticateWithApple(completion: @escaping (Result<Void, AuthenticationError>) -> Void) {
        print("[Mock Auth] Simulating Apple sign-in...")

        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedDelay) {
            // Simulate successful authentication
            print("[Mock Auth] Apple sign-in successful")
            completion(.success(()))
        }
    }
}
