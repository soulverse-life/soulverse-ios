//
//  PosthogTrackingService.swift
//  Soulverse
//
//  Created by Claude on 2026/1/17.
//

import Foundation
import PostHog

class PosthogTrackingService: TrackingServiceType {

    func setupUserDefaultProperties(_ user: UserProtocol) {
        guard let userId = user.userId else { return }
        
        PostHogSDK.shared.identify(
            userId,
            userProperties: [
                TrackingUserProperty.email: user.email ?? ""
            ]
        )
    }

    func clearUserProperties() {
        PostHogSDK.shared.reset()
    }

    func setupUserProperty(userId: String, info: [String: Any]) {
        let normalizedProperties = normalizeProperties(info)
        PostHogSDK.shared.identify(
            userId,
            userProperties: normalizeProperties(info)
        )
    }

    func track(_ event: TrackingEventType) {
        let eventName = normalizeEventName(event.name)
        let eventProperties = normalizeProperties(event.metadata)
        PostHogSDK.shared.capture(eventName, properties: eventProperties)
    }

    // MARK: - Private Helpers

    private func normalizeEventName(_ name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "_")
    }

    private func normalizeProperties(_ properties: [String: Any]) -> [String: Any] {
        var normalized: [String: Any] = [:]
        for (key, value) in properties {
            let normalizedKey = key.replacingOccurrences(of: " ", with: "_").lowercased()
            normalized[normalizedKey] = value
        }
        return normalized
    }
}
