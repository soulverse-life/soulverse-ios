//
//  EmotionType.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum EmotionType: String, CaseIterable {
    case joy = "Joy"
    case sadness = "Sadness"
    case anger = "Anger"
    case fear = "Fear"
    case trust = "Trust"
    case disgust = "Disgust"
    case anticipation = "Anticipation"
    case surprise = "Surprise"

    /// Display name for the emotion
    var displayName: String {
        return rawValue
    }

    /// Intensity labels for the emotion slider (left, center, right)
    var intensityLabels: (left: String, center: String, right: String) {
        switch self {
        case .joy:
            return ("Serenity", "Joy", "Ecstasy")
        case .sadness:
            return ("Pensiveness", "Sadness", "Grief")
        case .anger:
            return ("Annoyance", "Anger", "Rage")
        case .fear:
            return ("Apprehension", "Fear", "Terror")
        case .trust:
            return ("Acceptance", "Trust", "Admiration")
        case .disgust:
            return ("Boredom", "Disgust", "Loathing")
        case .anticipation:
            return ("Interest", "Anticipation", "Vigilance")
        case .surprise:
            return ("Distraction", "Surprise", "Amazement")
        }
    }
}
