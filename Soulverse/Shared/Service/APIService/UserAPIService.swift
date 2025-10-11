//
//  UserAPIService.swift
//  Soulverse
//
//  Created by mingshing on 2021/12/8.
//
import Foundation
import Moya

let UserAPIServiceProvider = MoyaProvider<UserAPIService>()
                                                                                   
enum UserAPIService {

    case signup(account: String, password: String, platform: String)
    case login(account: String, validator: String, platform: String)
    case getProfile(userId: String)
    case updateFCMToken(token: String)
    case submitOnboardingData(OnboardingUserData)
}

extension UserAPIService: TargetType {
    var baseURL: URL {
        return URL(string: HostAppContants.serverUrl)!
    }
    
    var path: String {
        switch self {
        case .signup:
            return "users"
        case .login:
            return "users/login"
        case .getProfile:
            return "me"
        case .updateFCMToken:
            return "pushtokens"
        case .submitOnboardingData:
            return "users/onboarding"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .signup, .login, .submitOnboardingData:
            return .post
        case .getProfile:
            return .get
        case .updateFCMToken:
            return .put
        }
    }
    
    var sampleData: Data {
        return Data()
    }
    
    var task: Task {
        switch self {
        case .login(let account, let validator, let platform),
             .signup(let account, let validator, let platform):
            return .requestParameters(parameters: ["platform": platform, "account": account, "validator": validator, "service": "soulverse"], encoding: JSONEncoding.default)
        case .updateFCMToken(let token):
            return .requestParameters(parameters: ["token": token], encoding: JSONEncoding.default)
        case .submitOnboardingData(let data):
            var parameters: [String: Any] = [:]

            if let birthday = data.birthday {
                let formatter = ISO8601DateFormatter()
                parameters["birthday"] = formatter.string(from: birthday)
            }
            if let gender = data.gender {
                parameters["gender"] = gender.rawValue
            }
            if let planetName = data.planetName {
                parameters["planet_name"] = planetName
            }
            if let emoPetName = data.emoPetName {
                parameters["emopet_name"] = emoPetName
            }
            if !data.selectedTopics.isEmpty {
                parameters["topics"] = data.selectedTopics.map { $0.rawValue }
            }

            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .getProfile(_):
            return .requestPlain
        }
    }
    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
