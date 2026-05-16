//
//  InnerCosmoEmotionData.swift
//  Soulverse
//

import UIKit

/// Data model for emotion planets displayed in the InnerCosmo daily view
struct EmotionPlanetData {
    let emotion: String
    /// Base color of the planet. Stored as UIColor (preferred); legacy
    /// callers can still construct via the `colorHex:` init below.
    let baseColor: UIColor
    var sizeMultiplier: CGFloat = 1.0
    /// Check-in intensity (0.0–1.0). Applied as alpha to the planet color so
    /// lower-intensity check-ins render as a more washed-out variant of the
    /// same hue. Defaults to 1.0 (full intensity) for callers that don't
    /// track intensity.
    var intensity: Double = 1.0

    /// Final planet color with intensity applied as alpha.
    var color: UIColor {
        let clamped = max(0, min(1, intensity))
        return baseColor.withAlphaComponent(CGFloat(clamped))
    }

    init(emotion: String, color: UIColor, sizeMultiplier: CGFloat = 1.0, intensity: Double = 1.0) {
        self.emotion = emotion
        self.baseColor = color
        self.sizeMultiplier = sizeMultiplier
        self.intensity = intensity
    }

    /// Backwards-compat init for Firestore-driven callers that pass hex strings
    /// (mood check-in colorHex comes off the wire as a string).
    init(emotion: String, colorHex: String, sizeMultiplier: CGFloat = 1.0, intensity: Double = 1.0) {
        let base = UIColor(hex: colorHex) ?? .themeTextSecondary
        self.init(emotion: emotion, color: base, sizeMultiplier: sizeMultiplier, intensity: intensity)
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
