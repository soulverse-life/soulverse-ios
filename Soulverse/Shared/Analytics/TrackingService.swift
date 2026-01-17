//
//  TrackingService.swift
//  Soulverse
//
//  Created by mingshing on 2021/12/21.
//

import Foundation

class TrackingService: CoreTracker {

    public static let shared = TrackingService()
    let operatingUser: UserProtocol
    var services: [TrackingServiceType]

    init(
        _ user: UserProtocol = User.shared,
        services: [TrackingServiceType] = [FirebaseTrackingService(), PosthogTrackingService()]
    ) {
        self.services = services
        self.operatingUser = user

        updateUserProperies()
        NotificationCenter.default.addObserver(self, selector: #selector(userIdentityChanged), name: NSNotification.Name(rawValue: Notification.UserIdentityChange), object: nil)
    }

    func updateUserAcquireInfo() {}

    func setupUserProperty(userId: String, info: [String: Any]) {
        services.forEach { provider in
            provider.setupUserProperty(userId: userId, info: info)
        }
    }

    @objc private func userIdentityChanged() {
        updateUserProperies()
    }

    private func updateUserProperies() {
        if operatingUser.isLoggedin {
            services.forEach { provider in
                provider.setupUserDefaultProperties(operatingUser)
            }
        } else {
            services.forEach { provider in
                provider.clearUserProperties()
            }
        }
    }

}
