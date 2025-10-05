//
//  MockOnboardingDataService.swift
//  Soulverse
//

import Foundation

final class MockOnboardingDataService: OnboardingDataServiceProtocol {

    // MARK: - Properties

    private let simulatedDelay: TimeInterval

    // MARK: - Initialization

    init(simulatedDelay: TimeInterval = 1.5) {
        self.simulatedDelay = simulatedDelay
    }

    // MARK: - OnboardingDataServiceProtocol

    func submitOnboardingData(_ data: OnboardingUserData, completion: @escaping (Result<Void, OnboardingDataError>) -> Void) {
        print("[Mock API] Submitting onboarding data...")
        logOnboardingData(data)

        DispatchQueue.main.asyncAfter(deadline: .now() + simulatedDelay) {
            // Simulate successful submission
            print("[Mock API] Onboarding data submitted successfully")
            completion(.success(()))
        }
    }

    // MARK: - Private Helpers

    private func logOnboardingData(_ data: OnboardingUserData) {
        print("  ├─ Birthday: \(data.birthday?.description ?? "N/A")")
        print("  ├─ Gender: \(data.gender?.rawValue ?? "N/A")")
        print("  ├─ Planet Name: \(data.planetName ?? "N/A")")
        print("  ├─ EmoPet Name: \(data.emoPetName ?? "N/A")")
        print("  └─ Topics: \(data.selectedTopics.map { $0.rawValue }.joined(separator: ", "))")
    }
}
