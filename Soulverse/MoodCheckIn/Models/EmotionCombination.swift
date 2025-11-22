//
//  EmotionCombination.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

/// Combined emotions based on Plutchik's Wheel of Emotions
/// Represents the result of combining two primary emotions into a secondary/tertiary emotion
enum EmotionCombination: String, CaseIterable {

    // MARK: - Primary Dyads (Adjacent emotions - 1 petal apart)

    /// Joy + Anticipation
    case optimism

    /// Joy + Trust
    case love

    /// Trust + Fear
    case submission

    /// Fear + Surprise
    case awe

    /// Surprise + Sadness
    case disapproval

    /// Sadness + Disgust
    case remorse

    /// Disgust + Anger
    case contempt

    /// Anger + Anticipation
    case aggressiveness

    // MARK: - Secondary Dyads (2 petals apart)

    /// Joy + Fear
    case guilt

    /// Trust + Surprise
    case curiosity

    /// Fear + Sadness
    case despair

    /// Surprise + Disgust
    case unbelief

    /// Sadness + Anger
    case envy

    /// Disgust + Anticipation
    case cynicism

    /// Anger + Joy
    case pride

    /// Anticipation + Trust
    case fatalism

    /// Joy + Sadness (additional secondary)
    case bittersweetness

    /// Trust + Anger (additional secondary)
    case dominance

    /// Fear + Disgust (additional secondary)
    case shame

    /// Surprise + Anticipation (additional secondary)
    case confusion

    // MARK: - Tertiary Dyads (3 petals apart)

    /// Joy + Disgust
    case morbidness

    /// Trust + Sadness
    case sentimentality

    /// Fear + Anger
    case anxiety

    /// Surprise + Joy
    case delight

    /// Sadness + Trust
    case resignation

    /// Disgust + Fear
    case horror

    /// Anger + Surprise
    case outrage

    /// Anticipation + Sadness
    case pessimism

    // MARK: - Display Name

    /// Localized display name for the combined emotion
    var displayName: String {
        switch self {
        // Primary Dyads
        case .optimism:
            return NSLocalizedString("emotion_combination_optimism", comment: "")
        case .love:
            return NSLocalizedString("emotion_combination_love", comment: "")
        case .submission:
            return NSLocalizedString("emotion_combination_submission", comment: "")
        case .awe:
            return NSLocalizedString("emotion_combination_awe", comment: "")
        case .disapproval:
            return NSLocalizedString("emotion_combination_disapproval", comment: "")
        case .remorse:
            return NSLocalizedString("emotion_combination_remorse", comment: "")
        case .contempt:
            return NSLocalizedString("emotion_combination_contempt", comment: "")
        case .aggressiveness:
            return NSLocalizedString("emotion_combination_aggressiveness", comment: "")

        // Secondary Dyads
        case .guilt:
            return NSLocalizedString("emotion_combination_guilt", comment: "")
        case .curiosity:
            return NSLocalizedString("emotion_combination_curiosity", comment: "")
        case .despair:
            return NSLocalizedString("emotion_combination_despair", comment: "")
        case .unbelief:
            return NSLocalizedString("emotion_combination_unbelief", comment: "")
        case .envy:
            return NSLocalizedString("emotion_combination_envy", comment: "")
        case .cynicism:
            return NSLocalizedString("emotion_combination_cynicism", comment: "")
        case .pride:
            return NSLocalizedString("emotion_combination_pride", comment: "")
        case .fatalism:
            return NSLocalizedString("emotion_combination_fatalism", comment: "")
        case .bittersweetness:
            return NSLocalizedString("emotion_combination_bittersweetness", comment: "")
        case .dominance:
            return NSLocalizedString("emotion_combination_dominance", comment: "")
        case .shame:
            return NSLocalizedString("emotion_combination_shame", comment: "")
        case .confusion:
            return NSLocalizedString("emotion_combination_confusion", comment: "")

        // Tertiary Dyads
        case .morbidness:
            return NSLocalizedString("emotion_combination_morbidness", comment: "")
        case .sentimentality:
            return NSLocalizedString("emotion_combination_sentimentality", comment: "")
        case .anxiety:
            return NSLocalizedString("emotion_combination_anxiety", comment: "")
        case .delight:
            return NSLocalizedString("emotion_combination_delight", comment: "")
        case .resignation:
            return NSLocalizedString("emotion_combination_resignation", comment: "")
        case .horror:
            return NSLocalizedString("emotion_combination_horror", comment: "")
        case .outrage:
            return NSLocalizedString("emotion_combination_outrage", comment: "")
        case .pessimism:
            return NSLocalizedString("emotion_combination_pessimism", comment: "")
        }
    }

    // MARK: - Static Methods

    /// Get the combined emotion from two primary emotions
    /// - Parameters:
    ///   - emotion1: First primary emotion
    ///   - emotion2: Second primary emotion
    /// - Returns: Combined emotion if a valid combination exists, nil otherwise
    static func getCombinedEmotion(from emotion1: EmotionType, and emotion2: EmotionType) -> EmotionCombination? {
        // Create a sorted set to handle order-independent lookup
        let pair = Set([emotion1, emotion2])

        // If both emotions are the same, no combination
        if emotion1 == emotion2 {
            return nil
        }

        // Primary Dyads (adjacent emotions)
        if pair == [.joy, .anticipation] { return .optimism }
        if pair == [.joy, .trust] { return .love }
        if pair == [.trust, .fear] { return .submission }
        if pair == [.fear, .surprise] { return .awe }
        if pair == [.surprise, .sadness] { return .disapproval }
        if pair == [.sadness, .disgust] { return .remorse }
        if pair == [.disgust, .anger] { return .contempt }
        if pair == [.anger, .anticipation] { return .aggressiveness }

        // Secondary Dyads (2 petals apart)
        if pair == [.joy, .fear] { return .guilt }
        if pair == [.trust, .surprise] { return .curiosity }
        if pair == [.fear, .sadness] { return .despair }
        if pair == [.surprise, .disgust] { return .unbelief }
        if pair == [.sadness, .anger] { return .envy }
        if pair == [.disgust, .anticipation] { return .cynicism }
        if pair == [.anger, .joy] { return .pride }
        if pair == [.anticipation, .trust] { return .fatalism }
        if pair == [.joy, .sadness] { return .bittersweetness }
        if pair == [.trust, .anger] { return .dominance }
        if pair == [.fear, .disgust] { return .shame }
        if pair == [.surprise, .anticipation] { return .confusion }

        // Tertiary Dyads (3 petals apart)
        if pair == [.joy, .disgust] { return .morbidness }
        if pair == [.trust, .sadness] { return .sentimentality }
        if pair == [.fear, .anger] { return .anxiety }
        if pair == [.surprise, .joy] { return .delight }
        if pair == [.sadness, .trust] { return .resignation }
        if pair == [.disgust, .fear] { return .horror }
        if pair == [.anger, .surprise] { return .outrage }
        if pair == [.anticipation, .sadness] { return .pessimism }

        return nil
    }
}
