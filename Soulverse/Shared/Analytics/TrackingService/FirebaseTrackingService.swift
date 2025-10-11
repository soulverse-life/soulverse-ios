//
//  FirebaseTrackingService.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/27.
//

import Foundation
import Firebase

class FirebaseTrackingService: TrackingServiceType {
    
    let firebaseEventsMapping: [String: String]
    
    init() {
        firebaseEventsMapping = ["log in": AnalyticsEventLogin, "sign up": AnalyticsEventSignUp]
    }
    
    func setupUserDefaultProperties(_ user: UserProtocol) {
        Analytics.setUserID(user.userId)
        Analytics.setUserProperty(user.email, forName: TrackingUserProperty.email)
    }
    
    func track(_ event: TrackingEventType) {
        let eventParameters = getValidFirebaseParameters(event.metadata)
        
        if isSpecialEvent(event) {
            guard let mappingEventName = firebaseEventsMapping[event.name] else { return }
            Analytics.logEvent(mappingEventName, parameters: eventParameters)
        } else {
            
            //Firebase use its own event name convention
            let eventName = event.name.replacingOccurrences(of: " ", with: "_")

            Analytics.logEvent(eventName, parameters: eventParameters)
        }
    }
    
    private func getValidFirebaseParameters(_ metadata: [String: Any]) -> [String: Any] {
        var eventParameters: [String: Any] = Dictionary()
        
        for (key, value) in metadata {
            let newKey = key.replacingOccurrences(of: " ", with: "_").lowercased()
            eventParameters[newKey] = value
        }
        return eventParameters
    }
    
    private func isSpecialEvent(_ event: TrackingEventType) -> Bool {
        
        return firebaseEventsMapping.keys.contains(event.name)
    }
}
