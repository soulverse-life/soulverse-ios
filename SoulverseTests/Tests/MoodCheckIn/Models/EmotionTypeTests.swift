//
//  EmotionTypeTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class EmotionTypeTests: XCTestCase {

    // MARK: - CaseIterable

    func test_EmotionType_allCases_contains8Cases() {
        XCTAssertEqual(EmotionType.allCases.count, 8)
    }

    // MARK: - displayName

    func test_EmotionType_displayName_nonEmptyForAllCases() {
        for emotion in EmotionType.allCases {
            XCTAssertFalse(emotion.displayName.isEmpty, "\(emotion) has empty displayName")
        }
    }

    // MARK: - oppositeEmotion Symmetry

    func test_EmotionType_oppositeEmotion_isSymmetric() {
        for emotion in EmotionType.allCases {
            let opposite = emotion.oppositeEmotion
            XCTAssertEqual(
                opposite.oppositeEmotion, emotion,
                "\(emotion).opposite is \(opposite), but \(opposite).opposite is \(opposite.oppositeEmotion)"
            )
        }
    }

    func test_EmotionType_oppositeEmotion_correctPairs() {
        XCTAssertEqual(EmotionType.joy.oppositeEmotion, .sadness)
        XCTAssertEqual(EmotionType.trust.oppositeEmotion, .disgust)
        XCTAssertEqual(EmotionType.fear.oppositeEmotion, .anger)
        XCTAssertEqual(EmotionType.surprise.oppositeEmotion, .anticipation)
    }

    func test_EmotionType_oppositeEmotion_neverSelf() {
        for emotion in EmotionType.allCases {
            XCTAssertNotEqual(emotion, emotion.oppositeEmotion, "\(emotion) is its own opposite")
        }
    }

    // MARK: - intensityLabels

    func test_EmotionType_intensityLabels_allThreeNonEmpty() {
        for emotion in EmotionType.allCases {
            let labels = emotion.intensityLabels
            XCTAssertFalse(labels.left.isEmpty, "\(emotion) left label is empty")
            XCTAssertFalse(labels.center.isEmpty, "\(emotion) center label is empty")
            XCTAssertFalse(labels.right.isEmpty, "\(emotion) right label is empty")
        }
    }

    func test_EmotionType_intensityLabels_labelsAreDistinct() {
        for emotion in EmotionType.allCases {
            let labels = emotion.intensityLabels
            let unique = Set([labels.left, labels.center, labels.right])
            XCTAssertEqual(unique.count, 3, "\(emotion) has duplicate intensity labels")
        }
    }

    // MARK: - Raw Values

    func test_EmotionType_rawValues_matchExpected() {
        XCTAssertEqual(EmotionType.joy.rawValue, "joy")
        XCTAssertEqual(EmotionType.sadness.rawValue, "sadness")
        XCTAssertEqual(EmotionType.anger.rawValue, "anger")
        XCTAssertEqual(EmotionType.fear.rawValue, "fear")
        XCTAssertEqual(EmotionType.trust.rawValue, "trust")
        XCTAssertEqual(EmotionType.disgust.rawValue, "disgust")
        XCTAssertEqual(EmotionType.anticipation.rawValue, "anticipation")
        XCTAssertEqual(EmotionType.surprise.rawValue, "surprise")
    }
}
