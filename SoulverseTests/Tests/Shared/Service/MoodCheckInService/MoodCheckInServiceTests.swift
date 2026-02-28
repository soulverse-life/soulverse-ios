//
//  MoodCheckInServiceTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class MoodCheckInServiceTests: XCTestCase {

    // MARK: - Properties

    private var serviceMock: MoodCheckInServiceMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        serviceMock = MoodCheckInServiceMock()
    }

    override func tearDown() {
        serviceMock = nil
        super.tearDown()
    }

    // MARK: - submitMoodCheckIn

    func test_MoodCheckInServiceMock_submitMoodCheckIn_returnsConfiguredId() {
        serviceMock.submitResult = .success("test-checkin-id")
        let exp = expectation(description: "completion called")

        var receivedId: String?
        serviceMock.submitMoodCheckIn(uid: "user1", data: makeCheckInData()) { result in
            if case .success(let id) = result {
                receivedId = id
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(receivedId, "test-checkin-id")
        XCTAssertEqual(serviceMock.submitCallCount, 1)
        XCTAssertEqual(serviceMock.lastSubmitUID, "user1")
    }

    // MARK: - fetchLatestCheckIns

    func test_MoodCheckInServiceMock_fetchLatest_returnsConfiguredModels() {
        let checkIn = makeCheckIn(id: "c1", createdAt: Date())
        serviceMock.fetchLatestResult = .success([checkIn])
        let exp = expectation(description: "completion called")

        var receivedCheckIns: [MoodCheckInModel]?
        serviceMock.fetchLatestCheckIns(uid: "user1", limit: 10) { result in
            if case .success(let checkIns) = result {
                receivedCheckIns = checkIns
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(receivedCheckIns?.count, 1)
        XCTAssertEqual(receivedCheckIns?.first?.id, "c1")
        XCTAssertEqual(serviceMock.fetchLatestCallCount, 1)
    }

    // MARK: - deleteCheckIn

    func test_MoodCheckInServiceMock_deleteCheckIn_succeeds() {
        let exp = expectation(description: "completion called")

        var didSucceed = false
        serviceMock.deleteCheckIn(uid: "user1", checkinId: "c1") { result in
            if case .success = result {
                didSucceed = true
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertTrue(didSucceed)
        XCTAssertEqual(serviceMock.deleteCallCount, 1)
        XCTAssertEqual(serviceMock.lastDeleteCheckinId, "c1")
    }

    // MARK: - Error Propagation

    func test_MoodCheckInServiceMock_submitWithError_returnsError() {
        serviceMock.submitResult = .failure(TestError.mockError)
        let exp = expectation(description: "completion called")

        var receivedError: Error?
        serviceMock.submitMoodCheckIn(uid: "user1", data: makeCheckInData()) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertNotNil(receivedError)
    }

    func test_MoodCheckInServiceMock_fetchLatestWithError_returnsError() {
        serviceMock.fetchLatestResult = .failure(TestError.mockError)
        let exp = expectation(description: "completion called")

        var receivedError: Error?
        serviceMock.fetchLatestCheckIns(uid: "user1", limit: 10) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)
        XCTAssertNotNil(receivedError)
    }

    // MARK: - Call Counts Tracked

    func test_MoodCheckInServiceMock_callCountsTrackedCorrectly() {
        XCTAssertEqual(serviceMock.submitCallCount, 0)
        XCTAssertEqual(serviceMock.fetchLatestCallCount, 0)
        XCTAssertEqual(serviceMock.fetchByDateCallCount, 0)
        XCTAssertEqual(serviceMock.deleteCallCount, 0)

        serviceMock.submitMoodCheckIn(uid: "u", data: makeCheckInData()) { _ in }
        serviceMock.fetchLatestCheckIns(uid: "u", limit: 5) { _ in }
        serviceMock.fetchCheckIns(uid: "u", from: Date(), to: Date()) { _ in }
        serviceMock.deleteCheckIn(uid: "u", checkinId: "c") { _ in }

        // Call counts are incremented synchronously before dispatch
        XCTAssertEqual(serviceMock.submitCallCount, 1)
        XCTAssertEqual(serviceMock.fetchLatestCallCount, 1)
        XCTAssertEqual(serviceMock.fetchByDateCallCount, 1)
        XCTAssertEqual(serviceMock.deleteCallCount, 1)
    }
}

// MARK: - Helpers

private extension MoodCheckInServiceTests {

    enum TestError: Error {
        case mockError
    }

    func makeCheckInData() -> MoodCheckInData {
        return MoodCheckInData()
    }

    func makeCheckIn(id: String, createdAt: Date?) -> MoodCheckInModel {
        return MoodCheckInModel(
            id: id,
            colorHex: "#FF5733",
            colorIntensity: 0.8,
            emotion: "happy",
            topic: "work",
            evaluation: "positive",
            journal: nil,
            timezoneOffsetMinutes: 480,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}
