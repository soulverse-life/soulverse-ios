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
    /// Uses the same keys as RecordedEmotion for single source of truth
    var intensityLabels: (left: String, center: String, right: String) {
        switch self {
        case .joy:
            return (
                NSLocalizedString("emotion_serenity", comment: ""),
                NSLocalizedString("emotion_joy", comment: ""),
                NSLocalizedString("emotion_ecstasy", comment: "")
            )
        case .sadness:
            return (
                NSLocalizedString("emotion_pensiveness", comment: ""),
                NSLocalizedString("emotion_sadness", comment: ""),
                NSLocalizedString("emotion_grief", comment: "")
            )
        case .anger:
            return (
                NSLocalizedString("emotion_annoyance", comment: ""),
                NSLocalizedString("emotion_anger", comment: ""),
                NSLocalizedString("emotion_rage", comment: "")
            )
        case .fear:
            return (
                NSLocalizedString("emotion_apprehension", comment: ""),
                NSLocalizedString("emotion_fear", comment: ""),
                NSLocalizedString("emotion_terror", comment: "")
            )
        case .trust:
            return (
                NSLocalizedString("emotion_acceptance", comment: ""),
                NSLocalizedString("emotion_trust", comment: ""),
                NSLocalizedString("emotion_admiration", comment: "")
            )
        case .disgust:
            return (
                NSLocalizedString("emotion_boredom", comment: ""),
                NSLocalizedString("emotion_disgust", comment: ""),
                NSLocalizedString("emotion_loathing", comment: "")
            )
        case .anticipation:
            return (
                NSLocalizedString("emotion_interest", comment: ""),
                NSLocalizedString("emotion_anticipation", comment: ""),
                NSLocalizedString("emotion_vigilance", comment: "")
            )
        case .surprise:
            return (
                NSLocalizedString("emotion_distraction", comment: ""),
                NSLocalizedString("emotion_surprise", comment: ""),
                NSLocalizedString("emotion_amazement", comment: "")
            )
        }
    }

    /// The opposite emotion on Plutchik's wheel (4 petals apart)
    var oppositeEmotion: EmotionType {
        switch self {
        case .joy: return .sadness
        case .sadness: return .joy
        case .trust: return .disgust
        case .disgust: return .trust
        case .fear: return .anger
        case .anger: return .fear
        case .surprise: return .anticipation
        case .anticipation: return .surprise
        }
    }
}
