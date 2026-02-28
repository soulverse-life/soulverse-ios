//
//  PromptOptionTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class PromptOptionTests: XCTestCase {

    // MARK: - CaseIterable

    func test_PromptOption_allCases_contains6Cases() {
        XCTAssertEqual(PromptOption.allCases.count, 6)
    }

    // MARK: - displayName

    func test_PromptOption_displayName_nonEmptyForAllCases() {
        for option in PromptOption.allCases {
            XCTAssertFalse(option.displayName.isEmpty, "\(option) has empty displayName")
        }
    }

    // MARK: - placeholderText

    func test_PromptOption_placeholderText_nonEmptyForAllCases() {
        for option in PromptOption.allCases {
            XCTAssertFalse(option.placeholderText.isEmpty, "\(option) has empty placeholderText")
        }
    }

    // MARK: - displayName and placeholderText are distinct

    func test_PromptOption_displayNameAndPlaceholder_areDistinct() {
        for option in PromptOption.allCases {
            XCTAssertNotEqual(
                option.displayName, option.placeholderText,
                "\(option) displayName equals placeholderText"
            )
        }
    }
}
