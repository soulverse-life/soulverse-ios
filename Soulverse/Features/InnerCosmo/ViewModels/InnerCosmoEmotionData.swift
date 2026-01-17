//
//  InnerCosmoEmotionData.swift
//  Soulverse
//

import UIKit

/// Data model for emotion planets displayed in the InnerCosmo daily view
struct EmotionPlanetData {
    let emotion: String
    let colorHex: String
    let sizeMultiplier: CGFloat

    /// Converts hex string to UIColor
    var color: UIColor {
        UIColor(hex: colorHex) ?? .themeTextSecondary
    }
}

/// Period options for InnerCosmo view
enum InnerCosmoPeriod: Int, CaseIterable {
    case daily = 0
    case weekly = 1
    case monthly = 2

    var title: String {
        switch self {
        case .daily:
            return NSLocalizedString("inner_cosmo_period_daily", comment: "")
        case .weekly:
            return NSLocalizedString("inner_cosmo_period_weekly", comment: "")
        case .monthly:
            return NSLocalizedString("inner_cosmo_period_monthly", comment: "")
        }
    }
}

// MARK: - Mock Data Provider

extension EmotionPlanetData {
    /// Mock data for development and testing
    static let mockData: [EmotionPlanetData] = [
        EmotionPlanetData(emotion: "Day1", colorHex: "#A5D6A7", sizeMultiplier: 1.0)
    ]
}
