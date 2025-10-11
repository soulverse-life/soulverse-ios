//
//  AuthService.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/6.
//

import Foundation

/// Result of authentication operation
enum AuthResult {

    case AuthSuccess
    case ThirdPartyServiceError(errorMsg: String? = nil)
    case ServerError
    case NetworkError
    case UserCancel
    case UnknownError

    var description: String {
        switch self {
        case .AuthSuccess:
            return "authentication successful"
        case .ThirdPartyServiceError(let msg):
            return "third party service error: \(msg ?? "unknown")"
        case .ServerError:
            return "server error"
        case .NetworkError:
            return "network error"
        case .UserCancel:
            return "user cancelled authentication"
        case .UnknownError:
            return "unknown error"
        }
    }
}

/// Protocol for authentication services
/// Currently supports 3rd party authentication (Google, Apple)
///
/// Note: For email/password authentication, create a separate
/// EmailAuthService class that implements this protocol
protocol AuthService {

    /// Authenticate user with the provider
    /// For 3rd party providers (Google, Apple), this handles both signup and login
    /// - Parameter completion: Callback with authentication result
    func authenticate(_ completion: ((AuthResult)->Void)?)
}
