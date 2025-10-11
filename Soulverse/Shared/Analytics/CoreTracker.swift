//
//  CoreTracker.swift
//  KonoSummit
//
//  Created by mingshing on 2021/12/21.
//

import Foundation

enum AppLocation: String {
    case AudioPlayer
    case Article
    case Account
    case Home
    case Login
    case Notification
    case Voting
    case VotingRecommend
    case SubscriptionPromote
    case Membership
    case PurchaseRecord
    case BackgroundProcess
}

struct TrackingUserProperty {
    static let utmMedium = "utm_medium"
    static let utmSource = "utm_source"
    static let utmCampaign = "utm_campaign"
    static let email = "email"
    static let accountType = "account type"
    static let paymentType = "payment type"
    static let couponCampaign = "campaign name"
}

protocol CoreTracker: AnyObject {
    
    var services: [TrackingServiceType] { get }
    func track(_ event: TrackingEventType)
    func updateUserAcquireInfo()
    func setupUserProperty(_ info: [String : Any])
}

extension CoreTracker {
    
    func track(_ event: TrackingEventType) {
        services.forEach { provider in
            provider.track(event)
        }
    }
}
