//
//  DrawingServiceTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingServiceTests: XCTestCase {

    // MARK: - Properties

    private var serviceMock: DrawingServiceMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        serviceMock = DrawingServiceMock()
    }

    override func tearDown() {
        serviceMock = nil
        super.tearDown()
    }

    // MARK: - submitDrawing

    func test_DrawingServiceMock_submitDrawing_returnsConfiguredId() {
        serviceMock.submitResult = .success("test-drawing-id")
        let exp = expectation(description: "completion called")

        var receivedId: String?
        serviceMock.submitDrawing(
            uid: "user1",
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        ) { result in
            if case .success(let id) = result {
                receivedId = id
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(receivedId, "test-drawing-id")
    }

    func test_DrawingServiceMock_submitDrawing_tracksCallCount() {
        serviceMock.submitDrawing(
            uid: "user1",
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        ) { _ in }

        serviceMock.submitDrawing(
            uid: "user2",
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        ) { _ in }

        // Call counts are incremented synchronously before dispatch
        XCTAssertEqual(serviceMock.submitCallCount, 2)
        XCTAssertEqual(serviceMock.lastSubmitUID, "user2")
    }

    func test_DrawingServiceMock_submitDrawingWithError_returnsError() {
        serviceMock.submitResult = .failure(TestError.mockError)
        let exp = expectation(description: "completion called")

        var receivedError: Error?
        serviceMock.submitDrawing(
            uid: "user1",
            image: UIImage(),
            recordingData: Data(),
            checkinId: nil,
            promptUsed: nil,
            templateName: nil
        ) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertNotNil(receivedError)
    }

    // MARK: - fetchDrawings by date

    func test_DrawingServiceMock_fetchByDate_returnsConfiguredModels() {
        let drawing = makeDrawing(id: "d1")
        serviceMock.fetchByDateResult = .success([drawing])
        let exp = expectation(description: "completion called")

        var receivedDrawings: [DrawingModel]?
        serviceMock.fetchDrawings(uid: "user1", from: Date(), to: nil) { result in
            if case .success(let drawings) = result {
                receivedDrawings = drawings
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(receivedDrawings?.count, 1)
        XCTAssertEqual(receivedDrawings?.first?.id, "d1")
    }

    func test_DrawingServiceMock_fetchByDateWithError_returnsError() {
        serviceMock.fetchByDateResult = .failure(TestError.mockError)
        let exp = expectation(description: "completion called")

        var receivedError: Error?
        serviceMock.fetchDrawings(uid: "user1", from: Date(), to: nil) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertNotNil(receivedError)
    }

    // MARK: - fetchDrawings by checkinId

    func test_DrawingServiceMock_fetchByCheckinId_tracksCallCount() {
        serviceMock.fetchDrawings(uid: "user1", checkinId: "c1") { _ in }

        XCTAssertEqual(serviceMock.fetchByCheckinCallCount, 1)
        XCTAssertEqual(serviceMock.lastFetchUID, "user1")
    }

    // MARK: - deleteDrawing

    func test_DrawingServiceMock_deleteDrawing_succeeds() {
        let exp = expectation(description: "completion called")

        var didSucceed = false
        serviceMock.deleteDrawing(uid: "user1", drawingId: "d1") { result in
            if case .success = result {
                didSucceed = true
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertTrue(didSucceed)
        XCTAssertEqual(serviceMock.deleteCallCount, 1)
        XCTAssertEqual(serviceMock.lastDeleteDrawingId, "d1")
    }

    // MARK: - Call counts tracked correctly

    func test_DrawingServiceMock_callCountsTrackedCorrectly() {
        XCTAssertEqual(serviceMock.submitCallCount, 0)
        XCTAssertEqual(serviceMock.fetchByDateCallCount, 0)
        XCTAssertEqual(serviceMock.fetchByCheckinCallCount, 0)
        XCTAssertEqual(serviceMock.deleteCallCount, 0)

        serviceMock.submitDrawing(
            uid: "u", image: UIImage(), recordingData: Data(),
            checkinId: nil, promptUsed: nil, templateName: nil
        ) { _ in }

        serviceMock.fetchDrawings(uid: "u", from: Date(), to: nil) { _ in }
        serviceMock.fetchDrawings(uid: "u", checkinId: "c") { _ in }
        serviceMock.deleteDrawing(uid: "u", drawingId: "d") { _ in }

        // Call counts are incremented synchronously before dispatch
        XCTAssertEqual(serviceMock.submitCallCount, 1)
        XCTAssertEqual(serviceMock.fetchByDateCallCount, 1)
        XCTAssertEqual(serviceMock.fetchByCheckinCallCount, 1)
        XCTAssertEqual(serviceMock.deleteCallCount, 1)
    }
}

// MARK: - Helpers

private extension DrawingServiceTests {

    enum TestError: Error {
        case mockError
    }

    func makeDrawing(id: String) -> DrawingModel {
        return DrawingModel(
            id: id,
            checkinId: nil,
            isFromCheckIn: false,
            imageURL: "https://example.com/\(id)/image.png",
            recordingURL: "https://example.com/\(id)/recording.pkd",
            timezoneOffsetMinutes: 480
        )
    }
}
