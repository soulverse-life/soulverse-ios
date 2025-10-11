//
//  SummitTracker.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/21.
//

import Foundation

class SummitTracker: CoreTracker {
    
    public static let shared = SummitTracker()
    let operatingUser: UserProtocol
    var services: [TrackingServiceType]

    init(
        _ user: UserProtocol = User.shared,
        services: [TrackingServiceType] = [FirebaseTrackingService()]
    ) {
        self.services = services
        self.operatingUser = user
        
        updateUserProperies()
        NotificationCenter.default.addObserver(self, selector: #selector(userIdentityChanged), name: NSNotification.Name(rawValue: Notification.UserIdentityChange), object: nil)
    }
    
    func updateUserAcquireInfo() {}
    
    func setupUserProperty(_ info: [String : Any]) {
        services.forEach { provider in
            provider.setupUserProperty(info)
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
