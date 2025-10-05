//
//  OnboardingDataServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol OnboardingDataServiceProtocol {
    func submitOnboardingData(_ data: OnboardingUserData, completion: @escaping (Result<Void, OnboardingDataError>) -> Void)
}

enum OnboardingDataError: Error {
    case networkError
    case invalidData
    case serverError(String)
    case unknown

    var localizedDescription: String {
        switch self {
        case .networkError:
            return "Network connection error"
        case .invalidData:
            return "Invalid data provided"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
