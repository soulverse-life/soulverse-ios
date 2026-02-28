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

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        delegateMock = InnerCosmoViewPresenterDelegateMock()
        presenter = InnerCosmoViewPresenter(user: userMock)
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        userMock = nil
        super.tearDown()
    }

    // MARK: - fetchData Async Delivery

    func test_InnerCosmoViewPresenter_fetchData_deliversUserData() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        // Presenter has hardcoded 0.5s asyncAfter delay
        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertNotNil(delegateMock.updatedViewModel)
        XCTAssertFalse(delegateMock.updatedViewModel?.isLoading == true)
    }

    func test_InnerCosmoViewPresenter_fetchData_userNameMatchesMock() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.userName, userMock.nickName)
    }

    func test_InnerCosmoViewPresenter_fetchData_petNameMatchesMock() {
        let exp = expectation(description: "delegate receives final update")
        delegateMock.expectation = exp

        presenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(delegateMock.updatedViewModel?.petName, userMock.emoPetName)
    }

    // MARK: - Init With Custom UserMock

    func test_InnerCosmoViewPresenter_initWithCustomUser_deliversCustomValues() {
        let customUser = UserMock()
        customUser.nickName = "CustomName"
        customUser.emoPetName = "CosmoPet"
        customUser.planetName = "Neptune"

        let customPresenter = InnerCosmoViewPresenter(user: customUser)
        let customDelegate = InnerCosmoViewPresenterDelegateMock()
        let exp = expectation(description: "delegate receives final update")
        customDelegate.expectation = exp
        customPresenter.delegate = customDelegate

        customPresenter.fetchData()

        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(customDelegate.updatedViewModel?.userName, "CustomName")
        XCTAssertEqual(customDelegate.updatedViewModel?.petName, "CosmoPet")
        XCTAssertEqual(customDelegate.updatedViewModel?.planetName, "Neptune")
    }
}
