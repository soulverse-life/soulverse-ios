//
//  Constants.swift
//
//  Created by mingshing on 2021/8/16.
//

import Foundation
import UIKit

struct AuthenticationKeyConstants {
    
    static let email: String = "email"
    static let password: String = "password"
}

struct UserDefaultKeys {
    static let uuid = "uuid"
}

struct RemoteConfigKeys {
    static let minimumSupportVersion = "minimum_version"
}

struct ViewComponentConstants {
    static let miniBarHeight: CGFloat = 76.0
    static let navigationBarHeight: CGFloat = 56.0
    static let actionButtonHeight: CGFloat = 48.0
    static let smallActionButtonHeight: CGFloat = 20.0
    
    
    /// Image height/width for Large NavBar state
    static let ImageSizeForLargeState: CGFloat = 40
    /// Margin from right anchor of safe area to right anchor of Image
    static let ImageRightMargin: CGFloat = 20
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Large NavBar state
    static let ImageBottomMarginForLargeState: CGFloat = 12
    /// Margin from bottom anchor of NavBar to bottom anchor of Image for Small NavBar state
    static let ImageBottomMarginForSmallState: CGFloat = 8
    /// Image height/width for Small NavBar state
    static let ImageSizeForSmallState: CGFloat = 28
    /// Height of NavBar for Small state. Usually it's just 44
    static let NavBarHeightSmallState: CGFloat = 44
    /// Height of NavBar for Large state. Usually it's just 96.5 but if you have a custom font for the title, please make sure to edit this value since it changes the height for Large state of NavBar
    static let NavBarHeightLargeState: CGFloat = 96.5
}

struct LocaleConstants {
    static let defaultLanguage = "zh-TW"
}

struct HostAppContants {
    
    
    static let latestCategoryType = "latest"
    static let upcomingCategoryType = "upcoming"
    static let continuePlayCategoryType = "continuePlay"
    static let ctaCategoryType = "cta"
    static let folderCategoryType = "category"
    
    static let schemaVersion: UInt64 = 5
    
    static let serviceName = "com.thekono.soulverse"
    
    static let privacyUrl = "https://soulverse.thekono.com/privacy"
    static let policyUrl = "https://soulverse.thekono.com/terms"
    static let faqUrl = "https://thekono.notion.site/Soulverse-e0a0ad9fd8d248a699a0b349f16ff2e0"
    static let appStoreUrl = "https://itunes.apple.com/tw/app/1581434131"
    static let cancelSurveyUrl = "https://docs.google.com/forms/d/e/1FAIpQLSdOG5IKSoabMUk0zXUlQVa6LG7MK3zuxeS474VI45Ir7gK-ig/viewform?usp=pp_url&entry.1926187267="
    static let contactRecipient = "support@thekono.com"
    static let contactSubject = "Soulverse 問題回報"
    static let deleteAccountSubject = "刪除Soulverse帳號"
    
    static let recommendBookMailSubject = "為 Soulverse 推薦更多書籍"
    
    static let anonymousUserId = "anonymousUserId"
    
    #if Dev
    static let serverUrl = "https://soulverse-dev.thekono.com/api"
    static let sessionKey = "soulverse-dev"
    static var deleteAccountURL = "https://docs.google.com/forms/d/e/1FAIpQLSejv6NTc2p4uJmUAXFYJ5RURkw0IT2sfPcCbPDvLMBkkaL_6g/viewform?usp=pp_url&entry.2074189006="
    static var suggestTitleURL =
    "https://docs.google.com/forms/d/e/1FAIpQLSfW2E-SKBRU3mdHbNOKnoJYkHTXkMCGPHu6UkP8O2GDnwhZrQ/viewform?usp=pp_url&entry.1408017048="
    #else
    static let serverUrl = "https://soulverse.thekono.com/api"
    static let sessionKey = "soulverse-prd"
    static var deleteAccountURL = "https://docs.google.com/forms/d/e/1FAIpQLSejv6NTc2p4uJmUAXFYJ5RURkw0IT2sfPcCbPDvLMBkkaL_6g/viewform?usp=pp_url&entry.2074189006="
    static var suggestTitleURL =
    "https://docs.google.com/forms/d/e/1FAIpQLSfW2E-SKBRU3mdHbNOKnoJYkHTXkMCGPHu6UkP8O2GDnwhZrQ/viewform?usp=pp_url&entry.1408017048="
    #endif

    static let finishedTimeThreshold: Double = 10
    static let minimumPlayTimeThreshold: Double = 0.5
    static let pagingCount: Int = 10
    static let continuePlayItemCount = 3
}

struct DeviceConstants {
    
    static var width: CGFloat {
        get {
            let screenSize: CGRect = UIScreen.main.bounds
            return screenSize.width
        }
    }
    static var height: CGFloat {
        get {
            let screenSize: CGRect = UIScreen.main.bounds
            return screenSize.height
        }
    }
}

struct Notification {
    static let UserIdentityChange = "UserIdentityChange"
    static let RemoteConfigFetched = "RemoteConfigFetched"
}

struct InAppURLScheme {
    static let vocabulary = "vocabulary"
    static let hostApp = "soulverse"
}

enum ContentType: String, Equatable {
    
    case category, book, article, audio, video
    
}

struct TimeConstant {
    static let day = 86400.0
    static let hour = 3600.0
    static let miniute = 60.0
}
