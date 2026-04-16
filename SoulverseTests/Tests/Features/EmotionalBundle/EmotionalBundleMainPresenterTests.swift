//
//  EmotionalBundleMainPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class EmotionalBundleMainPresenterTests: XCTestCase {

    private var presenter: EmotionalBundleMainPresenter!
    private var mockService: EmotionalBundleServiceMock!
    private var mockDelegate: MockPresenterDelegate!

    override func setUp() {
        super.setUp()
        mockService = EmotionalBundleServiceMock()
        mockDelegate = MockPresenterDelegate()
        presenter = EmotionalBundleMainPresenter(uid: "test-uid", service: mockService)
        presenter.delegate = mockDelegate
    }

    func testFetchDataShowsLoadingThenCards() {
        let bundle = EmotionalBundleModel(redFlags: [RedFlagItem(text: "flag", sortOrder: 0)])
        mockService.fetchBundleResult = .success(bundle)

        let expectation = expectation(description: "fetch")
        mockDelegate.onUpdate = { vm in
            if !vm.isLoading {
                XCTAssertEqual(vm.sectionCards.count, 5)
                XCTAssertTrue(vm.sectionCards[0].isCompleted) // redFlags
                XCTAssertFalse(vm.sectionCards[1].isCompleted) // supportMe
                expectation.fulfill()
            }
        }
        presenter.fetchData()
        waitForExpectations(timeout: 1)
    }

    func testFetchDataCallsDidFailOnError() {
        mockService.fetchBundleResult = .failure(NSError(domain: "test", code: 1))

        let expectation = expectation(description: "error")
        mockDelegate.onError = { _ in expectation.fulfill() }
        presenter.fetchData()
        waitForExpectations(timeout: 1)
    }

    func testCurrentBundleReturnsEmptyBeforeFetch() {
        let bundle = presenter.currentBundle()
        XCTAssertTrue(bundle.redFlags.isEmpty)
    }

    func testFetchDataIncrementsServiceCallCount() {
        mockService.fetchBundleResult = .success(nil)

        let expectation = expectation(description: "fetch")
        mockDelegate.onUpdate = { vm in
            if !vm.isLoading { expectation.fulfill() }
        }
        presenter.fetchData()
        waitForExpectations(timeout: 1)
        XCTAssertEqual(mockService.fetchBundleCallCount, 1)
    }

    func testCurrentBundleReturnsCachedBundleAfterFetch() {
        let bundle = EmotionalBundleModel(redFlags: [RedFlagItem(text: "cached", sortOrder: 0)])
        mockService.fetchBundleResult = .success(bundle)

        let expectation = expectation(description: "fetch")
        mockDelegate.onUpdate = { vm in
            if !vm.isLoading { expectation.fulfill() }
        }
        presenter.fetchData()
        waitForExpectations(timeout: 1)

        let cached = presenter.currentBundle()
        XCTAssertEqual(cached.redFlags.first?.text, "cached")
    }
}

private final class MockPresenterDelegate: EmotionalBundleMainPresenterDelegate {
    var onUpdate: ((EmotionalBundleMainViewModel) -> Void)?
    var onError: ((Error) -> Void)?

    func didUpdate(viewModel: EmotionalBundleMainViewModel) { onUpdate?(viewModel) }
    func didFailToLoad(error: Error) { onError?(error) }
}
