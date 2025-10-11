//
//  GoogleUserAuthService.swift
//  Soulverse
//

import Foundation
import GoogleSignIn

class GoogleUserAuthService: NSObject, AuthService {

    var completionAction: ((AuthResult)->Void)?
    let platform: String = "google"

    func authenticate(_ completion: ((AuthResult)->Void)? = nil) {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            completion?(.UnknownError)
            return
        }

        completionAction = completion

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("[GoogleAuth] Error: \(error.localizedDescription)")
                self.completionAction?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.completionAction?(.UnknownError)
                return
            }

            // user.userID is the unique, stable user identifier
            let uniqueUserID = user.userID ?? ""
            let email = user.profile?.email ?? ""
            let fullName = user.profile?.name ?? ""

            print("[GoogleAuth] Successfully authenticated")
            print("[GoogleAuth] Unique User ID: \(uniqueUserID)")
            print("[GoogleAuth] Email: \(email)")
            print("[GoogleAuth] Full Name: \(fullName)")

            // TODO: Send to backend: uniqueUserID, idToken, email, fullName
            // UserService.login(account: uniqueUserID, validator: idToken, platform: platform)

            self.completionAction?(.AuthSuccess)
        }
    }
}
