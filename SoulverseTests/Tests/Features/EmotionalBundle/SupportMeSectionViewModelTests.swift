//
//  SupportMeSectionViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class SupportMeSectionViewModelTests: XCTestCase {
    func testHasContentWhenNameFilled() {
        var vm = SupportMeSectionViewModel()
        vm.contacts[0].name = "Alice"
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentFalseWhenAllNamesEmpty() {
        let vm = SupportMeSectionViewModel()
        XCTAssertFalse(vm.hasContent)
    }

    func testHasContentIgnoresWhitespaceOnlyNames() {
        var vm = SupportMeSectionViewModel()
        vm.contacts[0].name = "   "
        XCTAssertFalse(vm.hasContent)
    }

    func testInitFromItemsSortsAndMaps() {
        let items = [
            SupportContact(name: "Bob", phone: "123", email: "b@b.com", relationship: "friend", sortOrder: 1),
            SupportContact(name: "Alice", phone: "456", email: "a@a.com", relationship: "sister", sortOrder: 0)
        ]
        let vm = SupportMeSectionViewModel(from: items)
        XCTAssertEqual(vm.contacts[0].name, "Alice")
        XCTAssertEqual(vm.contacts[0].phone, "456")
        XCTAssertEqual(vm.contacts[1].name, "Bob")
        XCTAssertEqual(vm.contacts[1].relationship, "friend")
    }

    func testInitFromEmptyItemsPadsTwoSlots() {
        let vm = SupportMeSectionViewModel(from: [])
        XCTAssertEqual(vm.contacts.count, 2)
        XCTAssertTrue(vm.contacts[0].name.isEmpty)
    }

    func testInitFromItemsHandlesNilOptionals() {
        let items = [SupportContact(name: "Alice", sortOrder: 0)]
        let vm = SupportMeSectionViewModel(from: items)
        XCTAssertEqual(vm.contacts[0].phone, "")
        XCTAssertEqual(vm.contacts[0].email, "")
        XCTAssertEqual(vm.contacts[0].relationship, "")
    }

    func testToSectionDataProducesCorrectItems() {
        var vm = SupportMeSectionViewModel()
        vm.contacts[0].name = "Alice"
        vm.contacts[0].phone = "123"
        let data = vm.toSectionData()
        if case .supportMe(let items) = data {
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items[0].name, "Alice")
            XCTAssertEqual(items[0].phone, "123")
            XCTAssertEqual(items[0].sortOrder, 0)
        } else {
            XCTFail("Expected .supportMe section data")
        }
    }
}
