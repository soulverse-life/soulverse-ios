//
//  ProfileViewPresenterDelegateMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class ProfileViewPresenterDelegateMock: ProfileViewPresenterDelegate {
    var updatedViewModel: ProfileViewModel?
    var didLogoutCalled = false
    var didDeleteAccountCalled = false
    var failError: Error?

    func didUpdate(viewModel: ProfileViewModel) {
        updatedViewModel = viewModel
    }

    func didLogout() {
        didLogoutCalled = true
    }

    func didDeleteAccount() {
        didDeleteAccountCalled = true
    }

    func didFailWithError(_ error: Error) {
        failError = error
    }
}
