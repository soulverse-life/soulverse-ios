//
//  ProfileViewModel.swift
//  Soulverse
//

import Foundation

struct ProfileViewModel {

    // MARK: - State

    var isLoading: Bool

    // MARK: - User Data

    var userName: String?
    var email: String?
    var authProvider: String?
    var emoPetName: String?
    var planetName: String?

    // MARK: - Initialization

    init(
        isLoading: Bool = false,
        userName: String? = nil,
        email: String? = nil,
        authProvider: String? = nil,
        emoPetName: String? = nil,
        planetName: String? = nil
    ) {
        self.isLoading = isLoading
        self.userName = userName
        self.email = email
        self.authProvider = authProvider
        self.emoPetName = emoPetName
        self.planetName = planetName
    }
}
