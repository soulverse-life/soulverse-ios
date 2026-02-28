//
//  DrawingGalleryPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingGalleryPresenterTests: XCTestCase {

    // MARK: - Properties

    private var delegateMock: DrawingGalleryPresenterDelegateMock!
    private var drawingServiceMock: DrawingServiceMock!
    private var userMock: UserMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        delegateMock = DrawingGalleryPresenterDelegateMock()
        drawingServiceMock = DrawingServiceMock()
        userMock = UserMock()
    }

    override func tearDown() {
        delegateMock = nil
        drawingServiceMock = nil
        userMock = nil
        super.tearDown()
    }

    // MARK: - fetchDrawings with nil userId

    func test_DrawingGalleryPresenter_fetchDrawingsNilUserId_receivesEmptyViewModel() {
        userMock.userId = nil
        let presenter = makePresenter()

        presenter.fetchDrawings()

        XCTAssertNotNil(delegateMock.updatedViewModel)
        XCTAssertTrue(delegateMock.updatedViewModel?.isEmpty == true)
    }

    // MARK: - fetchDrawings with valid userId + empty drawings

    func test_DrawingGalleryPresenter_fetchDrawingsEmptyResult_receivesEmptySections() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp
        drawingServiceMock.fetchByDateResult = .success([])
        let presenter = makePresenter()

        presenter.fetchDrawings()

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(delegateMock.updatedViewModel)
        XCTAssertTrue(delegateMock.updatedViewModel?.sections.isEmpty == true)
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    // MARK: - fetchDrawings with valid userId + mock failure

    func test_DrawingGalleryPresenter_fetchDrawingsFailure_receivesErrorMessage() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp
        drawingServiceMock.fetchByDateResult = .failure(TestError.mockError)
        let presenter = makePresenter()

        presenter.fetchDrawings()

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(delegateMock.updatedViewModel?.errorMessage)
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    // MARK: - fetchDrawings sets isLoading initially

    func test_DrawingGalleryPresenter_fetchDrawings_setsIsLoadingTrue() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp
        let presenter = makePresenter()

        presenter.fetchDrawings()

        // The first delegate update (before async completion) sets isLoading = true
        XCTAssertGreaterThanOrEqual(delegateMock.updateCount, 1)

        wait(for: [exp], timeout: 0.1)

        // After completion, isLoading is false
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }
}

// MARK: - Helpers

private extension DrawingGalleryPresenterTests {

    enum TestError: Error, LocalizedError {
        case mockError

        var errorDescription: String? {
            return "Mock error"
        }
    }

    func makePresenter() -> DrawingGalleryPresenter {
        let presenter = DrawingGalleryPresenter(
            user: userMock,
            drawingService: drawingServiceMock
        )
        presenter.delegate = delegateMock
        return presenter
    }
}
