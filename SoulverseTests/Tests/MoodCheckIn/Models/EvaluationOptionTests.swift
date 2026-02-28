//
//  EvaluationOptionTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class EvaluationOptionTests: XCTestCase {

    // MARK: - CaseIterable

    func test_EvaluationOption_allCases_contains5Cases() {
        XCTAssertEqual(EvaluationOption.allCases.count, 5)
    }

    // MARK: - displayName

    func test_EvaluationOption_displayName_nonEmptyForAllCases() {
        for option in EvaluationOption.allCases {
            XCTAssertFalse(option.displayName.isEmpty, "\(option) has empty displayName")
        }
    }

    // MARK: - Raw Values

    func test_EvaluationOption_rawValues_matchExpected() {
        XCTAssertEqual(EvaluationOption.acceptAsPartOfLife.rawValue, "acceptAsPartOfLife")
        XCTAssertEqual(EvaluationOption.letItBe.rawValue, "letItBe")
        XCTAssertEqual(EvaluationOption.tryToPushAway.rawValue, "tryToPushAway")
        XCTAssertEqual(EvaluationOption.resistOrFight.rawValue, "resistOrFight")
        XCTAssertEqual(EvaluationOption.feelUnsure.rawValue, "feelUnsure")
    }
}
