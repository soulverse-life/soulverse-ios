//
//  ProfileViewPresenterType.swift
//  Soulverse
//

import Foundation

protocol ProfileViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: ProfileViewModel)
    func didLogout()
    func didDeleteAccount()
    func didFailWithError(_ error: Error)
}

protocol ProfileViewPresenterType {
    func fetchProfile()
    func logout()
    func deleteAccount()
}
