//
//  RecordedEmotion.swift
//  Soulverse
//
//  Unified emotion model based on Plutchik's Wheel of Emotions.
//  Represents all possible emotions that can be recorded from mood check-in.
//
//  Wheel order (clockwise): Joy → Trust → Fear → Surprise → Sadness → Disgust → Anger → Anticipation
//  Dyad distance = number of petals apart (taking the shorter path around the wheel)
//  Opposite emotions (4 apart) do NOT combine: Joy↔Sadness, Trust↔Disgust, Fear↔Anger, Surprise↔Anticipation
//

import Foundation

/// All possible recorded emotions - either intensity-based (single primary) or combined (two primaries)
enum RecordedEmotion: String, CaseIterable, Codable, Hashable {

    // MARK: - Joy Family (intensity-based)
    case serenity       // Joy, low intensity
    case joy            // Joy, medium intensity
    case ecstasy        // Joy, high intensity

    // MARK: - Trust Family
    case acceptance     // Trust, low intensity
    case trust          // Trust, medium intensity
    case admiration     // Trust, high intensity

    // MARK: - Fear Family
    case apprehension   // Fear, low intensity
    case fear           // Fear, medium intensity
    case terror         // Fear, high intensity

    // MARK: - Surprise Family
    case distraction    // Surprise, low intensity
    case surprise       // Surprise, medium intensity
    case amazement      // Surprise, high intensity

    // MARK: - Sadness Family
    case pensiveness    // Sadness, low intensity
    case sadness        // Sadness, medium intensity
    case grief          // Sadness, high intensity

    // MARK: - Disgust Family
    case boredom        // Disgust, low intensity
    case disgust        // Disgust, medium intensity
    case loathing       // Disgust, high intensity

    // MARK: - Anger Family
    case annoyance      // Anger, low intensity
    case anger          // Anger, medium intensity
    case rage           // Anger, high intensity

    // MARK: - Anticipation Family
    case interest       // Anticipation, low intensity
    case anticipation   // Anticipation, medium intensity
    case vigilance      // Anticipation, high intensity

    // MARK: - Primary Dyads (Adjacent emotions - 1 petal apart, 8 combinations)
    case optimism       // Joy + Anticipation
    case love           // Joy + Trust
    case submission     // Trust + Fear
    case awe            // Fear + Surprise
    case disapproval    // Surprise + Sadness
    case remorse        // Sadness + Disgust
    case contempt       // Disgust + Anger
    case aggressiveness // Anger + Anticipation

    // MARK: - Secondary Dyads (2 petals apart, 8 combinations)
    case guilt          // Joy + Fear
    case curiosity      // Trust + Surprise
    case despair        // Fear + Sadness
    case unbelief       // Surprise + Disgust
    case envy           // Sadness + Anger
    case cynicism       // Disgust + Anticipation
    case pride          // Anger + Joy
    case fatalism       // Anticipation + Trust

    // MARK: - Tertiary Dyads (3 petals apart, 8 combinations)
    case morbidness     // Joy + Disgust
    case sentimentality // Trust + Sadness
    case shame          // Fear + Disgust
    case delight        // Surprise + Joy
    case dominance      // Anger + Trust
    case anxiety        // Anticipation + Fear
    case outrage        // Anger + Surprise
    case pessimism      // Anticipation + Sadness

    // MARK: - Display Name

    var displayName: String {
        switch self {
        // Joy Family (intensity-based)
        case .serenity: return NSLocalizedString("emotion_serenity", comment: "")
        case .joy: return NSLocalizedString("emotion_joy", comment: "")
        case .ecstasy: return NSLocalizedString("emotion_ecstasy", comment: "")

        // Trust Family
        case .acceptance: return NSLocalizedString("emotion_acceptance", comment: "")
        case .trust: return NSLocalizedString("emotion_trust", comment: "")
        case .admiration: return NSLocalizedString("emotion_admiration", comment: "")

        // Fear Family
        case .apprehension: return NSLocalizedString("emotion_apprehension", comment: "")
        case .fear: return NSLocalizedString("emotion_fear", comment: "")
        case .terror: return NSLocalizedString("emotion_terror", comment: "")

        // Surprise Family
        case .distraction: return NSLocalizedString("emotion_distraction", comment: "")
        case .surprise: return NSLocalizedString("emotion_surprise", comment: "")
        case .amazement: return NSLocalizedString("emotion_amazement", comment: "")

        // Sadness Family
        case .pensiveness: return NSLocalizedString("emotion_pensiveness", comment: "")
        case .sadness: return NSLocalizedString("emotion_sadness", comment: "")
        case .grief: return NSLocalizedString("emotion_grief", comment: "")

        // Disgust Family
        case .boredom: return NSLocalizedString("emotion_boredom", comment: "")
        case .disgust: return NSLocalizedString("emotion_disgust", comment: "")
        case .loathing: return NSLocalizedString("emotion_loathing", comment: "")

        // Anger Family
        case .annoyance: return NSLocalizedString("emotion_annoyance", comment: "")
        case .anger: return NSLocalizedString("emotion_anger", comment: "")
        case .rage: return NSLocalizedString("emotion_rage", comment: "")

        // Anticipation Family
        case .interest: return NSLocalizedString("emotion_interest", comment: "")
        case .anticipation: return NSLocalizedString("emotion_anticipation", comment: "")
        case .vigilance: return NSLocalizedString("emotion_vigilance", comment: "")

        // Primary Dyads (combined emotions)
        case .optimism: return NSLocalizedString("emotion_optimism", comment: "")
        case .love: return NSLocalizedString("emotion_love", comment: "")
        case .submission: return NSLocalizedString("emotion_submission", comment: "")
        case .awe: return NSLocalizedString("emotion_awe", comment: "")
        case .disapproval: return NSLocalizedString("emotion_disapproval", comment: "")
        case .remorse: return NSLocalizedString("emotion_remorse", comment: "")
        case .contempt: return NSLocalizedString("emotion_contempt", comment: "")
        case .aggressiveness: return NSLocalizedString("emotion_aggressiveness", comment: "")

        // Secondary Dyads
        case .guilt: return NSLocalizedString("emotion_guilt", comment: "")
        case .curiosity: return NSLocalizedString("emotion_curiosity", comment: "")
        case .despair: return NSLocalizedString("emotion_despair", comment: "")
        case .unbelief: return NSLocalizedString("emotion_unbelief", comment: "")
        case .envy: return NSLocalizedString("emotion_envy", comment: "")
        case .cynicism: return NSLocalizedString("emotion_cynicism", comment: "")
        case .pride: return NSLocalizedString("emotion_pride", comment: "")
        case .fatalism: return NSLocalizedString("emotion_fatalism", comment: "")

        // Tertiary Dyads
        case .morbidness: return NSLocalizedString("emotion_morbidness", comment: "")
        case .sentimentality: return NSLocalizedString("emotion_sentimentality", comment: "")
        case .shame: return NSLocalizedString("emotion_shame", comment: "")
        case .delight: return NSLocalizedString("emotion_delight", comment: "")
        case .dominance: return NSLocalizedString("emotion_dominance", comment: "")
        case .anxiety: return NSLocalizedString("emotion_anxiety", comment: "")
        case .outrage: return NSLocalizedString("emotion_outrage", comment: "")
        case .pessimism: return NSLocalizedString("emotion_pessimism", comment: "")
        }
    }

    /// Unique key for backend/analytics (same as rawValue)
    var uniqueKey: String {
        return rawValue
    }

    /// Returns the source primary emotions if this is a combined emotion, nil otherwise
    /// Used to display "Joy + Anger = Pride" format
    var sourceEmotions: (EmotionType, EmotionType)? {
        switch self {
        // Primary Dyads
        case .optimism: return (.joy, .anticipation)
        case .love: return (.joy, .trust)
        case .submission: return (.trust, .fear)
        case .awe: return (.fear, .surprise)
        case .disapproval: return (.surprise, .sadness)
        case .remorse: return (.sadness, .disgust)
        case .contempt: return (.disgust, .anger)
        case .aggressiveness: return (.anger, .anticipation)

        // Secondary Dyads
        case .guilt: return (.joy, .fear)
        case .curiosity: return (.trust, .surprise)
        case .despair: return (.fear, .sadness)
        case .unbelief: return (.surprise, .disgust)
        case .envy: return (.sadness, .anger)
        case .cynicism: return (.disgust, .anticipation)
        case .pride: return (.anger, .joy)
        case .fatalism: return (.anticipation, .trust)

        // Tertiary Dyads
        case .morbidness: return (.joy, .disgust)
        case .sentimentality: return (.trust, .sadness)
        case .shame: return (.fear, .disgust)
        case .delight: return (.surprise, .joy)
        case .dominance: return (.anger, .trust)
        case .anxiety: return (.anticipation, .fear)
        case .outrage: return (.anger, .surprise)
        case .pessimism: return (.anticipation, .sadness)

        // Intensity-based emotions (not combined)
        default: return nil
        }
    }

    /// Whether this emotion is a combined emotion (from two primary emotions)
    var isCombinedEmotion: Bool {
        return sourceEmotions != nil
    }
}

// MARK: - Resolution Methods

extension RecordedEmotion {

    /// Resolve a single primary emotion with intensity to a RecordedEmotion
    /// - Parameters:
    ///   - primary: The primary emotion type selected
    ///   - intensity: The intensity level (0.0 = low, 0.5 = medium, 1.0 = high)
    /// - Returns: The corresponding RecordedEmotion
    static func from(primary: EmotionType, intensity: Double) -> RecordedEmotion {
        // Normalize intensity to low/medium/high
        let level: IntensityLevel
        if intensity <= 0.25 {
            level = .low
        } else if intensity >= 0.75 {
            level = .high
        } else {
            level = .medium
        }

        switch (primary, level) {
        case (.joy, .low): return .serenity
        case (.joy, .medium): return .joy
        case (.joy, .high): return .ecstasy

        case (.trust, .low): return .acceptance
        case (.trust, .medium): return .trust
        case (.trust, .high): return .admiration

        case (.fear, .low): return .apprehension
        case (.fear, .medium): return .fear
        case (.fear, .high): return .terror

        case (.surprise, .low): return .distraction
        case (.surprise, .medium): return .surprise
        case (.surprise, .high): return .amazement

        case (.sadness, .low): return .pensiveness
        case (.sadness, .medium): return .sadness
        case (.sadness, .high): return .grief

        case (.disgust, .low): return .boredom
        case (.disgust, .medium): return .disgust
        case (.disgust, .high): return .loathing

        case (.anger, .low): return .annoyance
        case (.anger, .medium): return .anger
        case (.anger, .high): return .rage

        case (.anticipation, .low): return .interest
        case (.anticipation, .medium): return .anticipation
        case (.anticipation, .high): return .vigilance
        }
    }

    /// Resolve two primary emotions to a combined RecordedEmotion
    /// Opposite emotions (4 petals apart on Plutchik's wheel) cannot combine and return nil.
    /// - Parameters:
    ///   - emotion1: First primary emotion
    ///   - emotion2: Second primary emotion
    /// - Returns: The combined emotion if valid combination exists, nil otherwise
    static func from(emotion1: EmotionType, emotion2: EmotionType) -> RecordedEmotion? {
        // Create a set to handle order-independent lookup
        let pair = Set([emotion1, emotion2])

        // Same emotion or opposite emotions cannot combine
        if emotion1 == emotion2 || emotion1.oppositeEmotion == emotion2 {
            return nil
        }

        // Primary Dyads (1 petal apart)
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

        // Tertiary Dyads (3 petals apart)
        if pair == [.joy, .disgust] { return .morbidness }
        if pair == [.trust, .sadness] { return .sentimentality }
        if pair == [.fear, .disgust] { return .shame }
        if pair == [.surprise, .joy] { return .delight }
        if pair == [.anger, .trust] { return .dominance }
        if pair == [.anticipation, .fear] { return .anxiety }
        if pair == [.anger, .surprise] { return .outrage }
        if pair == [.anticipation, .sadness] { return .pessimism }

        return nil
    }

    // MARK: - Private

    private enum IntensityLevel {
        case low, medium, high
    }
}
