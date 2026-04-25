//
//  DrawingReflectionPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingReflectionPresenterTests: XCTestCase {

    private var delegateMock: DrawingReflectionPresenterDelegateMock!
    private var serviceMock: DrawingServiceMock!
    private var userMock: UserMock!

    override func setUp() {
        super.setUp()
        delegateMock = DrawingReflectionPresenterDelegateMock()
        serviceMock = DrawingServiceMock()
        userMock = UserMock()
    }

    override func tearDown() {
        delegateMock = nil
        serviceMock = nil
        userMock = nil
        super.tearDown()
    }

    // MARK: - submitReflection guards

    func test_submitReflection_emptyAnswer_doesNotCallService() {
        let presenter = makePresenter()

        presenter.submitReflection(drawingId: "d1", answer: "   ")

        XCTAssertEqual(serviceMock.updateReflectionCallCount, 0)
        XCTAssertFalse(delegateMock.didStartSaving)
        XCTAssertNil(delegateMock.didFinishAnswer)
        XCTAssertNil(delegateMock.didFailError)
    }

    func test_submitReflection_nilUserId_callsDidFail() {
        userMock.userId = nil
        let presenter = makePresenter()

        presenter.submitReflection(drawingId: "d1", answer: "hello")

        XCTAssertNotNil(delegateMock.didFailError)
        XCTAssertEqual(serviceMock.updateReflectionCallCount, 0)
    }

    // MARK: - submitReflection success / failure

    func test_submitReflection_success_callsDidFinish() {
        let exp = expectation(description: "delegate finishes")
        delegateMock.expectation = exp
        serviceMock.updateReflectionResult = .success(())
        let presenter = makePresenter()

        presenter.submitReflection(drawingId: "d1", answer: "  reflection text  ")

        wait(for: [exp], timeout: 0.1)
        XCTAssertEqual(delegateMock.didFinishAnswer, "reflection text")
        XCTAssertEqual(serviceMock.lastUpdateReflectionAnswer, "reflection text")
    }

    func test_submitReflection_failure_callsDidFail() {
        let exp = expectation(description: "delegate fails")
        delegateMock.expectation = exp
        serviceMock.updateReflectionResult = .failure(TestError.mockError)
        let presenter = makePresenter()

        presenter.submitReflection(drawingId: "d1", answer: "hello")

        wait(for: [exp], timeout: 0.1)
        XCTAssertNotNil(delegateMock.didFailError)
    }

    func test_submitReflection_doubleTap_callsServiceOnce() {
        let presenter = makePresenter()

        presenter.submitReflection(drawingId: "d1", answer: "first")
        presenter.submitReflection(drawingId: "d1", answer: "second")

        XCTAssertEqual(serviceMock.updateReflectionCallCount, 1)
    }

    func test_submitReflection_success_postsDrawingDidChangeNotification() {
        let delegateExp = expectation(description: "delegate finishes")
        delegateMock.expectation = delegateExp
        let notificationExp = expectation(
            forNotification: NSNotification.Name(rawValue: Notification.DrawingDidChange),
            object: nil
        )
        serviceMock.updateReflectionResult = .success(())
        let presenter = makePresenter()

        presenter.submitReflection(drawingId: "d1", answer: "hello")

        wait(for: [delegateExp, notificationExp], timeout: 0.5)
    }
}

// MARK: - Helpers

private extension DrawingReflectionPresenterTests {
    enum TestError: Error { case mockError }

    func makePresenter() -> DrawingReflectionPresenter {
        let presenter = DrawingReflectionPresenter(
            user: userMock,
            drawingService: serviceMock
        )
        presenter.delegate = delegateMock
        return presenter
    }
}

final class DrawingReflectionPresenterDelegateMock: DrawingReflectionPresenterDelegate {
    var didStartSaving = false
    var didFinishAnswer: String?
    var didFailError: Error?
    var expectation: XCTestExpectation?

    func didStartSavingReflection() {
        didStartSaving = true
    }

    func didFinishSavingReflection(answer: String) {
        didFinishAnswer = answer
        expectation?.fulfill()
    }

    func didFailSavingReflection(error: Error) {
        didFailError = error
        expectation?.fulfill()
    }
}
