//
//  Constants.swift
//
//  Created by mingshing on 2021/8/16.
//

import Foundation
import SnapKit
import UIKit


struct ViewComponentConstants {
    static let navigationBarHeight: CGFloat = 48.0
    static let actionButtonHeight: CGFloat = 48.0
    static let smallActionButtonHeight: CGFloat = 20.0
    static let navigationButtonSize: CGFloat = 44.0
    static let colorDisplaySize: CGFloat = 30.0

    static let progressViewWidth: CGFloat = 144.0

    static let horizontalPadding: CGFloat = 26.0

    /// Configures a card view with a light glass effect (iOS 26+) or semi-transparent fallback.
    /// Use for cards that sit over a light/neutral background.
    static func applyGlassCardEffect(
        to cardView: UIView,
        visualEffectView: UIVisualEffectView,
        contentView: UIView,
        cornerRadius: CGFloat
    ) {
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = cornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(contentView)
            cardView.addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            cardView.backgroundColor = .white.withAlphaComponent(0.1)
            cardView.layer.borderWidth = 1
            cardView.layer.borderColor = UIColor.themeSeparator.cgColor
            cardView.addSubview(contentView)
        }
    }

    /// Configures a card view with a dark glass effect (iOS 26+) or dark semi-transparent fallback.
    /// Matches the look of `MoodEntryCardCell`: a black backing layer sits beneath the glass so
    /// the card reads as dark even on top of dark backgrounds. Use for cards on dark-themed pages.
    static func applyDarkGlassCardEffect(
        to cardView: UIView,
        visualEffectView: UIVisualEffectView,
        contentView: UIView,
        cornerRadius: CGFloat
    ) {
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = cornerRadius
            visualEffectView.clipsToBounds = true

            // Black backing layer underneath the content so the glass card reads as dark.
            let darkBackingView = UIView()
            darkBackingView.backgroundColor = .black.withAlphaComponent(0.5)
            visualEffectView.contentView.addSubview(darkBackingView)
            darkBackingView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            visualEffectView.contentView.addSubview(contentView)
            cardView.addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            cardView.backgroundColor = .black.withAlphaComponent(0.4)
            cardView.layer.borderWidth = 1
            cardView.layer.borderColor = UIColor.themeSeparator.cgColor
            cardView.addSubview(contentView)
        }
    }
}


struct HostAppContants {
    
    
    static let privacyUrl = "https://soulverse.thekono.com/privacy"
    static let policyUrl = "https://soulverse.thekono.com/terms"
    static let faqUrl = "https://thekono.notion.site/Soulverse-e0a0ad9fd8d248a699a0b349f16ff2e0"
    static let appStoreUrl = "https://itunes.apple.com/tw/app/1581434131"
    static let cancelSurveyUrl = "https://docs.google.com/forms/d/e/1FAIpQLSdOG5IKSoabMUk0zXUlQVa6LG7MK3zuxeS474VI45Ir7gK-ig/viewform?usp=pp_url&entry.1926187267="
    static let contactRecipient = "support@thekono.com"
    static let contactSubject = "Soulverse 問題回報"
    static let deleteAccountSubject = "刪除Soulverse帳號"
    
    static let recommendBookMailSubject = "為 Soulverse 推薦更多書籍"
    
    
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
    static let MoodCheckInCreated = "MoodCheckInCreated"
    /// Posted whenever a drawing's persisted state changes — created on save,
    /// or updated when the reflection answer is filled in / changed.
    static let DrawingDidChange = "DrawingDidChange"
    /// Posted when a journal entry is created or updated for a check-in.
    static let JournalDidChange = "JournalDidChange"
}

struct InAppURLScheme {
    static let vocabulary = "vocabulary"
    static let hostApp = "soulverse"
}


struct TimeConstant {
    static let day = 86400.0
    static let hour = 3600.0
    static let miniute = 60.0
}

struct AnimationConstant {
    static let defaultDuration: TimeInterval = 0.2
}

struct ColorIntensityConstants {
    /// Number of intensity levels (circles) for color selection
    static let levelCount: Int = 5

    /// Minimum alpha value for the weakest intensity level
    static let minAlpha: Double = 0.3

    /// Maximum alpha value for the strongest intensity level
    static let maxAlpha: Double = 1.0

    /// Converts an intensity level index (0..<levelCount) to an alpha value.
    static func alpha(forLevel level: Int) -> Double {
        guard levelCount > 1 else { return maxAlpha }
        let step = (maxAlpha - minAlpha) / Double(levelCount - 1)
        return minAlpha + step * Double(level)
    }

    /// Converts a stored alpha value back to the nearest intensity level index.
    static func level(forAlpha alpha: Double) -> Int {
        guard levelCount > 1 else { return 0 }
        let step = (maxAlpha - minAlpha) / Double(levelCount - 1)
        let level = (alpha - minAlpha) / step
        return max(0, min(levelCount - 1, Int(round(level))))
    }
}

struct Layout {
    // MARK: - Quest Progress View Layout
    struct QuestProgress {
        static let containerPadding: CGFloat = 20
        static let titleTopOffset: CGFloat = 10
        static let sectionSpacing: CGFloat = 10
        static let bottomPadding: CGFloat = 10
        
        // View heights
        static let titleHeight: CGFloat = 20
        static let progressContainerHeight: CGFloat = 40
        static let labelsContainerHeight: CGFloat = 20
        
        // Font sizes
        static let titleFontSize: CGFloat = 16
        static let labelFontSize: CGFloat = 10
    }
}
