//
//  User.swift
//

import Foundation
import UIKit
import FirebaseAuth

enum UserInfoKeys: String {
    case avatarImageURL
    case email
    case emoPetName
    case fcmToken
    case hasLoggedIn
    case hasGrantedNotification
    case hasCompletedOnboarding
    case nickname
    case nextAskingPermissionTime
    case notificationAskGapTime
    case planetName
    case userId
    case selectedTheme
    case themeMode
}

public enum NotificationAskGapTime: Int, Comparable {
    
    case Unknown = 0
    case SevenDays = 1
    case FourteenDays = 2
    case ThirtyDays = 3
    
    var second: Double {
        switch self {
        case .Unknown:
            return 0
        case .SevenDays:
            #if Dev
            return 1 * TimeConstant.miniute
            #else
            return 7 * TimeConstant.day
            #endif
        case .FourteenDays:
            #if Dev
            return 2 * TimeConstant.miniute
            #else
            return 14 * TimeConstant.day
            #endif
        case .ThirtyDays:
            #if Dev
            return 4 * TimeConstant.miniute
            #else
            return 30 * TimeConstant.day
            #endif
        }
    }
    
    public static func < (lhs: NotificationAskGapTime, rhs: NotificationAskGapTime) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


protocol UserProtocol {
    var userId: String? { get set }
    var email: String? { get set }
    var nickName: String? { get set }
    var emoPetName: String? { get set }
    var planetName: String? { get set }
    var isLoggedin: Bool { get }
    var hasGrantedNotification: Bool { get }
    var selectedTheme: String? { get set }
    var themeMode: ThemeMode { get set }

    func hasShownRequestPermissionAlert()
    func showCustomizeRequestPermissionAlert() -> Bool
}

class User: UserProtocol {
    
    public static let shared = User()
    
    // MARK: - Initializers
    private let defaults: UserDefaults
    
    init(defaults: UserDefaults = UserDefaults.standard) {
        self.defaults = defaults
    }
    
    // MARK: - Properties
    var userId: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.userId.rawValue)
            return value
        }
        set(userId) {
            guard userId != nil else {
                defaults.removeObject(forKey: UserInfoKeys.userId.rawValue)
                return
            }
            defaults.set(userId, forKey: UserInfoKeys.userId.rawValue)
        }
    }
    
    var email: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.email.rawValue)
            return value
        }
        set(newEmail) {
            guard let email = newEmail else {
                defaults.removeObject(forKey: UserInfoKeys.email.rawValue)
                return
            }
            defaults.set(email, forKey: UserInfoKeys.email.rawValue)
        }
    }
    
    var nickName: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.nickname.rawValue)
            return value
        }
        set(newNickname) {
            guard let nickname = newNickname else {
                defaults.removeObject(forKey: UserInfoKeys.nickname.rawValue)
                return
            }
            defaults.set(nickname, forKey: UserInfoKeys.nickname.rawValue)
        }
    }

    var emoPetName: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.emoPetName.rawValue)
            return value
        }
        set(newEmoPetName) {
            guard let emoPetName = newEmoPetName else {
                defaults.removeObject(forKey: UserInfoKeys.emoPetName.rawValue)
                return
            }
            defaults.set(emoPetName, forKey: UserInfoKeys.emoPetName.rawValue)
        }
    }

    var planetName: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.planetName.rawValue)
            return value
        }
        set(newPlanetName) {
            guard let planetName = newPlanetName else {
                defaults.removeObject(forKey: UserInfoKeys.planetName.rawValue)
                return
            }
            defaults.set(planetName, forKey: UserInfoKeys.planetName.rawValue)
        }
    }

    var avatarImageURL: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.avatarImageURL.rawValue)
            return value
        }
        set(newImageURL) {
            guard let imageURL = newImageURL else {
                defaults.removeObject(forKey: UserInfoKeys.avatarImageURL.rawValue)
                return
            }
            defaults.set(imageURL, forKey: UserInfoKeys.avatarImageURL.rawValue)
        }
    }
    
    var isLoggedin: Bool {
        get {
            let res = defaults.bool(forKey: UserInfoKeys.hasLoggedIn.rawValue)
            return res
        }
        set(newValue) {
            defaults.set(newValue, forKey: UserInfoKeys.hasLoggedIn.rawValue)
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notification.UserIdentityChange), object: nil, userInfo: nil)
            updateFCMToken()
        }
    }
    
    
    public var hasGrantedNotification: Bool {
        get {
            let res = defaults.bool(forKey: UserInfoKeys.hasGrantedNotification.rawValue)
            return res
        }
        set(newValue) {
            defaults.set(newValue, forKey: UserInfoKeys.hasGrantedNotification.rawValue)
        }
    }

    public var hasCompletedOnboarding: Bool {
        get {
            let res = defaults.bool(forKey: UserInfoKeys.hasCompletedOnboarding.rawValue)
            return res
        }
        set(newValue) {
            defaults.set(newValue, forKey: UserInfoKeys.hasCompletedOnboarding.rawValue)
        }
    }
    
    var nextAskingPermissionTime: TimeInterval? {
        get {
            let value = defaults.double(forKey: UserInfoKeys.nextAskingPermissionTime.rawValue)
            return value
        }
        set(newAskingTime) {
            guard let _ = newAskingTime else {
                defaults.removeObject(forKey: UserInfoKeys.nextAskingPermissionTime.rawValue)
                return
            }
            defaults.set(newAskingTime, forKey: UserInfoKeys.nextAskingPermissionTime.rawValue)
        }
    }
    
    var notificationAskGapTime: NotificationAskGapTime {
        get {
            let res = NotificationAskGapTime(rawValue: defaults.integer(forKey: UserInfoKeys.notificationAskGapTime.rawValue)) ?? .Unknown
            return res
        }
        set(newValue) {
            defaults.set(newValue.rawValue, forKey: UserInfoKeys.notificationAskGapTime.rawValue)
        }
    }
    
    var fcmToken: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.fcmToken.rawValue)
            return value
        }
        set(newToken) {
            guard let token = newToken else {
                defaults.removeObject(forKey: UserInfoKeys.fcmToken.rawValue)
                return
            }
            defaults.set(token, forKey: UserInfoKeys.fcmToken.rawValue)
            updateFCMToken()
        }
    }

    var selectedTheme: String? {
        get {
            let value = defaults.string(forKey: UserInfoKeys.selectedTheme.rawValue)
            return value
        }
        set(newTheme) {
            guard let theme = newTheme else {
                defaults.removeObject(forKey: UserInfoKeys.selectedTheme.rawValue)
                return
            }
            defaults.set(theme, forKey: UserInfoKeys.selectedTheme.rawValue)
        }
    }

    var themeMode: ThemeMode {
        get {
            let modeRaw = defaults.integer(forKey: UserInfoKeys.themeMode.rawValue)
            return modeRaw == 1 ? .automatic : .manual
        }
        set(newMode) {
            defaults.set(newMode == .automatic ? 1 : 0, forKey: UserInfoKeys.themeMode.rawValue)
        }
    }

    func logout() {
        try? Auth.auth().signOut()
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        clearUserProperty()
    }

    #if DEBUG
    /// Debug helper to reset all user data including onboarding
    /// Use this to test the onboarding flow again
    public func resetAllUserData() {
        logout()
        // Also clear all UserDefaults keys
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        print("[Debug] All user data cleared - onboarding will show on next launch")
    }
    #endif
    
    private func clearUserProperty() {
        // we won't clear the notification related userdefault
        userId = nil
        email = nil
        isLoggedin = false
        nickName = nil
        emoPetName = nil
        planetName = nil
        avatarImageURL = nil
        hasCompletedOnboarding = false
    }
    
    private func updateFCMToken() {
        guard let token = fcmToken, let uid = userId, isLoggedin else { return }
        FirestoreUserService.updateFCMToken(uid: uid, token: token)
    }
    
}


// MARK - handle the notification pop up showing logic

extension User {
    
    func hasShownRequestPermissionAlert() {
        
        var newGapTime: NotificationAskGapTime = .ThirtyDays
        if self.notificationAskGapTime < NotificationAskGapTime.ThirtyDays {
            newGapTime = NotificationAskGapTime(rawValue: notificationAskGapTime.rawValue + 1) ?? .ThirtyDays
        }
        nextAskingPermissionTime = Date().timeIntervalSince1970 + newGapTime.second
        notificationAskGapTime = newGapTime
    }
    
    func showCustomizeRequestPermissionAlert() -> Bool {
        
        if let nextAskingPermissionTime = nextAskingPermissionTime,
              nextAskingPermissionTime > Date().timeIntervalSince1970 {
            return false
        }
        let cancelAction = SummitAlertAction(
            title: NSLocalizedString("notification_permission_alert_action_later", comment: ""),
            style: .cancel,
            isPreferredAction: false,
            handler: nil)
        
        let okAction = SummitAlertAction(
            title: NSLocalizedString("notification_permission_alert_action_ok", comment: ""),
            style: .default,
            isPreferredAction: true) {
                let url = URL(string: UIApplication.openSettingsURLString)!
                UIApplication.shared.open(url)
            }
        DispatchQueue.main.async {
            SummitAlertView.shared.show(
                title: NSLocalizedString("notification_permission_alert_title", comment: ""),
                message: NSLocalizedString("notification_permission_alert_description", comment: ""),
                actions: [cancelAction, okAction]
            )
        }
        return true
    }
}
