//
//  RedFlagsSectionViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class RedFlagsSectionViewModelTests: XCTestCase {
    func testIsValidWhenFirstFlagHasText() {
        let vm = RedFlagsSectionViewModel(redFlags: ["I isolate myself", ""])
        XCTAssertTrue(vm.isValid)
    }

    func testIsInvalidWhenFirstFlagEmpty() {
        let vm = RedFlagsSectionViewModel(redFlags: ["", "some text"])
        XCTAssertFalse(vm.isValid)
    }

    func testIsInvalidWhenFirstFlagWhitespaceOnly() {
        let vm = RedFlagsSectionViewModel(redFlags: ["   ", ""])
        XCTAssertFalse(vm.isValid)
    }

    func testHasContentWhenAnyFlagFilled() {
        let vm = RedFlagsSectionViewModel(redFlags: ["", "I stop answering"])
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentFalseWhenAllEmpty() {
        let vm = RedFlagsSectionViewModel(redFlags: ["", ""])
        XCTAssertFalse(vm.hasContent)
    }

    func testInitFromItems() {
        let items = [RedFlagItem(text: "flag2", sortOrder: 1), RedFlagItem(text: "flag1", sortOrder: 0)]
        let vm = RedFlagsSectionViewModel(from: items)
        XCTAssertEqual(vm.redFlags[0], "flag1")
        XCTAssertEqual(vm.redFlags[1], "flag2")
    }

    func testInitFromEmptyItemsPadsTwoSlots() {
        let vm = RedFlagsSectionViewModel(from: [])
        XCTAssertEqual(vm.redFlags.count, 2)
    }

    func testToSectionDataProducesCorrectItems() {
        let vm = RedFlagsSectionViewModel(redFlags: ["a", "b"])
        let data = vm.toSectionData()
        if case .redFlags(let items) = data {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0].text, "a")
            XCTAssertEqual(items[0].sortOrder, 0)
            XCTAssertEqual(items[1].text, "b")
            XCTAssertEqual(items[1].sortOrder, 1)
        } else {
            XCTFail("Expected .redFlags section data")
        }
    }
}
