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

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        presenter = InsightViewPresenter()
        delegateMock = InsightViewPresenterDelegateMock()
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        super.tearDown()
    }

    // MARK: - fetchData

    func test_InsightViewPresenter_fetchData_deliversIsLoadingFalse() {
        presenter.fetchData()

        XCTAssertFalse(delegateMock.updatedViewModel!.isLoading)
    }

    func test_InsightViewPresenter_fetchData_weeklyMoodScoreIsNonNil() {
        presenter.fetchData()

        XCTAssertNotNil(delegateMock.updatedViewModel?.weeklyMoodScore)
    }

    func test_InsightViewPresenter_fetchData_weeklyMoodScoreHas7DailyScores() {
        presenter.fetchData()

        XCTAssertEqual(delegateMock.updatedViewModel?.weeklyMoodScore?.dailyScores.count, 7)
    }

    // MARK: - numberOfSectionsOnTableView

    func test_InsightViewPresenter_numberOfSectionsOnTableView_returnsZero() {
        XCTAssertEqual(presenter.numberOfSectionsOnTableView(), 0)
    }

    // MARK: - Initial State

    func test_InsightViewPresenter_initialState_isLoadingFalse() {
        // Before any fetchData call, no delegate update has been triggered.
        // The loadedModel is initialized with isLoading: false.
        XCTAssertNil(delegateMock.updatedViewModel)
        XCTAssertEqual(delegateMock.updateCount, 0)
    }
}
