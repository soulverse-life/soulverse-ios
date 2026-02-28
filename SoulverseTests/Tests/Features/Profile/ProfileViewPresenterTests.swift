//
//  ProfileViewPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class ProfileViewPresenterTests: XCTestCase {

    // MARK: - Properties

    private var presenter: ProfileViewPresenter!
    private var delegateMock: ProfileViewPresenterDelegateMock!
    private var userMock: UserMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        userMock = UserMock()
        delegateMock = ProfileViewPresenterDelegateMock()
        presenter = ProfileViewPresenter(user: userMock)
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        userMock = nil
        super.tearDown()
    }

    // MARK: - fetchProfile

    func test_ProfileViewPresenter_fetchProfile_deliversUserName() {
        presenter.fetchProfile()

        XCTAssertEqual(delegateMock.updatedViewModel?.userName, "TestUser")
    }

    func test_ProfileViewPresenter_fetchProfile_deliversEmail() {
        presenter.fetchProfile()

        XCTAssertEqual(delegateMock.updatedViewModel?.email, "test@gmail.com")
    }

    func test_ProfileViewPresenter_fetchProfile_deliversEmoPetName() {
        presenter.fetchProfile()

        XCTAssertEqual(delegateMock.updatedViewModel?.emoPetName, userMock.emoPetName)
    }

    func test_ProfileViewPresenter_fetchProfile_deliversPlanetName() {
        presenter.fetchProfile()

        XCTAssertEqual(delegateMock.updatedViewModel?.planetName, userMock.planetName)
    }

    func test_ProfileViewPresenter_fetchProfile_setsIsLoadingFalse() {
        presenter.fetchProfile()

        XCTAssertFalse(delegateMock.updatedViewModel!.isLoading)
    }
}
