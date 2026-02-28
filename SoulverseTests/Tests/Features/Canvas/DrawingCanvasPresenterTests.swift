//
//  DrawingCanvasPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingCanvasPresenterTests: XCTestCase {

    // MARK: - Properties

    private var delegateMock: DrawingCanvasPresenterDelegateMock!
    private var drawingServiceMock: DrawingServiceMock!
    private var userMock: UserMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        delegateMock = DrawingCanvasPresenterDelegateMock()
        drawingServiceMock = DrawingServiceMock()
        userMock = UserMock()
    }

    override func tearDown() {
        delegateMock = nil
        drawingServiceMock = nil
        userMock = nil
        super.tearDown()
    }

    // MARK: - submitDrawing with nil userId

    func test_DrawingCanvasPresenter_submitDrawingNilUserId_callsDidFailSavingDrawing() {
        userMock.userId = nil
        let presenter = makePresenter()

        presenter.submitDrawing(
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        )

        XCTAssertNotNil(delegateMock.didFailError)
    }

    // MARK: - submitDrawing with valid userId + mock success

    func test_DrawingCanvasPresenter_submitDrawingSuccess_callsDidFinishSavingDrawing() {
        let exp = expectation(description: "delegate receives finish callback")
        delegateMock.expectation = exp
        drawingServiceMock.submitResult = .success("mock-id")
        let presenter = makePresenter()

        presenter.submitDrawing(
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        )

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(delegateMock.didFinishImage)
    }

    // MARK: - submitDrawing with valid userId + mock failure

    func test_DrawingCanvasPresenter_submitDrawingFailure_callsDidFailSavingDrawing() {
        let exp = expectation(description: "delegate receives fail callback")
        delegateMock.expectation = exp
        drawingServiceMock.submitResult = .failure(TestError.mockError)
        let presenter = makePresenter()

        presenter.submitDrawing(
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        )

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(delegateMock.didFailError)
    }

    // MARK: - submitDrawing calls didStartSavingDrawing

    func test_DrawingCanvasPresenter_submitDrawing_callsDidStartSavingDrawing() {
        let presenter = makePresenter()

        presenter.submitDrawing(
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        )

        XCTAssertTrue(delegateMock.didStartSaving)
    }

    // MARK: - submitDrawing calls service exactly once

    func test_DrawingCanvasPresenter_submitDrawingOnce_serviceCalledOnce() {
        let presenter = makePresenter()

        presenter.submitDrawing(
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        )

        // submitCallCount is incremented synchronously in the mock before dispatch
        XCTAssertEqual(drawingServiceMock.submitCallCount, 1)
    }
}

// MARK: - Helpers

private extension DrawingCanvasPresenterTests {

    enum TestError: Error {
        case mockError
    }

    func makePresenter() -> DrawingCanvasPresenter {
        let presenter = DrawingCanvasPresenter(
            user: userMock,
            drawingService: drawingServiceMock
        )
        presenter.delegate = delegateMock
        return presenter
    }
}
