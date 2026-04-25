//
//  FeelCalmSectionViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class FeelCalmSectionViewModelTests: XCTestCase {
    func testIsValidWhenFirstActivityHasText() {
        let vm = FeelCalmSectionViewModel(activities: ["Deep breathing", "", ""])
        XCTAssertTrue(vm.isValid)
    }

    func testIsInvalidWhenFirstActivityEmpty() {
        let vm = FeelCalmSectionViewModel(activities: ["", "Walk", ""])
        XCTAssertFalse(vm.isValid)
    }

    func testIsInvalidWhenFirstActivityWhitespaceOnly() {
        let vm = FeelCalmSectionViewModel(activities: ["  ", "", ""])
        XCTAssertFalse(vm.isValid)
    }

    func testHasContentWhenAnyActivityFilled() {
        let vm = FeelCalmSectionViewModel(activities: ["", "", "Music"])
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentFalseWhenAllEmpty() {
        let vm = FeelCalmSectionViewModel(activities: ["", "", ""])
        XCTAssertFalse(vm.hasContent)
    }

    func testInitFromItemsSortsCorrectly() {
        let items = [
            CalmActivity(text: "third", sortOrder: 2),
            CalmActivity(text: "first", sortOrder: 0),
            CalmActivity(text: "second", sortOrder: 1)
        ]
        let vm = FeelCalmSectionViewModel(from: items)
        XCTAssertEqual(vm.activities[0], "first")
        XCTAssertEqual(vm.activities[1], "second")
        XCTAssertEqual(vm.activities[2], "third")
    }

    func testInitFromEmptyItemsPadsThreeSlots() {
        let vm = FeelCalmSectionViewModel(from: [])
        XCTAssertEqual(vm.activities.count, 3)
    }

    func testInitFromOneItemPadsToThree() {
        let items = [CalmActivity(text: "Walk", sortOrder: 0)]
        let vm = FeelCalmSectionViewModel(from: items)
        XCTAssertEqual(vm.activities.count, 3)
        XCTAssertEqual(vm.activities[0], "Walk")
        XCTAssertEqual(vm.activities[1], "")
    }

    func testToSectionDataProducesCorrectItems() {
        let vm = FeelCalmSectionViewModel(activities: ["a", "b", "c"])
        let data = vm.toSectionData()
        if case .feelCalm(let items) = data {
            XCTAssertEqual(items.count, 3)
            XCTAssertEqual(items[0].text, "a")
            XCTAssertEqual(items[2].sortOrder, 2)
        } else {
            XCTFail("Expected .feelCalm section data")
        }
    }
}
