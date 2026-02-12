//
//  ProfileViewPresenter.swift
//  Soulverse
//

import Foundation
import FirebaseAuth

class ProfileViewPresenter: ProfileViewPresenterType {

    // MARK: - Properties

    weak var delegate: ProfileViewPresenterDelegate?

    private var loadedModel: ProfileViewModel {
        didSet {
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }

    private let user: UserProtocol

    // MARK: - Initialization

    init(user: UserProtocol = User.shared) {
        self.user = user
        self.loadedModel = ProfileViewModel(isLoading: true)
    }

    // MARK: - ProfileViewPresenterType

    func fetchProfile() {
        let providerID = Auth.auth().currentUser?.providerData.first?.providerID
        let authProvider: String? = {
            switch providerID {
            case "apple.com":
                return "Apple"
            case "google.com":
                return "Google"
            default:
                return providerID
            }
        }()

        loadedModel = ProfileViewModel(
            isLoading: false,
            userName: user.nickName,
            email: user.email,
            authProvider: authProvider,
            emoPetName: user.emoPetName,
            planetName: user.planetName
        )
    }

    func logout() {
        User.shared.logout()
        delegate?.didLogout()
    }

    func deleteAccount() {
        loadedModel.isLoading = true

        guard let firebaseUser = Auth.auth().currentUser else {
            loadedModel.isLoading = false
            delegate?.didFailWithError(NSError(
                domain: "ProfileViewPresenter",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"]
            ))
            return
        }

        let uid = firebaseUser.uid

        // Step 1: Delete Firestore document
        FirestoreUserService.deleteUser(uid: uid) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                DispatchQueue.main.async {
                    self.loadedModel.isLoading = false
                    self.delegate?.didFailWithError(error)
                }

            case .success:
                // Step 2: Delete Firebase Auth user
                firebaseUser.delete { [weak self] error in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        if let error = error {
                            self.loadedModel.isLoading = false
                            self.delegate?.didFailWithError(error)
                            return
                        }

                        // Step 3: Clear local data
                        User.shared.logout()
                        self.delegate?.didDeleteAccount()
                    }
                }
            }
        }
    }
}
