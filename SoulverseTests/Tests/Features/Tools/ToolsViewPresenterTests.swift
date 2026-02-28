//
//  ToolsViewPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class ToolsViewPresenterTests: XCTestCase {

    // MARK: - Properties

    private var presenter: ToolsViewPresenter!
    private var delegateMock: ToolsViewPresenterDelegateMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        presenter = ToolsViewPresenter()
        delegateMock = ToolsViewPresenterDelegateMock()
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        super.tearDown()
    }

    // MARK: - fetchData

    func test_ToolsViewPresenter_fetchData_deliversLoadingThenSections() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        // First delegate call should be isLoading = true
        XCTAssertNotNil(delegateMock.updatedViewModel)
        XCTAssertTrue(delegateMock.updatedViewModel?.isLoading == true)

        // Presenter has hardcoded 0.5s asyncAfter delay
        wait(for: [exp], timeout: 1.0)

        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
        XCTAssertEqual(delegateMock.updatedViewModel?.sections.count, 2)
    }

    func test_ToolsViewPresenter_fetchData_firstSectionHas2Items() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.sections[0].items.count, 2)
    }

    func test_ToolsViewPresenter_fetchData_secondSectionHas3Items() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.sections[1].items.count, 3)
    }

    // MARK: - didSelectTool

    func test_ToolsViewPresenter_didSelectToolDailyQuote_doesNotCrash() {
        presenter.didSelectTool(action: .dailyQuote)
        // No crash means success
    }

    // MARK: - Initial State

    func test_ToolsViewPresenter_initialViewModel_isLoadingTrue() {
        // The initial viewModel is created with isLoading: true in the presenter.
        // Setting the delegate after init does not trigger didSet,
        // so we call fetchData which immediately sets isLoading = true.
        presenter.fetchData()

        XCTAssertTrue(delegateMock.updatedViewModel?.isLoading == true)
    }
}
