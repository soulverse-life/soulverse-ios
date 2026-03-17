//
//  InnerCosmoEmotionData.swift
//  Soulverse
//

import UIKit

/// Data model for emotion planets displayed in the InnerCosmo daily view
struct EmotionPlanetData {
    let emotion: String
    let colorHex: String
    var sizeMultiplier: CGFloat = 1.0

    /// Converts hex string to UIColor
    var color: UIColor {
        UIColor(hex: colorHex) ?? .themeTextSecondary
    }
}

/// Period options for InnerCosmo view
enum InnerCosmoPeriod: Int, CaseIterable {
    case recent = 0
    case all = 1

    var title: String {
        switch self {
        case .recent:
            return NSLocalizedString("inner_cosmo_period_recent", comment: "")
        case .all:
            return NSLocalizedString("inner_cosmo_period_all", comment: "")
        }
    }
}

// MARK: - Mock Data Provider

extension EmotionPlanetData {
    /// Mock data for development and testing
    static let mockData: [EmotionPlanetData] = [
        EmotionPlanetData(emotion: "Day1", colorHex: "#A5D6A7")
    ]
}
