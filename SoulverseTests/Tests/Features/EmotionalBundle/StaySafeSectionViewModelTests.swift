//
//  StaySafeSectionViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class StaySafeSectionViewModelTests: XCTestCase {
    func testHasContentWhenActionFilled() {
        let vm = StaySafeSectionViewModel(action: "Remove sharp objects")
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentFalseWhenEmpty() {
        let vm = StaySafeSectionViewModel()
        XCTAssertFalse(vm.hasContent)
    }

    func testHasContentFalseWhenWhitespaceOnly() {
        let vm = StaySafeSectionViewModel(action: "   ")
        XCTAssertFalse(vm.hasContent)
    }

    func testInitFromItems() {
        let items = [
            SafetyAction(text: "second", sortOrder: 1),
            SafetyAction(text: "first", sortOrder: 0)
        ]
        let vm = StaySafeSectionViewModel(from: items)
        XCTAssertEqual(vm.action, "first")
    }

    func testInitFromEmptyItems() {
        let vm = StaySafeSectionViewModel(from: [])
        XCTAssertEqual(vm.action, "")
    }

    func testToSectionDataProducesCorrectItem() {
        let vm = StaySafeSectionViewModel(action: "Lock medicine cabinet")
        let data = vm.toSectionData()
        if case .staySafe(let items) = data {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items[0].text, "Lock medicine cabinet")
            XCTAssertEqual(items[0].sortOrder, 0)
        } else {
            XCTFail("Expected .staySafe section data")
        }
    }
}
