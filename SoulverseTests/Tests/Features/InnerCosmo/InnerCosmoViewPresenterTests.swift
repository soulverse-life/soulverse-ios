//
//  InnerCosmoViewPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class InnerCosmoViewPresenterTests: XCTestCase {

    // MARK: - Properties

    private var presenter: InnerCosmoViewPresenter!
    private var delegateMock: InnerCosmoViewPresenterDelegateMock!
    private var userMock: UserMock!
    private var moodCheckInServiceMock: MoodCheckInServiceMock!
    private var drawingServiceMock: DrawingServiceMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        delegateMock = InnerCosmoViewPresenterDelegateMock()
        moodCheckInServiceMock = MoodCheckInServiceMock()
        drawingServiceMock = DrawingServiceMock()

        let assembler = MoodEntriesDataAssembler(
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock
        )

        presenter = InnerCosmoViewPresenter(user: userMock, assembler: assembler)
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        userMock = nil
        moodCheckInServiceMock = nil
        drawingServiceMock = nil
        super.tearDown()
    }

    // MARK: - fetchData Async Delivery

    func test_InnerCosmoViewPresenter_fetchData_deliversUserData() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        XCTAssertNotNil(delegateMock.updatedViewModel)
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    func test_InnerCosmoViewPresenter_fetchData_userNameMatchesMock() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.userName, userMock.nickName)
    }

    func test_InnerCosmoViewPresenter_fetchData_petNameMatchesMock() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.petName, userMock.emoPetName)
    }

    // MARK: - Init With Custom UserMock

    func test_InnerCosmoViewPresenter_initWithCustomUser_deliversCustomValues() {
        let customUser = UserMock()
        customUser.nickName = "CustomName"
        customUser.emoPetName = "CosmoPet"
        customUser.planetName = "Neptune"

        let assembler = MoodEntriesDataAssembler(
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock
        )
        let customPresenter = InnerCosmoViewPresenter(user: customUser, assembler: assembler)
        let customDelegate = InnerCosmoViewPresenterDelegateMock()
        let exp = expectation(description: "delegate receives final update")
        customDelegate.expectation = exp
        customPresenter.delegate = customDelegate

        customPresenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        XCTAssertEqual(customDelegate.updatedViewModel?.userName, "CustomName")
        XCTAssertEqual(customDelegate.updatedViewModel?.petName, "CosmoPet")
        XCTAssertEqual(customDelegate.updatedViewModel?.planetName, "Neptune")
    }

    // MARK: - Mood Entry Conversion

    func test_InnerCosmoViewPresenter_fetchData_convertsMoodEntryCards() {
        let now = Date()
        let checkIn = MoodCheckInModel(
            id: "checkin-1",
            colorHex: "#FFD700",
            colorIntensity: 0.8,
            emotion: "joy",
            topic: "emotional",
            evaluation: "Feeling great today",
            journal: nil,
            timezoneOffsetMinutes: 480,
            createdAt: now,
            updatedAt: now
        )
        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])
        drawingServiceMock.fetchByDateResult = .success([])

        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        let entries = delegateMock.updatedViewModel?.moodEntries ?? []
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.emotion, .joy)
        XCTAssertEqual(entries.first?.colorHex, "#FFD700")
        XCTAssertEqual(entries.first?.promptResponse, "Feeling great today")
        XCTAssertEqual(entries.first?.artworkURLs, [])
    }

    func test_InnerCosmoViewPresenter_fetchData_mapsDrawingURLsToArtworkURLs() {
        let now = Date()
        let checkIn = MoodCheckInModel(
            id: "checkin-2",
            colorHex: "#4A4A8A",
            colorIntensity: 0.6,
            emotion: "serenity",
            topic: "spiritual",
            evaluation: "Peaceful moment",
            journal: nil,
            timezoneOffsetMinutes: 480,
            createdAt: now,
            updatedAt: now
        )

        let drawing1 = DrawingModel(
            id: "drawing-1",
            checkinId: "checkin-2",
            isFromCheckIn: false,
            imageURL: "https://example.com/art1.png",
            recordingURL: "https://example.com/rec1.mp4",
            timezoneOffsetMinutes: 480,
            createdAt: now.addingTimeInterval(60),
            updatedAt: now.addingTimeInterval(60)
        )
        let drawing2 = DrawingModel(
            id: "drawing-2",
            checkinId: "checkin-2",
            isFromCheckIn: false,
            imageURL: "https://example.com/art2.png",
            recordingURL: "https://example.com/rec2.mp4",
            timezoneOffsetMinutes: 480,
            createdAt: now.addingTimeInterval(120),
            updatedAt: now.addingTimeInterval(120)
        )

        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])
        drawingServiceMock.fetchByDateResult = .success([drawing1, drawing2])

        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        let entries = delegateMock.updatedViewModel?.moodEntries ?? []
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.artworkURLs.count, 2)
        XCTAssertTrue(entries.first?.hasArtwork == true)
    }

    func test_InnerCosmoViewPresenter_fetchData_setsErrorOnServiceFailure() {
        moodCheckInServiceMock.fetchLatestResult = .failure(NSError(domain: "test", code: 1))

        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        let viewModel = delegateMock.updatedViewModel
        XCTAssertTrue(viewModel?.moodEntries.isEmpty == true)
        XCTAssertTrue(viewModel?.moodEntriesLoadError == true)
    }

    func test_InnerCosmoViewPresenter_fetchData_noErrorOnSuccess() {
        let now = Date()
        let checkIn = MoodCheckInModel(
            id: "checkin-ok",
            colorHex: "#FFD700",
            colorIntensity: 0.5,
            emotion: "joy",
            topic: "emotional",
            evaluation: "All good",
            journal: nil,
            timezoneOffsetMinutes: 480,
            createdAt: now,
            updatedAt: now
        )
        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])
        drawingServiceMock.fetchByDateResult = .success([])

        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        let viewModel = delegateMock.updatedViewModel
        XCTAssertFalse(viewModel?.moodEntriesLoadError == true)
        XCTAssertEqual(viewModel?.moodEntries.count, 1)
    }

    func test_InnerCosmoViewPresenter_fetchData_setsErrorWhenNoUserId() {
        userMock.userId = nil

        let assembler = MoodEntriesDataAssembler(
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock
        )
        let noIdPresenter = InnerCosmoViewPresenter(user: userMock, assembler: assembler)
        let noIdDelegate = InnerCosmoViewPresenterDelegateMock()
        let exp = expectation(description: "delegate receives final update")
        noIdDelegate.expectation = exp
        noIdPresenter.delegate = noIdDelegate

        noIdPresenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        let viewModel = noIdDelegate.updatedViewModel
        XCTAssertTrue(viewModel?.moodEntries.isEmpty == true)
        XCTAssertTrue(viewModel?.moodEntriesLoadError == true)
    }
}
