//
//  ErrorReportingTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class ErrorReportingTests: XCTestCase {

    // MARK: - Properties

    private var clientMock: CrashlyticsClientMock!
    private var userMock: UserMock!
    private var notificationCenter: NotificationCenter!
    private var sut: ErrorReporting!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        clientMock = CrashlyticsClientMock()
        userMock = UserMock()
        notificationCenter = NotificationCenter()
        sut = ErrorReporting(
            client: clientMock,
            user: userMock,
            notificationCenter: notificationCenter
        )
    }

    override func tearDown() {
        sut = nil
        notificationCenter = nil
        userMock = nil
        clientMock = nil
        super.tearDown()
    }

    // MARK: - start()

    func test_ErrorReporting_start_setsCurrentUserIDImmediately() {
        userMock.userId = "user-123"

        sut.start()

        XCTAssertEqual(clientMock.setUserIDCallCount, 1)
        XCTAssertEqual(clientMock.lastUserIDSet, "user-123")
    }

    func test_ErrorReporting_start_setsEmptyStringWhenLoggedOut() {
        userMock.userId = nil

        sut.start()

        XCTAssertEqual(clientMock.lastUserIDSet, "")
    }

    // MARK: - UserIdentityChange notification

    func test_ErrorReporting_userIdentityChangeNotification_resyncsUserID() {
        userMock.userId = nil
        sut.start()
        XCTAssertEqual(clientMock.lastUserIDSet, "")

        userMock.userId = "user-456"
        notificationCenter.post(
            name: NSNotification.Name(rawValue: Notification.UserIdentityChange),
            object: nil
        )

        XCTAssertEqual(clientMock.setUserIDCallCount, 2)
        XCTAssertEqual(clientMock.lastUserIDSet, "user-456")
    }

    func test_ErrorReporting_logout_clearsUserID() {
        userMock.userId = "user-789"
        sut.start()

        userMock.userId = nil
        notificationCenter.post(
            name: NSNotification.Name(rawValue: Notification.UserIdentityChange),
            object: nil
        )

        XCTAssertEqual(clientMock.lastUserIDSet, "")
    }
}
