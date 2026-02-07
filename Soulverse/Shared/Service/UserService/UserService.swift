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


class UserService {
    
    public static func login(account: String, validator: String, platform: String, completion: @escaping(Result<SummitUserModel, UserServiceError>) -> ()) {
        
        UserAPIServiceProvider.request(.login(account: account, validator: validator, platform: platform)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    var result = try JSONDecoder().decode(SummitUserModel.self, from: filteredResponse.data)
                    
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: response.response?.allHeaderFields as! [String: String], for: (response.response?.url)!)
                    if let sessionToken = cookies.first(where: { cookie in
                        cookie.name == HostAppContants.sessionKey
                    }) {
                        result.sessionToken = sessionToken.value
                    }
                    
                    completion(.success(result))
                } catch _ {
                   
                    do {
                        let json = try JSONSerialization.jsonObject(with: response.data, options: .mutableContainers)
                        let dic = json as! Dictionary<String, Any>
                        if dic.keys.contains("code") {
                            let error = UserServiceError(rawValue: dic["code"] as! String)
                            completion(.failure(error ?? UserServiceError.InvalidData))
                        } else {
                            completion(.failure(UserServiceError.InvalidData))
                        }
                        
                    } catch _ {
                        completion(.failure(UserServiceError.InvalidData))
                    }
                }
            case .failure(_):
                completion(.failure(UserServiceError.Network))
            }
        }
    }
    
    public static func signup(account: String, password: String, platform: String, completion: @escaping(Result<SummitUserModel, UserServiceError>) -> ()) {
        
        UserAPIServiceProvider.request(.signup(account: account, password: password, platform: platform)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let result = try JSONDecoder().decode(SummitUserModel.self, from: filteredResponse.data)
                    
                    
                    completion(.success(result))
                } catch _ {
                   
                    do {
                        let json = try JSONSerialization.jsonObject(with: response.data, options: .mutableContainers)
                        let dic = json as! Dictionary<String, Any>
                        if dic.keys.contains("code") {
                            let error = UserServiceError(rawValue: dic["code"] as! String)
                            completion(.failure(error ?? UserServiceError.InvalidData))
                        } else {
                            completion(.failure(UserServiceError.InvalidData))
                        }
                        
                    } catch _ {
                        completion(.failure(UserServiceError.InvalidData))
                    }
                }
            case .failure(_):
                completion(.failure(UserServiceError.Network))
            }
        }
    }
    
    
    public static func updateUserProfile(userId: String, completion: @escaping(Result<SummitUserModel, ApiError>) -> ()) {
        
        UserAPIServiceProvider.request(.getProfile(userId: userId)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let result = try JSONDecoder().decode(SummitUserModel.self, from: filteredResponse.data)
                    
                    completion(.success(result))
                } catch _ {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    
                    switch response.statusCode {
                    case 401:
                        completion(.failure(ApiError.UnAuthorize))
                    default:
                        completion(.failure(ApiError.ServerError(reason: errorResponse)))
                    }
                    
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion(.failure(ApiError.Network))
            }
        }
    }
    
    public static func updateFCMToken(token: String, completion: @escaping(Result<String, ApiError>) -> ()) {
    
        UserAPIServiceProvider.request(.updateFCMToken(token: token)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    let result = String(decoding: filteredResponse.data, as: UTF8.self)
                    
                    completion(.success(result))
                } catch _ {
                    
                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")
                    completion(.failure(ApiError.ServerError(reason: errorResponse)))
                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion(.failure(ApiError.Network))
            }
        }
    }
    

    public static func submitOnboardingData(_ data: OnboardingUserData, completion: @escaping(Result<Void, ApiError>) -> ()) {

        UserAPIServiceProvider.request(.submitOnboardingData(data)) { result in
            switch result {
            case let .success(response):
                do {
                    let filteredResponse = try response.filterSuccessfulStatusAndRedirectCodes()
                    _ = String(decoding: filteredResponse.data, as: UTF8.self)

                    // Save onboarding data to User singleton for local access
                    User.shared.hasCompletedOnboarding = true
                    User.shared.emoPetName = data.emoPetName
                    User.shared.planetName = data.planetName

                    completion(.success(()))
                } catch _ {

                    let errorResponse = String(decoding: response.data, as: UTF8.self)
                    print("[API Error: \(#function)] \(errorResponse)")

                    switch response.statusCode {
                    case 401:
                        completion(.failure(ApiError.UnAuthorize))
                    default:
                        completion(.failure(ApiError.ServerError(reason: errorResponse)))
                    }

                }
            case .failure(let error):
                print(error.errorDescription ?? "")
                completion(.failure(ApiError.Network))
            }
        }
    }
}
