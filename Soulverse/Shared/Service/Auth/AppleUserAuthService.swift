//
//  AppleUserAuthService.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/6.
//

import Foundation
import AuthenticationServices

class AppleUserAuthService: NSObject, AuthService {

    var completionAction: ((AuthResult)->Void)?
    let platform: String = "apple"
    private weak var presentingViewController: UIViewController?

    func authenticate(_ completion: ((AuthResult)->Void)? = nil) {
        // Get the presenting view controller
        guard let viewController = UIApplication.shared.windows.first?.rootViewController else {
            print("[AppleAuth] Error: No root view controller found")
            completion?(.UnknownError)
            return
        }

        self.presentingViewController = viewController

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        completionAction = completion
    }
}

extension AppleUserAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {

            if let token = credential.identityToken {
                let tokenString = String(data: token, encoding: .utf8) ?? ""

                // credential.user is the unique, stable user identifier
                let uniqueUserID = credential.user

                print("[AppleAuth] Successfully authenticated")
                print("[AppleAuth] Unique User ID: \(uniqueUserID)")
                print("[AppleAuth] Email: \(credential.email ?? "N/A")")
                print("[AppleAuth] Full Name: \(credential.fullName?.givenName ?? "N/A") \(credential.fullName?.familyName ?? "N/A")")

                // TODO: Send to backend: uniqueUserID, tokenString, email, fullName
                // UserService.login(account: uniqueUserID, validator: tokenString, platform: platform)

                self.completionAction?(.AuthSuccess)
            } else {
                print("[AppleAuth] Error: No identity token received")
                self.completionAction?(.UnknownError)
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        print("[AppleAuth] Error code: \(nsError.code), domain: \(nsError.domain)")
        print("[AppleAuth] Error description: \(error.localizedDescription)")

        // Check if user cancelled
        if nsError.code == ASAuthorizationError.canceled.rawValue {
            completionAction?(.UserCancel)
        } else {
            completionAction?(.ThirdPartyServiceError(errorMsg: "Error \(nsError.code): \(error.localizedDescription)"))
        }
    }
}

extension AppleUserAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = presentingViewController?.view.window {
            return window
        }

        // Fallback if view controller is nil
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
