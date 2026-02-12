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

        firebaseUser.delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.loadedModel.isLoading = false
                    self.delegate?.didFailWithError(error)
                }
                return
            }

            FirestoreUserService.deleteUser(uid: uid) { [weak self] _ in
                DispatchQueue.main.async {
                    User.shared.logout()
                    self?.delegate?.didDeleteAccount()
                }
            }
        }
    }
}
