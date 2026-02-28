//
//  InnerCosmoPeriodTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class InnerCosmoPeriodTests: XCTestCase {

    // MARK: - CaseIterable

    func test_InnerCosmoPeriod_allCases_contains3Cases() {
        XCTAssertEqual(InnerCosmoPeriod.allCases.count, 3)
    }

    // MARK: - Raw Values

    func test_InnerCosmoPeriod_rawValues_matchExpected() {
        XCTAssertEqual(InnerCosmoPeriod.daily.rawValue, 0)
        XCTAssertEqual(InnerCosmoPeriod.weekly.rawValue, 1)
        XCTAssertEqual(InnerCosmoPeriod.monthly.rawValue, 2)
    }

    func test_InnerCosmoPeriod_initFromRawValue_success() {
        XCTAssertEqual(InnerCosmoPeriod(rawValue: 0), .daily)
        XCTAssertEqual(InnerCosmoPeriod(rawValue: 1), .weekly)
        XCTAssertEqual(InnerCosmoPeriod(rawValue: 2), .monthly)
    }

    func test_InnerCosmoPeriod_initFromRawValue_invalidReturnsNil() {
        XCTAssertNil(InnerCosmoPeriod(rawValue: 3))
        XCTAssertNil(InnerCosmoPeriod(rawValue: -1))
    }

    // MARK: - title

    func test_InnerCosmoPeriod_title_nonEmptyForAllCases() {
        for period in InnerCosmoPeriod.allCases {
            XCTAssertFalse(period.title.isEmpty, "\(period) has empty title")
        }
    }
}
