//
//  LoginViewModel.swift
//  KonoSummit
//
//  Created by mingshing on 2022/1/19.
//

import Foundation

enum LoginSectionCategory {

    case ThirdParty
    case Email

    var platforms: [LoginPlatform] {
        switch self {
        case .ThirdParty:
            return [.Apple]
        case .Email:
            return [.Kono(email: "", password: "")]
        }
    }
}

struct LoginViewModel {
    
    var sectionList: [LoginSectionCategory]
    var displayMode: LoginViewDisplayMode
}
