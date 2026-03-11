//
//  RecordedEmotion+MoodScore.swift
//  Soulverse
//

import Foundation

extension RecordedEmotion {

    /// A mood score in the range approximately -0.5...+0.5,
    /// derived from the emotion-to-valence mapping.
    /// Returns 0.0 (neutral) for any emotion without a mapped score.
    var moodScore: Double {
        return Self.moodScores[self] ?? 0.0
    }

    // MARK: - Score Data

    private static let moodScores: [RecordedEmotion: Double] = [
        // Joy family
        .serenity: 0.17,
        .joy: 0.46,
        .ecstasy: 0.35,

        // Trust family
        .acceptance: 0.19,
        .trust: 0.23,
        .admiration: 0.36,

        // Fear family
        .apprehension: -0.20,
        .fear: -0.33,
        .terror: -0.38,

        // Surprise family
        .distraction: -0.09,
        .surprise: 0.42,
        .amazement: 0.38,

        // Sadness family
        .pensiveness: -0.16,
        .sadness: -0.15,
        .grief: -0.33,

        // Disgust family
        .boredom: -0.11,
        .disgust: -0.21,
        .loathing: -0.28,

        // Anger family
        .annoyance: -0.29,
        .anger: -0.39,
        .rage: -0.44,

        // Anticipation family
        .interest: 0.17,
        .anticipation: 0.04,
        .vigilance: 0.06,

        // Primary dyads
        .optimism: 0.27,
        .love: 0.41,
        .submission: -0.04,
        .awe: 0.16,
        .disapproval: -0.16,
        .remorse: -0.14,
        .contempt: -0.20,
        .aggressiveness: -0.29,

        // Secondary dyads
        .guilt: -0.29,
        .curiosity: 0.21,
        .despair: -0.16,
        .unbelief: -0.11,
        .envy: -0.20,
        .cynicism: -0.20,
        .pride: 0.21,
        .fatalism: 0.0,

        // Tertiary dyads
        .morbidness: -0.30,
        .sentimentality: 0.08,
        .shame: -0.33,
        .delight: 0.40,
        .dominance: 0.03,
        .anxiety: -0.31,
        .outrage: -0.35,
        .pessimism: -0.12,
    ]
}
