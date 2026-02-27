//
//  UserMock.swift
//

import Foundation
@testable import Soulverse

final class UserMock: UserProtocol {
    var userId: String? = "123456"
    var email: String? = "test@gmail.com"
    var nickName: String? = "TestUser"
    var emoPetName: String? = nil
    var planetName: String? = nil
    var isLoggedin: Bool = true
    var hasGrantedNotification: Bool = true
    var selectedTheme: String? = nil
    var themeMode: ThemeMode = .manual

    func hasShownRequestPermissionAlert() {}
    func showCustomizeRequestPermissionAlert() -> Bool { return false }
}
