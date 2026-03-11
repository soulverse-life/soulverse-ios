//
//  WeeklyMoodScoreViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class WeeklyMoodScoreViewModelTests: XCTestCase {

    // MARK: - mockData

    func test_WeeklyMoodScoreViewModel_mockData_returns7DailyScores() {
        let mock = WeeklyMoodScoreViewModel.mockData()
        XCTAssertEqual(mock.dailyScores.count, 7)
    }

    func test_WeeklyMoodScoreViewModel_mockData_titleIsNonEmpty() {
        let mock = WeeklyMoodScoreViewModel.mockData()
        XCTAssertFalse(mock.title.isEmpty)
    }

    // MARK: - DailyMoodScore

    func test_DailyMoodScore_init_storesEntries() {
        let date = Date()
        let entry = MoodCheckInEntry(time: date, score: 0.5, colorHex: "FF0000")
        let score = DailyMoodScore(date: date, entries: [entry])
        XCTAssertEqual(score.entries.count, 1)
        XCTAssertEqual(score.entries.first?.score ?? 0, 0.5, accuracy: 0.001)
        XCTAssertEqual(score.entries.first?.colorHex, "FF0000")
    }
}
