//
//  OnboardingAuthenticationServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol OnboardingAuthenticationServiceProtocol {
    func authenticateWithGoogle(completion: @escaping (Result<Void, AuthenticationError>) -> Void)
    func authenticateWithApple(completion: @escaping (Result<Void, AuthenticationError>) -> Void)
}

enum AuthenticationError: Error {
    case userCancelled
    case networkError
    case invalidCredentials
    case serverError(String)
    case unknown

    var localizedDescription: String {
        switch self {
        case .userCancelled:
            return "User cancelled authentication"
        case .networkError:
            return "Network connection error"
        case .invalidCredentials:
            return "Invalid credentials"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}
