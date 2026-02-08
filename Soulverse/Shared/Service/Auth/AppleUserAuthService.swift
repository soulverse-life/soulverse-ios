//
//  AppleUserAuthService.swift
//  Soulverse
//

import Foundation
import AuthenticationServices
import FirebaseAuth

class AppleUserAuthService: NSObject, AuthService {

    var completionAction: ((AuthResult)->Void)?
    let platform: String = "apple"
    private weak var presentingViewController: UIViewController?

    func authenticate(_ completion: ((AuthResult)->Void)? = nil) {
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
        if let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

            guard let token = appleCredential.identityToken,
                  let tokenString = String(data: token, encoding: .utf8) else {
                print("[AppleAuth] Error: No identity token received")
                self.completionAction?(.UnknownError)
                return
            }

            print("[AppleAuth] Successfully authenticated with Apple")

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: tokenString,
                rawNonce: nil,
                fullName: appleCredential.fullName
            )

            Auth.auth().signIn(with: firebaseCredential) { [weak self] authResult, error in
                guard let self = self else { return }

                if let error = error {
                    print("[AppleAuth] Firebase sign-in error: \(error.localizedDescription)")
                    self.completionAction?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self.completionAction?(.UnknownError)
                    return
                }

                let uid = firebaseUser.uid
                let email = firebaseUser.email ?? appleCredential.email ?? ""
                let displayName = firebaseUser.displayName
                    ?? [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")

                print("[AppleAuth] Firebase UID: \(uid)")

                FirestoreUserService.createOrUpdateUser(
                    uid: uid,
                    email: email,
                    displayName: displayName,
                    platform: self.platform
                ) { result in
                    switch result {
                    case .success(let isNewUser):
                        User.shared.userId = uid
                        User.shared.email = email
                        User.shared.nickName = displayName
                        User.shared.isLoggedin = true
                        self.completionAction?(.AuthSuccess(isNewUser: isNewUser))
                    case .failure(let error):
                        print("[AppleAuth] Firestore error: \(error.localizedDescription)")
                        self.completionAction?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let nsError = error as NSError
        print("[AppleAuth] Error code: \(nsError.code), domain: \(nsError.domain)")

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
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
