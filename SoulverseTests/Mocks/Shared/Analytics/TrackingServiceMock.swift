//
//  TrackingServiceMock.swift
//
//

import Foundation
@testable import Soulverse

final class TrackingServiceMock: TrackingServiceType {

    var trackedEvent: TrackingEventType?
    var trackedUserId: String?
    var trackedUserEmail: String?
    var saveUserPropertyValue: String? = "testUserProperty"

    func clearUserProperties() {
        saveUserPropertyValue = nil
    }

    func setupUserDefaultProperties(_ user: UserProtocol) {
        trackedUserId = user.userId
        trackedUserEmail = user.email
    }

    func setupUserProperty(userId: String, info: [String: Any]) {}

    func track(_ event: TrackingEventType) {
        trackedEvent = event
    }

}
