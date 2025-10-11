//
//  TrackingServiceType.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/21.
//

import Foundation

protocol TrackingServiceType {
    
    func track(_ event: TrackingEventType)
    func clearUserProperties()
    func setupUserDefaultProperties(_ user: UserProtocol)
    func setupUserProperty(_ info: [String: Any])

}

extension TrackingServiceType {
    func clearUserProperties() {}
    func setupUserDefaultProperties(_ user: User) {}
    func setupUserProperty(_ info: [String: Any]) {}
}
