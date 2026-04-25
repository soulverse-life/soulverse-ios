//
//  ProfessionalSupportSectionViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class ProfessionalSupportSectionViewModelTests: XCTestCase {
    func testHasContentWhenPlaceNameFilled() {
        let vm = ProfessionalSupportSectionViewModel(placeName: "City Hospital", crisisResource: nil)
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentWhenContactNameFilled() {
        let vm = ProfessionalSupportSectionViewModel(contactName: "Dr. Smith", crisisResource: nil)
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentWhenPhoneFilled() {
        let vm = ProfessionalSupportSectionViewModel(phone: "1-800-123", crisisResource: nil)
        XCTAssertTrue(vm.hasContent)
    }

    func testHasContentFalseWhenAllEmpty() {
        let vm = ProfessionalSupportSectionViewModel(crisisResource: nil)
        XCTAssertFalse(vm.hasContent)
    }

    func testHasContentFalseWhenWhitespaceOnly() {
        let vm = ProfessionalSupportSectionViewModel(placeName: "  ", contactName: "  ", phone: "  ", crisisResource: nil)
        XCTAssertFalse(vm.hasContent)
    }

    func testInitFromItems() {
        let items = [
            ProfessionalContact(placeName: "second", contactName: "b", phone: "2", sortOrder: 1),
            ProfessionalContact(placeName: "first", contactName: "a", phone: "1", sortOrder: 0)
        ]
        let vm = ProfessionalSupportSectionViewModel(from: items, crisisResource: nil)
        XCTAssertEqual(vm.placeName, "first")
        XCTAssertEqual(vm.contactName, "a")
        XCTAssertEqual(vm.phone, "1")
    }

    func testInitFromEmptyItems() {
        let vm = ProfessionalSupportSectionViewModel(from: [], crisisResource: nil)
        XCTAssertEqual(vm.placeName, "")
        XCTAssertEqual(vm.contactName, "")
        XCTAssertEqual(vm.phone, "")
    }

    func testInitFromItemsWithNilFields() {
        let items = [ProfessionalContact(sortOrder: 0)]
        let vm = ProfessionalSupportSectionViewModel(from: items, crisisResource: nil)
        XCTAssertEqual(vm.placeName, "")
        XCTAssertEqual(vm.contactName, "")
        XCTAssertEqual(vm.phone, "")
    }

    func testToSectionDataProducesCorrectItem() {
        let vm = ProfessionalSupportSectionViewModel(placeName: "Clinic", contactName: "Dr. X", phone: "555", crisisResource: nil)
        let data = vm.toSectionData()
        if case .professionalSupport(let items) = data {
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items[0].placeName, "Clinic")
            XCTAssertEqual(items[0].contactName, "Dr. X")
            XCTAssertEqual(items[0].phone, "555")
            XCTAssertEqual(items[0].sortOrder, 0)
        } else {
            XCTFail("Expected .professionalSupport section data")
        }
    }
}
