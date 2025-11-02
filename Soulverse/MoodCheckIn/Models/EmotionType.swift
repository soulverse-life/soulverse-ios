//
//  EmotionType.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum EmotionType: String, CaseIterable {
    case joy
    case sadness
    case anger
    case fear
    case trust
    case disgust
    case anticipation
    case surprise

    /// Display name for the emotion (localized)
    var displayName: String {
        switch self {
        case .joy:
            return NSLocalizedString("emotion_joy", comment: "")
        case .sadness:
            return NSLocalizedString("emotion_sadness", comment: "")
        case .anger:
            return NSLocalizedString("emotion_anger", comment: "")
        case .fear:
            return NSLocalizedString("emotion_fear", comment: "")
        case .trust:
            return NSLocalizedString("emotion_trust", comment: "")
        case .disgust:
            return NSLocalizedString("emotion_disgust", comment: "")
        case .anticipation:
            return NSLocalizedString("emotion_anticipation", comment: "")
        case .surprise:
            return NSLocalizedString("emotion_surprise", comment: "")
        }
    }

    /// Intensity labels for the emotion slider (left, center, right) - localized
    var intensityLabels: (left: String, center: String, right: String) {
        switch self {
        case .joy:
            return (
                NSLocalizedString("emotion_joy_low", comment: ""),
                NSLocalizedString("emotion_joy_medium", comment: ""),
                NSLocalizedString("emotion_joy_high", comment: "")
            )
        case .sadness:
            return (
                NSLocalizedString("emotion_sadness_low", comment: ""),
                NSLocalizedString("emotion_sadness_medium", comment: ""),
                NSLocalizedString("emotion_sadness_high", comment: "")
            )
        case .anger:
            return (
                NSLocalizedString("emotion_anger_low", comment: ""),
                NSLocalizedString("emotion_anger_medium", comment: ""),
                NSLocalizedString("emotion_anger_high", comment: "")
            )
        case .fear:
            return (
                NSLocalizedString("emotion_fear_low", comment: ""),
                NSLocalizedString("emotion_fear_medium", comment: ""),
                NSLocalizedString("emotion_fear_high", comment: "")
            )
        case .trust:
            return (
                NSLocalizedString("emotion_trust_low", comment: ""),
                NSLocalizedString("emotion_trust_medium", comment: ""),
                NSLocalizedString("emotion_trust_high", comment: "")
            )
        case .disgust:
            return (
                NSLocalizedString("emotion_disgust_low", comment: ""),
                NSLocalizedString("emotion_disgust_medium", comment: ""),
                NSLocalizedString("emotion_disgust_high", comment: "")
            )
        case .anticipation:
            return (
                NSLocalizedString("emotion_anticipation_low", comment: ""),
                NSLocalizedString("emotion_anticipation_medium", comment: ""),
                NSLocalizedString("emotion_anticipation_high", comment: "")
            )
        case .surprise:
            return (
                NSLocalizedString("emotion_surprise_low", comment: ""),
                NSLocalizedString("emotion_surprise_medium", comment: ""),
                NSLocalizedString("emotion_surprise_high", comment: "")
            )
        }
    }
}
