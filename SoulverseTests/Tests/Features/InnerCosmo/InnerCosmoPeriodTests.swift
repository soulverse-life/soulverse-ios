//
//  InnerCosmoPeriodTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class InnerCosmoPeriodTests: XCTestCase {

    // MARK: - CaseIterable

    func test_InnerCosmoPeriod_allCases_contains2Cases() {
        XCTAssertEqual(InnerCosmoPeriod.allCases.count, 2)
    }

    // MARK: - Raw Values

    func test_InnerCosmoPeriod_rawValues_matchExpected() {
        XCTAssertEqual(InnerCosmoPeriod.recent.rawValue, 0)
        XCTAssertEqual(InnerCosmoPeriod.all.rawValue, 1)
    }

    func test_InnerCosmoPeriod_initFromRawValue_success() {
        XCTAssertEqual(InnerCosmoPeriod(rawValue: 0), .recent)
        XCTAssertEqual(InnerCosmoPeriod(rawValue: 1), .all)
    }

    func test_InnerCosmoPeriod_initFromRawValue_invalidReturnsNil() {
        XCTAssertNil(InnerCosmoPeriod(rawValue: 2))
        XCTAssertNil(InnerCosmoPeriod(rawValue: -1))
    }

    // MARK: - title

    func test_InnerCosmoPeriod_title_nonEmptyForAllCases() {
        for period in InnerCosmoPeriod.allCases {
            XCTAssertFalse(period.title.isEmpty, "\(period) has empty title")
        }
    }
}
