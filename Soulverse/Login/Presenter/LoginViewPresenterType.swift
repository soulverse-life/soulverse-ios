//
//  LoginViewPresenterType.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/6.
//

import Foundation

enum LoginPlatform {

    case Apple
    case Kono(email: String, password: String)

    var authService: AuthService {
        switch self {
        case .Apple:
            return AppleUserAuthService()
        case .Kono(let email, let password):
            return KonoUserAuthService(email: email, password: password)
        }
    }

    var name: String {
        switch self {
        case .Apple:
            return "apple"
        case .Kono:
            return "email"
        }
    }
}

enum LoginViewDisplayMode {
    case Register
    case Login
    
    var name: String {
        switch self {
        case .Register:
            return "Register"
        case .Login:
            return "Login"
        }
    }
}

enum LoginViewInputCheckResult {
    case Valid
    case EmailEmpty
    case PasswordEmpty
    case ConfirmPasswordEmpty
    case InvalidEmail
    case DifferentPassword
}

protocol LoginViewPresenterDelegate: AnyObject {
    
    //func updateView(_ viewModel: LoginViewModel)
    func startAuthProcess()
    func didChangeDisplayMode(_ viewModel: LoginViewModel)
    func didFinishedAuthProcess(_ result: AuthResult)
    func openPolicy()
    func openForgetPassword()
    func dismissView()

}


protocol LoginViewPresenterType {
    
    var delegate: LoginViewPresenterDelegate? {get set}
    var viewModel: LoginViewModel {get set}
    
    func numberOfSections() -> Int
    func numberOfItems(of section: Int) -> Int
    func loginPlatformForIndex(section: Int, row: Int) -> LoginPlatform?
    func didTapLoginAction(platform: LoginPlatform)
    
    func didTapBackButton()
    func didTapSkipButton()
    func didTapSwitchButton()
    func didTapUserPolicy()
    func didTapForgetPassword()
}
