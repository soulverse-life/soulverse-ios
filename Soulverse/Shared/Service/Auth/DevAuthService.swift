//
//  DevAuthService.swift
//  Soulverse
//

#if DEBUG

import Foundation
import FirebaseAuth

class DevAuthService: AuthService {

    private let email = "test@soulverse.life"
    private let password = "test1234"
    private let platform = "dev"

    func authenticate(_ completion: ((AuthResult) -> Void)? = nil) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                print("[DevAuth] Firebase sign-in error: \(error.localizedDescription)")
                completion?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                return
            }

            guard let firebaseUser = authResult?.user else {
                completion?(.UnknownError)
                return
            }

            let uid = firebaseUser.uid
            let userEmail = firebaseUser.email ?? self.email

            print("[DevAuth] Firebase UID: \(uid)")

            FirestoreUserService.createOrUpdateUser(
                uid: uid,
                email: userEmail,
                displayName: "Dev User",
                platform: self.platform
            ) { result in
                switch result {
                case .success(let isNewUser):
                    User.shared.userId = uid
                    User.shared.email = userEmail
                    User.shared.nickName = "Dev User"
                    User.shared.isLoggedin = true
                    completion?(.AuthSuccess(isNewUser: isNewUser))
                case .failure(let error):
                    print("[DevAuth] Firestore error: \(error.localizedDescription)")
                    completion?(.ThirdPartyServiceError(errorMsg: error.localizedDescription))
                }
            }
        }
    }
}

#endif
