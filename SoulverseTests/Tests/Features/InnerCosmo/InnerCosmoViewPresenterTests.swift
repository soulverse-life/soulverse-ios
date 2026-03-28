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
    private var journalServiceMock: JournalServiceMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        delegateMock = InnerCosmoViewPresenterDelegateMock()
        moodCheckInServiceMock = MoodCheckInServiceMock()
        drawingServiceMock = DrawingServiceMock()
        journalServiceMock = JournalServiceMock()

        let assembler = MoodEntriesDataAssembler(
            user: userMock,
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock,
            journalService: journalServiceMock
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
        journalServiceMock = nil
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
            user: userMock,
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock,
            journalService: journalServiceMock
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
        XCTAssertNil(entries.first?.journalTitle)
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

    func test_InnerCosmoViewPresenter_fetchData_deliversEmptyEntriesOnServiceFailure() {
        moodCheckInServiceMock.fetchLatestResult = .failure(NSError(domain: "test", code: 1))

        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 2.0)

        let viewModel = delegateMock.updatedViewModel
        XCTAssertTrue(viewModel?.moodEntries.isEmpty == true)
        XCTAssertFalse(viewModel?.isLoading == true)
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
        XCTAssertEqual(viewModel?.moodEntries.count, 1)
    }

    // MARK: - didSelectPlanet

    func test_InnerCosmoViewPresenter_didSelectPlanet_deliversCheckInToDelegate() {
        let now = Date()
        let checkIn = MoodCheckInModel(
            id: "planet-checkin-1",
            colorHex: "#FFD700",
            colorIntensity: 0.8,
            emotion: "joy",
            topic: "emotional",
            evaluation: "Feeling great",
            timezoneOffsetMinutes: 480,
            createdAt: now,
            updatedAt: now
        )
        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])
        drawingServiceMock.fetchByDateResult = .success([])

        let fetchExp = expectation(description: "delegate receives final update")
        delegateMock.expectation = fetchExp

        presenter.fetchData()
        wait(for: [fetchExp], timeout: 2.0)

        // Now select planet at index 0 (central planet)
        presenter.didSelectPlanet(at: 0)

        XCTAssertNotNil(delegateMock.requestedCheckIn)
        XCTAssertEqual(delegateMock.requestedCheckIn?.id, "planet-checkin-1")
    }

    func test_InnerCosmoViewPresenter_didSelectPlanet_outOfBoundsDoesNotCrash() {
        let now = Date()
        let checkIn = MoodCheckInModel(
            id: "planet-checkin-2",
            colorHex: "#A5D6A7",
            colorIntensity: 0.5,
            emotion: "serenity",
            topic: "spiritual",
            evaluation: "Calm",
            timezoneOffsetMinutes: 480,
            createdAt: now,
            updatedAt: now
        )
        moodCheckInServiceMock.fetchLatestResult = .success([checkIn])
        drawingServiceMock.fetchByDateResult = .success([])

        let fetchExp = expectation(description: "delegate receives final update")
        delegateMock.expectation = fetchExp

        presenter.fetchData()
        wait(for: [fetchExp], timeout: 2.0)

        // Out of bounds — should not crash or call delegate
        presenter.didSelectPlanet(at: 10)
        XCTAssertNil(delegateMock.requestedCheckIn)

        // Negative index
        presenter.didSelectPlanet(at: -1)
        XCTAssertNil(delegateMock.requestedCheckIn)
    }

    func test_InnerCosmoViewPresenter_didSelectPlanet_beforeFetchDoesNotCrash() {
        // No fetchData called — planetCheckIns is empty
        presenter.didSelectPlanet(at: 0)
        XCTAssertNil(delegateMock.requestedCheckIn)
    }

    func test_InnerCosmoViewPresenter_didSelectPlanet_selectsCorrectCheckInByIndex() {
        let now = Date()
        var checkIns: [MoodCheckInModel] = []
        for i in 0..<3 {
            checkIns.append(MoodCheckInModel(
                id: "checkin-\(i)",
                colorHex: "#FFD700",
                colorIntensity: 0.5,
                emotion: "joy",
                topic: "emotional",
                evaluation: "Entry \(i)",
                timezoneOffsetMinutes: 480,
                createdAt: now.addingTimeInterval(Double(-i * 60)),
                updatedAt: now.addingTimeInterval(Double(-i * 60))
            ))
        }
        moodCheckInServiceMock.fetchLatestResult = .success(checkIns)
        drawingServiceMock.fetchByDateResult = .success([])

        let fetchExp = expectation(description: "delegate receives final update")
        delegateMock.expectation = fetchExp

        presenter.fetchData()
        wait(for: [fetchExp], timeout: 2.0)

        // Select surrounding planet (index 2 = third check-in)
        presenter.didSelectPlanet(at: 2)

        XCTAssertEqual(delegateMock.requestedCheckIn?.id, "checkin-2")
    }

    // MARK: - No User ID

    func test_InnerCosmoViewPresenter_fetchData_deliversEmptyEntriesWhenNoUserId() {
        userMock.userId = nil

        let assembler = MoodEntriesDataAssembler(
            user: userMock,
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock,
            journalService: journalServiceMock
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
        XCTAssertFalse(viewModel?.isLoading == true)
    }
}
