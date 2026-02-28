//
//  MoodCheckInDataTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class MoodCheckInDataTests: XCTestCase {

    // MARK: - Default State

    func test_MoodCheckInData_default_isNotComplete() {
        let data = MoodCheckInData()
        XCTAssertFalse(data.isComplete)
    }

    // MARK: - isSensingComplete

    func test_MoodCheckInData_isSensingComplete_falseWhenNoColor() {
        let data = MoodCheckInData()
        XCTAssertFalse(data.isSensingComplete)
    }

    func test_MoodCheckInData_isSensingComplete_trueWhenColorSet() {
        var data = MoodCheckInData()
        data.selectedColor = .red
        XCTAssertTrue(data.isSensingComplete)
    }

    // MARK: - isNamingComplete

    func test_MoodCheckInData_isNamingComplete_falseWhenNoEmotion() {
        let data = MoodCheckInData()
        XCTAssertFalse(data.isNamingComplete)
    }

    func test_MoodCheckInData_isNamingComplete_trueWhenEmotionSet() {
        var data = MoodCheckInData()
        data.recordedEmotion = .joy
        XCTAssertTrue(data.isNamingComplete)
    }

    // MARK: - isShapingComplete

    func test_MoodCheckInData_isShapingComplete_alwaysTrue() {
        let data = MoodCheckInData()
        XCTAssertTrue(data.isShapingComplete)
    }

    // MARK: - isAttributingComplete

    func test_MoodCheckInData_isAttributingComplete_falseWhenNoTopic() {
        let data = MoodCheckInData()
        XCTAssertFalse(data.isAttributingComplete)
    }

    func test_MoodCheckInData_isAttributingComplete_trueWhenTopicSet() {
        var data = MoodCheckInData()
        data.selectedTopic = .emotional
        XCTAssertTrue(data.isAttributingComplete)
    }

    // MARK: - isEvaluatingComplete

    func test_MoodCheckInData_isEvaluatingComplete_falseWhenNoEvaluation() {
        let data = MoodCheckInData()
        XCTAssertFalse(data.isEvaluatingComplete)
    }

    func test_MoodCheckInData_isEvaluatingComplete_trueWhenEvaluationSet() {
        var data = MoodCheckInData()
        data.evaluation = .letItBe
        XCTAssertTrue(data.isEvaluatingComplete)
    }

    // MARK: - isComplete

    func test_MoodCheckInData_isComplete_trueWhenAllFieldsSet() {
        var data = MoodCheckInData()
        data.selectedColor = .blue
        data.recordedEmotion = .optimism
        data.selectedTopic = .social
        data.evaluation = .acceptAsPartOfLife
        XCTAssertTrue(data.isComplete)
    }

    func test_MoodCheckInData_isComplete_falseWhenMissingColor() {
        var data = makeCompleteData()
        data.selectedColor = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_MoodCheckInData_isComplete_falseWhenMissingEmotion() {
        var data = makeCompleteData()
        data.recordedEmotion = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_MoodCheckInData_isComplete_falseWhenMissingTopic() {
        var data = makeCompleteData()
        data.selectedTopic = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_MoodCheckInData_isComplete_falseWhenMissingEvaluation() {
        var data = makeCompleteData()
        data.evaluation = nil
        XCTAssertFalse(data.isComplete)
    }

    // MARK: - colorHexString

    func test_MoodCheckInData_colorHexString_nilWhenNoColor() {
        let data = MoodCheckInData()
        XCTAssertNil(data.colorHexString)
    }

    func test_MoodCheckInData_colorHexString_redColor() {
        var data = MoodCheckInData()
        data.selectedColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(data.colorHexString, "#FF0000")
    }

    func test_MoodCheckInData_colorHexString_blackColor() {
        var data = MoodCheckInData()
        data.selectedColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        XCTAssertEqual(data.colorHexString, "#000000")
    }

    func test_MoodCheckInData_colorHexString_whiteColor() {
        var data = MoodCheckInData()
        data.selectedColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        XCTAssertEqual(data.colorHexString, "#FFFFFF")
    }

    // MARK: - colorIntensity Default

    func test_MoodCheckInData_colorIntensity_defaultIs0point5() {
        let data = MoodCheckInData()
        XCTAssertEqual(data.colorIntensity, 0.5, accuracy: 0.001)
    }
}

// MARK: - Helpers

private extension MoodCheckInDataTests {
    func makeCompleteData() -> MoodCheckInData {
        var data = MoodCheckInData()
        data.selectedColor = .blue
        data.recordedEmotion = .joy
        data.selectedTopic = .emotional
        data.evaluation = .letItBe
        return data
    }
}
