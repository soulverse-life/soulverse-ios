//
//  RecordedEmotionTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class RecordedEmotionTests: XCTestCase {

    // MARK: - from(primary:intensity:) Intensity Boundaries

    func test_RecordedEmotion_fromPrimary_lowIntensity_returnsLowVariant() {
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 0.0), .serenity)
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 0.25), .serenity)
    }

    func test_RecordedEmotion_fromPrimary_mediumIntensity_returnsMediumVariant() {
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 0.26), .joy)
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 0.5), .joy)
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 0.74), .joy)
    }

    func test_RecordedEmotion_fromPrimary_highIntensity_returnsHighVariant() {
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 0.75), .ecstasy)
        XCTAssertEqual(RecordedEmotion.from(primary: .joy, intensity: 1.0), .ecstasy)
    }

    // MARK: - from(primary:intensity:) All Primary Emotions

    func test_RecordedEmotion_fromPrimary_trust_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .trust, intensity: 0.0), .acceptance)
        XCTAssertEqual(RecordedEmotion.from(primary: .trust, intensity: 0.5), .trust)
        XCTAssertEqual(RecordedEmotion.from(primary: .trust, intensity: 1.0), .admiration)
    }

    func test_RecordedEmotion_fromPrimary_fear_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .fear, intensity: 0.0), .apprehension)
        XCTAssertEqual(RecordedEmotion.from(primary: .fear, intensity: 0.5), .fear)
        XCTAssertEqual(RecordedEmotion.from(primary: .fear, intensity: 1.0), .terror)
    }

    func test_RecordedEmotion_fromPrimary_surprise_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .surprise, intensity: 0.0), .distraction)
        XCTAssertEqual(RecordedEmotion.from(primary: .surprise, intensity: 0.5), .surprise)
        XCTAssertEqual(RecordedEmotion.from(primary: .surprise, intensity: 1.0), .amazement)
    }

    func test_RecordedEmotion_fromPrimary_sadness_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .sadness, intensity: 0.0), .pensiveness)
        XCTAssertEqual(RecordedEmotion.from(primary: .sadness, intensity: 0.5), .sadness)
        XCTAssertEqual(RecordedEmotion.from(primary: .sadness, intensity: 1.0), .grief)
    }

    func test_RecordedEmotion_fromPrimary_disgust_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .disgust, intensity: 0.0), .boredom)
        XCTAssertEqual(RecordedEmotion.from(primary: .disgust, intensity: 0.5), .disgust)
        XCTAssertEqual(RecordedEmotion.from(primary: .disgust, intensity: 1.0), .loathing)
    }

    func test_RecordedEmotion_fromPrimary_anger_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .anger, intensity: 0.0), .annoyance)
        XCTAssertEqual(RecordedEmotion.from(primary: .anger, intensity: 0.5), .anger)
        XCTAssertEqual(RecordedEmotion.from(primary: .anger, intensity: 1.0), .rage)
    }

    func test_RecordedEmotion_fromPrimary_anticipation_allIntensities() {
        XCTAssertEqual(RecordedEmotion.from(primary: .anticipation, intensity: 0.0), .interest)
        XCTAssertEqual(RecordedEmotion.from(primary: .anticipation, intensity: 0.5), .anticipation)
        XCTAssertEqual(RecordedEmotion.from(primary: .anticipation, intensity: 1.0), .vigilance)
    }

    // MARK: - from(emotion1:emotion2:) Primary Dyads

    func test_RecordedEmotion_fromTwoEmotions_primaryDyads_returnExpectedCombination() {
        XCTAssertEqual(RecordedEmotion.from(emotion1: .joy, emotion2: .anticipation), .optimism)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .joy, emotion2: .trust), .love)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .trust, emotion2: .fear), .submission)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .fear, emotion2: .surprise), .awe)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .surprise, emotion2: .sadness), .disapproval)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .sadness, emotion2: .disgust), .remorse)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .disgust, emotion2: .anger), .contempt)
        XCTAssertEqual(RecordedEmotion.from(emotion1: .anger, emotion2: .anticipation), .aggressiveness)
    }

    // MARK: - from(emotion1:emotion2:) Order Independence

    func test_RecordedEmotion_fromTwoEmotions_orderIndependent() {
        XCTAssertEqual(
            RecordedEmotion.from(emotion1: .joy, emotion2: .trust),
            RecordedEmotion.from(emotion1: .trust, emotion2: .joy)
        )
        XCTAssertEqual(
            RecordedEmotion.from(emotion1: .anger, emotion2: .anticipation),
            RecordedEmotion.from(emotion1: .anticipation, emotion2: .anger)
        )
    }

    // MARK: - from(emotion1:emotion2:) Opposite Emotions

    func test_RecordedEmotion_fromTwoEmotions_opposites_returnsNil() {
        XCTAssertNil(RecordedEmotion.from(emotion1: .joy, emotion2: .sadness))
        XCTAssertNil(RecordedEmotion.from(emotion1: .trust, emotion2: .disgust))
        XCTAssertNil(RecordedEmotion.from(emotion1: .fear, emotion2: .anger))
        XCTAssertNil(RecordedEmotion.from(emotion1: .surprise, emotion2: .anticipation))
    }

    // MARK: - from(emotion1:emotion2:) Same Emotion

    func test_RecordedEmotion_fromTwoEmotions_sameEmotion_returnsNil() {
        XCTAssertNil(RecordedEmotion.from(emotion1: .joy, emotion2: .joy))
        XCTAssertNil(RecordedEmotion.from(emotion1: .anger, emotion2: .anger))
    }

    // MARK: - sourceEmotions

    func test_RecordedEmotion_sourceEmotions_combinedEmotion_returnsSourcePair() {
        let sources = RecordedEmotion.love.sourceEmotions
        XCTAssertNotNil(sources)
        XCTAssertEqual(sources?.0, .joy)
        XCTAssertEqual(sources?.1, .trust)
    }

    func test_RecordedEmotion_sourceEmotions_intensityBasedEmotion_returnsNil() {
        XCTAssertNil(RecordedEmotion.serenity.sourceEmotions)
        XCTAssertNil(RecordedEmotion.joy.sourceEmotions)
        XCTAssertNil(RecordedEmotion.ecstasy.sourceEmotions)
    }

    // MARK: - isCombinedEmotion

    func test_RecordedEmotion_isCombinedEmotion_trueForDyads() {
        XCTAssertTrue(RecordedEmotion.optimism.isCombinedEmotion)
        XCTAssertTrue(RecordedEmotion.love.isCombinedEmotion)
        XCTAssertTrue(RecordedEmotion.pride.isCombinedEmotion)
        XCTAssertTrue(RecordedEmotion.anxiety.isCombinedEmotion)
    }

    func test_RecordedEmotion_isCombinedEmotion_falseForIntensityBased() {
        XCTAssertFalse(RecordedEmotion.serenity.isCombinedEmotion)
        XCTAssertFalse(RecordedEmotion.joy.isCombinedEmotion)
        XCTAssertFalse(RecordedEmotion.rage.isCombinedEmotion)
        XCTAssertFalse(RecordedEmotion.terror.isCombinedEmotion)
    }

    // MARK: - displayName

    func test_RecordedEmotion_displayName_nonEmptyForAllCases() {
        for emotion in RecordedEmotion.allCases {
            XCTAssertFalse(emotion.displayName.isEmpty, "\(emotion) has empty displayName")
        }
    }

    // MARK: - uniqueKey

    func test_RecordedEmotion_uniqueKey_equalsRawValue() {
        for emotion in RecordedEmotion.allCases {
            XCTAssertEqual(emotion.uniqueKey, emotion.rawValue)
        }
    }

    // MARK: - CaseIterable Count

    func test_RecordedEmotion_allCases_contains48Cases() {
        // 24 intensity-based (8 emotions x 3 intensities) + 24 dyads (8 + 8 + 8)
        XCTAssertEqual(RecordedEmotion.allCases.count, 48)
    }
}
