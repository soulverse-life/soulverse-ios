//
//  ToolsViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class ToolsViewModelTests: XCTestCase {

    // MARK: - Default Init

    func test_ToolsViewModel_defaultInit_isNotLoading() {
        let vm = ToolsViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    func test_ToolsViewModel_defaultInit_hasZeroSections() {
        let vm = ToolsViewModel()
        XCTAssertEqual(vm.numberOfSections(), 0)
    }

    func test_ToolsViewModel_defaultInit_healingTitleNonEmpty() {
        let vm = ToolsViewModel()
        XCTAssertFalse(vm.healingTitle.isEmpty)
    }

    func test_ToolsViewModel_defaultInit_healingDescriptionNonEmpty() {
        let vm = ToolsViewModel()
        XCTAssertFalse(vm.healingDescription.isEmpty)
    }

    // MARK: - numberOfSections

    func test_ToolsViewModel_numberOfSections_matchesSectionsCount() {
        let vm = makeViewModel(sectionCounts: [2, 3])
        XCTAssertEqual(vm.numberOfSections(), 2)
    }

    // MARK: - numberOfItems

    func test_ToolsViewModel_numberOfItems_validSection_returnsCorrectCount() {
        let vm = makeViewModel(sectionCounts: [2, 3])
        XCTAssertEqual(vm.numberOfItems(in: 0), 2)
        XCTAssertEqual(vm.numberOfItems(in: 1), 3)
    }

    func test_ToolsViewModel_numberOfItems_outOfBoundsSection_returnsZero() {
        let vm = makeViewModel(sectionCounts: [2])
        XCTAssertEqual(vm.numberOfItems(in: 5), 0)
    }

    // MARK: - item(at:)

    func test_ToolsViewModel_itemAt_validIndexPath_returnsItem() {
        let vm = makeViewModel(sectionCounts: [2, 3])
        let item = vm.item(at: IndexPath(item: 1, section: 0))
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.title, "Tool 0-1")
    }

    func test_ToolsViewModel_itemAt_outOfBoundsSection_returnsNil() {
        let vm = makeViewModel(sectionCounts: [2])
        XCTAssertNil(vm.item(at: IndexPath(item: 0, section: 5)))
    }

    func test_ToolsViewModel_itemAt_outOfBoundsItem_returnsNil() {
        let vm = makeViewModel(sectionCounts: [2])
        XCTAssertNil(vm.item(at: IndexPath(item: 10, section: 0)))
    }

    // MARK: - titleForSection

    func test_ToolsViewModel_titleForSection_validSection_returnsTitle() {
        let vm = makeViewModel(sectionCounts: [1])
        XCTAssertEqual(vm.titleForSection(0), "Section 0")
    }

    func test_ToolsViewModel_titleForSection_outOfBounds_returnsNil() {
        let vm = makeViewModel(sectionCounts: [1])
        XCTAssertNil(vm.titleForSection(5))
    }

    // MARK: - isLoading

    func test_ToolsViewModel_isLoading_canBeSetToTrue() {
        let vm = ToolsViewModel(isLoading: true)
        XCTAssertTrue(vm.isLoading)
    }
}

// MARK: - Helpers

private extension ToolsViewModelTests {
    func makeViewModel(sectionCounts: [Int]) -> ToolsViewModel {
        let sections = sectionCounts.enumerated().map { sectionIndex, itemCount in
            let items = (0..<itemCount).map { itemIndex in
                ToolsCellViewModel(
                    iconName: "icon_\(sectionIndex)_\(itemIndex)",
                    title: "Tool \(sectionIndex)-\(itemIndex)",
                    description: "Description",
                    action: .comingSoon
                )
            }
            return ToolsSectionViewModel(title: "Section \(sectionIndex)", items: items)
        }
        return ToolsViewModel(sections: sections)
    }
}
