//
//  UserService.swift
//
import Foundation

enum ApiError: Error, Equatable {
    case UnAuthorize
    case Network
    case ServerError(reason: String)
    case FailedAction(reason: String)

    var description: String {
        switch self {
        case .UnAuthorize:
            return "please login"
        case .Network:
            return NSLocalizedString("message_error_network", comment: "")
        case .ServerError(let reason), .FailedAction(let reason):
            return reason
        }
    }

}


enum UserServiceError: String, Swift.Error {

    case ParameterMissing = "PARAMETER_MISSING"
    case InvalidData = "INVALID_DATA"
    case AppleAuthError = "APPLE_AUTH_ERROR"
    case Network = "NETWORK"


    var reason: AuthResult {
        switch self {
        case .InvalidData, .ParameterMissing:
            return .ServerError
        case .AppleAuthError:
            return .ThirdPartyServiceError(errorMsg: nil)
        case .Network:
            return .NetworkError
        }
    }

}


/// Legacy REST API user service — kept for compilation but no longer functional.
/// All active user operations now go through `FirestoreUserService`.
class UserService {

    public static func login(account: String, validator: String, platform: String, completion: @escaping(Result<UserModel, UserServiceError>) -> ()) {
        completion(.failure(.Network))
    }

    public static func signup(account: String, password: String, platform: String, completion: @escaping(Result<UserModel, UserServiceError>) -> ()) {
        completion(.failure(.Network))
    }

    public static func updateUserProfile(userId: String, completion: @escaping(Result<UserModel, ApiError>) -> ()) {
        completion(.failure(.Network))
    }

    public static func updateFCMToken(token: String, completion: @escaping(Result<String, ApiError>) -> ()) {
        completion(.failure(.Network))
    }

    public static func submitOnboardingData(_ data: OnboardingUserData, completion: @escaping(Result<Void, ApiError>) -> ()) {
        completion(.failure(.Network))
    }
}
