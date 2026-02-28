//
//  TopicTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class TopicTests: XCTestCase {

    // MARK: - CaseIterable

    func test_Topic_allCases_contains8Cases() {
        XCTAssertEqual(Topic.allCases.count, 8)
    }

    // MARK: - localizedTitle

    func test_Topic_localizedTitle_nonEmptyForAllCases() {
        for topic in Topic.allCases {
            XCTAssertFalse(topic.localizedTitle.isEmpty, "\(topic) has empty localizedTitle")
        }
    }

    // MARK: - iconImage

    func test_Topic_iconImage_nonEmptyForAllCases() {
        for topic in Topic.allCases {
            // UIImage() creates a valid but empty image; system symbols return a non-empty image
            XCTAssertNotNil(topic.iconImage, "\(topic) has nil iconImage")
            XCTAssertGreaterThan(topic.iconImage.size.width, 0, "\(topic) iconImage has zero width")
        }
    }

    // MARK: - mainColor

    func test_Topic_mainColor_nonNilForAllCases() {
        for topic in Topic.allCases {
            // Verify color components are extractable (not a pattern color)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            let success = topic.mainColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            XCTAssertTrue(success, "\(topic) mainColor cannot extract RGB components")
            XCTAssertEqual(a, 1.0, accuracy: 0.01, "\(topic) mainColor alpha is not 1.0")
        }
    }

    // MARK: - Raw Values

    func test_Topic_rawValues_matchExpected() {
        XCTAssertEqual(Topic.physical.rawValue, "physical")
        XCTAssertEqual(Topic.emotional.rawValue, "emotional")
        XCTAssertEqual(Topic.social.rawValue, "social")
        XCTAssertEqual(Topic.intellectual.rawValue, "intellectual")
        XCTAssertEqual(Topic.spiritual.rawValue, "spiritual")
        XCTAssertEqual(Topic.occupational.rawValue, "occupational")
        XCTAssertEqual(Topic.environment.rawValue, "environment")
        XCTAssertEqual(Topic.financial.rawValue, "financial")
    }
}
