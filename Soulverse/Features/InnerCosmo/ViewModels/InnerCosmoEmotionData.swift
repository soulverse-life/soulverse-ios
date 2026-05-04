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
    /// Check-in intensity (0.0–1.0). Applied as alpha to the planet color so
    /// lower-intensity check-ins render as a more washed-out variant of the
    /// same hue. Defaults to 1.0 (full intensity) for callers that don't
    /// track intensity.
    var intensity: Double = 1.0

    /// Converts hex string to UIColor with intensity applied as alpha.
    var color: UIColor {
        let base = UIColor(hex: colorHex) ?? .themeTextSecondary
        let clamped = max(0, min(1, intensity))
        return base.withAlphaComponent(CGFloat(clamped))
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
