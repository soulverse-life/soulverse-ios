//
//  WeeklyMoodScoreViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class WeeklyMoodScoreViewModelTests: XCTestCase {

    // MARK: - TrendDirection Symbol

    func test_TrendDirection_symbol_up() {
        XCTAssertEqual(WeeklyMoodScoreViewModel.TrendDirection.up.symbol, "↑")
    }

    func test_TrendDirection_symbol_down() {
        XCTAssertEqual(WeeklyMoodScoreViewModel.TrendDirection.down.symbol, "↓")
    }

    func test_TrendDirection_symbol_neutral() {
        XCTAssertEqual(WeeklyMoodScoreViewModel.TrendDirection.neutral.symbol, "→")
    }

    // MARK: - mockData

    func test_WeeklyMoodScoreViewModel_mockData_returns7DailyScores() {
        let mock = WeeklyMoodScoreViewModel.mockData()
        XCTAssertEqual(mock.dailyScores.count, 7)
    }

    func test_WeeklyMoodScoreViewModel_mockData_trendIsUp() {
        let mock = WeeklyMoodScoreViewModel.mockData()
        XCTAssertEqual(mock.trendDirection, .up)
    }

    func test_WeeklyMoodScoreViewModel_mockData_trendValueIsPositive() {
        let mock = WeeklyMoodScoreViewModel.mockData()
        XCTAssertGreaterThan(mock.trendValue, 0)
    }

    func test_WeeklyMoodScoreViewModel_mockData_titleIsNonEmpty() {
        let mock = WeeklyMoodScoreViewModel.mockData()
        XCTAssertFalse(mock.title.isEmpty)
    }

    // MARK: - DailyMoodScore

    func test_DailyMoodScore_init_storesValues() {
        let date = Date()
        let score = DailyMoodScore(date: date, score: 0.5, colorHex: "FF0000")
        XCTAssertEqual(score.score, 0.5, accuracy: 0.001)
        XCTAssertEqual(score.colorHex, "FF0000")
    }
}
