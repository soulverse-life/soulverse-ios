//
//  InsightViewPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class InsightViewPresenterTests: XCTestCase {

    // MARK: - Properties

    private var presenter: InsightViewPresenter!
    private var delegateMock: InsightViewPresenterDelegateMock!
    private var userMock: UserMock!
    private var moodCheckInServiceMock: MoodCheckInServiceMock!
    private var drawingServiceMock: DrawingServiceMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        moodCheckInServiceMock = MoodCheckInServiceMock()
        drawingServiceMock = DrawingServiceMock()
        presenter = InsightViewPresenter(
            user: userMock,
            moodCheckInService: moodCheckInServiceMock,
            drawingService: drawingServiceMock
        )
        delegateMock = InsightViewPresenterDelegateMock()
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

    // MARK: - fetchData with mock data (empty services → fallback to mockData)

    func test_InsightViewPresenter_fetchData_deliversIsLoadingFalse() {
        let expectation = expectation(description: "delegate update")
        delegateMock.onUpdate = { viewModel in
            if !viewModel.isLoading {
                expectation.fulfill()
            }
        }

        presenter.fetchData()

        waitForExpectations(timeout: 2)
        XCTAssertFalse(delegateMock.updatedViewModel!.isLoading)
    }

    func test_InsightViewPresenter_fetchData_weeklyMoodScoreIsNonNil() {
        let expectation = expectation(description: "delegate update")
        delegateMock.onUpdate = { viewModel in
            if !viewModel.isLoading {
                expectation.fulfill()
            }
        }

        presenter.fetchData()

        waitForExpectations(timeout: 2)
        XCTAssertNotNil(delegateMock.updatedViewModel?.weeklyMoodScore)
    }

    func test_InsightViewPresenter_fetchData_weeklyMoodScoreHas7DailyScores() {
        let expectation = expectation(description: "delegate update")
        delegateMock.onUpdate = { viewModel in
            if !viewModel.isLoading {
                expectation.fulfill()
            }
        }

        presenter.fetchData()

        waitForExpectations(timeout: 2)
        XCTAssertEqual(delegateMock.updatedViewModel?.weeklyMoodScore?.dailyScores.count, 7)
    }

    func test_InsightViewPresenter_fetchData_noUserReturnsEmptyModel() {
        userMock.userId = nil

        presenter.fetchData()

        XCTAssertNotNil(delegateMock.updatedViewModel)
        XCTAssertFalse(delegateMock.updatedViewModel!.isLoading)
        XCTAssertNil(delegateMock.updatedViewModel?.weeklyMoodScore)
    }

    // MARK: - numberOfSectionsOnTableView

    func test_InsightViewPresenter_numberOfSectionsOnTableView_returnsZero() {
        XCTAssertEqual(presenter.numberOfSectionsOnTableView(), 0)
    }

    // MARK: - Initial State

    func test_InsightViewPresenter_initialState_isLoadingFalse() {
        XCTAssertNil(delegateMock.updatedViewModel)
        XCTAssertEqual(delegateMock.updateCount, 0)
    }

    // MARK: - setTimeRange

    func test_InsightViewPresenter_setTimeRange_refetchesData() {
        let expectation = expectation(description: "delegate update after range change")
        var nonLoadingCount = 0
        delegateMock.onUpdate = { viewModel in
            if !viewModel.isLoading {
                nonLoadingCount += 1
                if nonLoadingCount == 2 { // first fetch + range change fetch
                    expectation.fulfill()
                }
            }
        }

        presenter.fetchData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.presenter.setTimeRange(.all)
        }

        waitForExpectations(timeout: 3)
        XCTAssertEqual(delegateMock.updatedViewModel?.timeRange, .all)
    }
}
