//
//  MoodEntriesDataAssemblerFetchTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class MoodEntriesDataAssemblerFetchTests: XCTestCase {

    // MARK: - Properties

    private var userMock: UserMock!
    private var moodCheckInServiceMock: MoodCheckInServiceMock!
    private var drawingServiceMock: DrawingServiceMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        moodCheckInServiceMock = MoodCheckInServiceMock()
        drawingServiceMock = DrawingServiceMock()
    }

    override func tearDown() {
        userMock = nil
        moodCheckInServiceMock = nil
        drawingServiceMock = nil
        super.tearDown()
    }

    // MARK: - fetchInitial with empty check-ins

    func test_MoodEntriesDataAssembler_fetchInitialEmptyCheckIns_fetchesOrphanDrawings() {
        moodCheckInServiceMock.fetchLatestResult = .success([])
        drawingServiceMock.fetchByDateResult = .success([])

        let assembler = makeAssembler()
        let exp = expectation(description: "completion called")

        var receivedCards: [MoodEntryCard]?
        assembler.fetchInitial(limit: 10) { result in
            if case .success(let cards) = result {
                receivedCards = cards
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(receivedCards)
        XCTAssertTrue(receivedCards?.isEmpty == true)
        // With empty check-ins, the drawing service should be called for orphan path
        XCTAssertEqual(drawingServiceMock.fetchByDateCallCount, 1)
    }

    func test_MoodEntriesDataAssembler_fetchInitialEmptyCheckInsWithDrawings_returnsOrphanCards() {
        moodCheckInServiceMock.fetchLatestResult = .success([])
        let drawing = makeDrawing(id: "d1", checkinId: nil, createdAt: Date())
        drawingServiceMock.fetchByDateResult = .success([drawing])

        let assembler = makeAssembler()
        let exp = expectation(description: "completion called")

        var receivedCards: [MoodEntryCard]?
        assembler.fetchInitial(limit: 10) { result in
            if case .success(let cards) = result {
                receivedCards = cards
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)

        XCTAssertEqual(receivedCards?.count, 1)
        XCTAssertTrue(receivedCards?.first?.isOrphan == true)
    }

    // MARK: - fetchInitial with check-ins

    func test_MoodEntriesDataAssembler_fetchInitialWithCheckIns_assemblesCardsCorrectly() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])

        let drawing = makeDrawing(id: "d1", checkinId: "c1", createdAt: date(2026, 2, 20, 10, 5))
        drawingServiceMock.fetchByDateResult = .success([drawing])

        let assembler = makeAssembler()
        let exp = expectation(description: "completion called")

        var receivedCards: [MoodEntryCard]?
        assembler.fetchInitial(limit: 10) { result in
            if case .success(let cards) = result {
                receivedCards = cards
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)

        XCTAssertEqual(receivedCards?.count, 1)
        XCTAssertEqual(receivedCards?.first?.checkIn?.id, "c1")
        XCTAssertEqual(receivedCards?.first?.drawings.count, 1)
        XCTAssertEqual(receivedCards?.first?.drawings.first?.id, "d1")
    }

    // MARK: - fetchInitial with moodCheckIn service error

    func test_MoodEntriesDataAssembler_fetchInitialMoodCheckInError_propagatesError() {
        moodCheckInServiceMock.fetchLatestResult = .failure(TestError.checkInFetchFailed)

        let assembler = makeAssembler()
        let exp = expectation(description: "completion called")

        var receivedError: Error?
        assembler.fetchInitial(limit: 10) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(receivedError)
        XCTAssertEqual(receivedError as? TestError, .checkInFetchFailed)
        // Drawing service should not be called when check-in fetch fails
        XCTAssertEqual(drawingServiceMock.fetchByDateCallCount, 0)
    }

    // MARK: - fetchInitial with drawing service error

    func test_MoodEntriesDataAssembler_fetchInitialDrawingError_propagatesError() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])
        drawingServiceMock.fetchByDateResult = .failure(TestError.drawingFetchFailed)

        let assembler = makeAssembler()
        let exp = expectation(description: "completion called")

        var receivedError: Error?
        assembler.fetchInitial(limit: 10) { result in
            if case .failure(let error) = result {
                receivedError = error
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 0.1)

        XCTAssertNotNil(receivedError)
        XCTAssertEqual(receivedError as? TestError, .drawingFetchFailed)
    }
}

// MARK: - Helpers

private extension MoodEntriesDataAssemblerFetchTests {

    enum TestError: Error {
        case checkInFetchFailed
        case drawingFetchFailed
    }

    func makeAssembler() -> MoodEntriesDataAssembler {
        return MoodEntriesDataAssembler(
            user: userMock,
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock
        )
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

    func makeDrawing(id: String, checkinId: String?, createdAt: Date?) -> DrawingModel {
        return DrawingModel(
            id: id,
            checkinId: checkinId,
            isFromCheckIn: checkinId != nil,
            imageURL: "https://example.com/\(id)/image.png",
            recordingURL: "https://example.com/\(id)/recording.pkd",
            timezoneOffsetMinutes: 480,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }
}
