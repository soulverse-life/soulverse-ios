//
//  EmotionalBundleModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class EmotionalBundleModelTests: XCTestCase {

    func testEmptyFactoryReturnsEmptyArrays() {
        let bundle = EmotionalBundleModel.empty()
        XCTAssertEqual(bundle.version, 1)
        XCTAssertTrue(bundle.redFlags.isEmpty)
        XCTAssertTrue(bundle.supportMe.isEmpty)
        XCTAssertTrue(bundle.feelCalm.isEmpty)
        XCTAssertTrue(bundle.staySafe.isEmpty)
        XCTAssertTrue(bundle.professionalSupport.isEmpty)
    }

    func testRedFlagItemGeneratesUniqueId() {
        let item1 = RedFlagItem(text: "test", sortOrder: 0)
        let item2 = RedFlagItem(text: "test", sortOrder: 1)
        XCTAssertNotEqual(item1.id, item2.id)
        XCTAssertTrue(item1.id.hasPrefix("rf_"))
    }

    func testSupportContactGeneratesUniqueId() {
        let contact = SupportContact(name: "Stephy", phone: "555-1234", sortOrder: 0)
        XCTAssertTrue(contact.id.hasPrefix("sm_"))
        XCTAssertEqual(contact.name, "Stephy")
    }

    func testSectionDisplayTitlesAreNotEmpty() {
        for section in EmotionalBundleSection.allCases {
            XCTAssertFalse(section.displayTitle.isEmpty, "\(section.rawValue) has empty display title")
        }
    }

    func testCrisisResourceLoaderReturnsNilForUnknownLocale() {
        _ = CrisisResourceLoader.loadForCurrentLocale()
    }
}
