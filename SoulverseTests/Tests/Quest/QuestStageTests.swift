//
//  QuestStageTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestStageTests: XCTestCase {

    func test_QuestStage_zeroDays_isStage1() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 0), .stage1)
    }

    func test_QuestStage_day1to7_isStage1() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 1), .stage1)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 6), .stage1)
    }

    func test_QuestStage_day7to13_isStage2() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 7), .stage2)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 13), .stage2)
    }

    func test_QuestStage_day14to20_isStage3() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 14), .stage3)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 20), .stage3)
    }

    func test_QuestStage_day21orMore_isCompleted() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 21), .completed)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 50), .completed)
    }

    func test_QuestStage_dotRange_stage1_isOneToSeven() {
        XCTAssertEqual(QuestStage.stage1.dotRange, 1...7)
    }

    func test_QuestStage_dotRange_stage2_isEightToFourteen() {
        XCTAssertEqual(QuestStage.stage2.dotRange, 8...14)
    }

    func test_QuestStage_dotRange_stage3_isFifteenToTwentyOne() {
        XCTAssertEqual(QuestStage.stage3.dotRange, 15...21)
    }
}
