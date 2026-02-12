//
//  GoogleUserAuthService.swift
//  Soulverse
//

import Foundation
import GoogleSignIn
import FirebaseAuth

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
                let nsError = error as NSError
                if nsError.code == GIDSignInError.canceled.rawValue {
                    self.completionAction?(.UserCancel)
                } else {
                    print("[GoogleAuth] Error: \(error.localizedDescription)")
                    self.completionAction?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                self.completionAction?(.UnknownError)
                return
            }

            let email = user.profile?.email ?? ""
            let fullName = user.profile?.name ?? ""

            print("[GoogleAuth] Successfully authenticated with Google")

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }

                if let error = error {
                    print("[GoogleAuth] Firebase sign-in error: \(error.localizedDescription)")
                    self.completionAction?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    self.completionAction?(.UnknownError)
                    return
                }

                let uid = firebaseUser.uid

                print("[GoogleAuth] Firebase UID: \(uid)")

                FirestoreUserService.createOrUpdateUser(
                    uid: uid,
                    email: email,
                    displayName: fullName,
                    platform: self.platform
                ) { result in
                    switch result {
                    case .success(let isNewUser):
                        User.shared.userId = uid
                        User.shared.email = email
                        User.shared.nickName = fullName
                        User.shared.isLoggedin = true
                        self.completionAction?(.AuthSuccess(isNewUser: isNewUser))
                    case .failure(let error):
                        print("[GoogleAuth] Firestore error: \(error.localizedDescription)")
                        self.completionAction?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                    }
                }
            }
        }
    }
}
