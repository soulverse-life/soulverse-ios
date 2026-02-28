//
//  DrawingGalleryViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingGalleryViewModelTests: XCTestCase {

    // MARK: - Default Init

    func test_DrawingGalleryViewModel_defaultInit_isNotLoading() {
        let vm = DrawingGalleryViewModel()
        XCTAssertFalse(vm.isLoading)
    }

    func test_DrawingGalleryViewModel_defaultInit_isEmpty() {
        let vm = DrawingGalleryViewModel()
        XCTAssertTrue(vm.isEmpty)
    }

    func test_DrawingGalleryViewModel_defaultInit_noErrorMessage() {
        let vm = DrawingGalleryViewModel()
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - isEmpty

    func test_DrawingGalleryViewModel_isEmpty_falseWhenHasSections() {
        let vm = makeViewModel(sectionCounts: [1])
        XCTAssertFalse(vm.isEmpty)
    }

    // MARK: - numberOfSections

    func test_DrawingGalleryViewModel_numberOfSections_matchesSectionsCount() {
        let vm = makeViewModel(sectionCounts: [2, 3])
        XCTAssertEqual(vm.numberOfSections(), 2)
    }

    // MARK: - numberOfItems

    func test_DrawingGalleryViewModel_numberOfItems_validSection_returnsCorrectCount() {
        let vm = makeViewModel(sectionCounts: [2, 3])
        XCTAssertEqual(vm.numberOfItems(in: 0), 2)
        XCTAssertEqual(vm.numberOfItems(in: 1), 3)
    }

    func test_DrawingGalleryViewModel_numberOfItems_outOfBoundsSection_returnsZero() {
        let vm = makeViewModel(sectionCounts: [2])
        XCTAssertEqual(vm.numberOfItems(in: 5), 0)
    }

    // MARK: - drawing(at:)

    func test_DrawingGalleryViewModel_drawingAt_validIndexPath_returnsDrawing() {
        let vm = makeViewModel(sectionCounts: [2])
        let drawing = vm.drawing(at: IndexPath(item: 0, section: 0))
        XCTAssertNotNil(drawing)
    }

    func test_DrawingGalleryViewModel_drawingAt_outOfBoundsSection_returnsNil() {
        let vm = makeViewModel(sectionCounts: [2])
        XCTAssertNil(vm.drawing(at: IndexPath(item: 0, section: 5)))
    }

    func test_DrawingGalleryViewModel_drawingAt_outOfBoundsItem_returnsNil() {
        let vm = makeViewModel(sectionCounts: [2])
        XCTAssertNil(vm.drawing(at: IndexPath(item: 10, section: 0)))
    }

    // MARK: - titleForSection

    func test_DrawingGalleryViewModel_titleForSection_validSection_returnsTitle() {
        let vm = makeViewModel(sectionCounts: [1])
        XCTAssertEqual(vm.titleForSection(0), "Feb 20")
    }

    func test_DrawingGalleryViewModel_titleForSection_outOfBounds_returnsNil() {
        let vm = makeViewModel(sectionCounts: [1])
        XCTAssertNil(vm.titleForSection(5))
    }

    // MARK: - errorMessage

    func test_DrawingGalleryViewModel_withErrorMessage_storesError() {
        let vm = DrawingGalleryViewModel(errorMessage: "Something went wrong")
        XCTAssertEqual(vm.errorMessage, "Something went wrong")
    }

    // MARK: - isLoading

    func test_DrawingGalleryViewModel_isLoading_canBeSetToTrue() {
        let vm = DrawingGalleryViewModel(isLoading: true)
        XCTAssertTrue(vm.isLoading)
    }
}

// MARK: - Helpers

private extension DrawingGalleryViewModelTests {
    func makeDrawing(id: String) -> DrawingModel {
        return DrawingModel(
            checkinId: nil,
            isFromCheckIn: false,
            imageURL: "https://example.com/\(id)/image.png",
            recordingURL: "https://example.com/\(id)/recording.pkd",
            timezoneOffsetMinutes: 480
        )
    }

    func makeViewModel(sectionCounts: [Int]) -> DrawingGalleryViewModel {
        let sections = sectionCounts.enumerated().map { sectionIndex, drawingCount in
            let drawings = (0..<drawingCount).map { i in
                makeDrawing(id: "d\(sectionIndex)-\(i)")
            }
            return DrawingGallerySectionViewModel(title: "Feb 20", drawings: drawings)
        }
        return DrawingGalleryViewModel(sections: sections)
    }
}
