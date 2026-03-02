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
    private var assemblerMock: MoodEntriesDataAssemblerMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        assemblerMock = MoodEntriesDataAssemblerMock()
        delegateMock = InnerCosmoViewPresenterDelegateMock()
        presenter = InnerCosmoViewPresenter(user: userMock, assembler: assemblerMock)
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        userMock = nil
        assemblerMock = nil
        super.tearDown()
    }

    // MARK: - fetchData Tests

    func test_fetchData_withCheckIns_populatesMoodEntries() {
        let card = makeCheckInCard(id: "c1", emotion: "joy", journal: "Happy day")
        assemblerMock.fetchInitialResult = .success([card])

        let exp = expectation(description: "delegate receives update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(assemblerMock.fetchInitialCallCount, 1)
        XCTAssertEqual(delegateMock.updatedViewModel?.moodEntries.count, 1)
        XCTAssertEqual(delegateMock.updatedViewModel?.moodEntries.first?.emotion, .joy)
        XCTAssertEqual(delegateMock.updatedViewModel?.moodEntries.first?.journal, "Happy day")
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    func test_fetchData_empty_deliversEmptyEntries() {
        assemblerMock.fetchInitialResult = .success([])

        let exp = expectation(description: "delegate receives update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.moodEntries.count, 0)
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    func test_fetchData_error_deliversEmptyEntriesGracefully() {
        assemblerMock.fetchInitialResult = .failure(TestError.fetchFailed)

        let exp = expectation(description: "delegate receives update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.moodEntries.count, 0)
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    func test_fetchData_deliversUserData() {
        assemblerMock.fetchInitialResult = .success([])

        let exp = expectation(description: "delegate receives update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.userName, userMock.nickName)
        XCTAssertEqual(delegateMock.updatedViewModel?.petName, userMock.emoPetName)
        XCTAssertEqual(delegateMock.updatedViewModel?.planetName, userMock.planetName)
    }

    // MARK: - loadMoreMoodEntries Tests

    func test_loadMoreMoodEntries_appendsEntries() {
        // First, do initial load
        let initialCard = makeCheckInCard(id: "c1", emotion: "joy", journal: "Day 1")
        assemblerMock.fetchInitialResult = .success([initialCard])
        assemblerMock.hasMore = true

        let exp1 = expectation(description: "initial load")
        delegateMock.expectation = exp1
        presenter.fetchData()
        wait(for: [exp1], timeout: 1.0)

        // Now load more
        let moreCard = makeCheckInCard(id: "c2", emotion: "trust", journal: "Day 2")
        assemblerMock.fetchMoreResult = .success([moreCard])

        let exp2 = expectation(description: "load more append")
        delegateMock.appendExpectation = exp2
        presenter.loadMoreMoodEntries()
        wait(for: [exp2], timeout: 1.0)

        XCTAssertEqual(assemblerMock.fetchMoreCallCount, 1)
        XCTAssertEqual(delegateMock.appendedEntries?.count, 1)
        XCTAssertEqual(delegateMock.appendedEntries?.first?.emotion, .trust)
    }

    func test_loadMoreMoodEntries_whenHasMoreFalse_doesNotFetch() {
        // Initial load
        let initialCard = makeCheckInCard(id: "c1", emotion: "joy", journal: "Day 1")
        assemblerMock.fetchInitialResult = .success([initialCard])
        assemblerMock.hasMore = false

        let exp1 = expectation(description: "initial load")
        delegateMock.expectation = exp1
        presenter.fetchData()
        wait(for: [exp1], timeout: 1.0)

        // Try to load more — should be guarded by hasMore == false
        presenter.loadMoreMoodEntries()

        XCTAssertEqual(assemblerMock.fetchMoreCallCount, 0)
    }
}

// MARK: - Helpers

private extension InnerCosmoViewPresenterTests {

    enum TestError: Error {
        case fetchFailed
    }

    func makeCheckInCard(id: String, emotion: String, journal: String?) -> MoodEntryCard {
        let checkIn = MoodCheckInModel(
            id: id,
            colorHex: "#FFD700",
            colorIntensity: 0.8,
            emotion: emotion,
            topic: "emotional",
            evaluation: "positive",
            journal: journal,
            timezoneOffsetMinutes: 480,
            createdAt: Date(),
            updatedAt: Date()
        )
        return MoodEntryCard(
            checkIn: checkIn,
            drawings: [],
            date: Date()
        )
    }
}
