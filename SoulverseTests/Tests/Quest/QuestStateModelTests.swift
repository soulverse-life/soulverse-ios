//
//  QuestStateModelTests.swift
//  SoulverseTests
//

import XCTest
import FirebaseFirestore
@testable import Soulverse

final class QuestStateModelTests: XCTestCase {

    func test_QuestStateModel_initialState_hasZeroDays() {
        let state = QuestStateModel.initial()
        XCTAssertEqual(state.distinctCheckInDays, 0)
        XCTAssertNil(state.focusDimension)
        XCTAssertTrue(state.pendingSurveys.isEmpty)
        XCTAssertNil(state.lastDistinctDayKey)
        XCTAssertNil(state.questCompletedAt)
    }

    func test_QuestStateModel_decodesFromFirestoreDictionary() throws {
        let data: [String: Any] = [
            "distinctCheckInDays": 5,
            "lastDistinctDayKey": "2026-04-29",
            "focusDimension": NSNull(),
            "pendingSurveys": [],
            "surveyEligibleSinceMap": [:],
            "notificationHour": 1,
            "timezoneOffsetMinutes": 480
        ]
        let state = QuestStateModel.fromDictionary(data)
        XCTAssertEqual(state.distinctCheckInDays, 5)
        XCTAssertEqual(state.lastDistinctDayKey, "2026-04-29")
        XCTAssertNil(state.focusDimension)
        XCTAssertEqual(state.notificationHour, 1)
    }
}
