//
//  DrawingReplayPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingReplayPresenterTests: XCTestCase {

    // MARK: - Properties

    private var presenter: DrawingReplayPresenter!
    private var delegateMock: DrawingReplayPresenterDelegateMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        presenter = DrawingReplayPresenter()
        delegateMock = DrawingReplayPresenterDelegateMock()
        presenter.delegate = delegateMock
    }

    override func tearDown() {
        presenter = nil
        delegateMock = nil
        super.tearDown()
    }

    // MARK: - loadRecording: Invalid URL

    func test_DrawingReplayPresenter_loadRecordingEmptyString_callsDidFailLoading() {
        presenter.loadRecording(from: "")

        XCTAssertNotNil(delegateMock.failError)
        XCTAssertEqual(delegateMock.failCount, 1)
    }

    func test_DrawingReplayPresenter_loadRecordingEmptyString_doesNotCallDidStartLoading() {
        presenter.loadRecording(from: "")

        XCTAssertFalse(delegateMock.didStartLoadingCalled)
    }

    func test_DrawingReplayPresenter_loadRecordingInvalidURL_errorIsInvalidURL() {
        presenter.loadRecording(from: "")

        let replayError = delegateMock.failError as? DrawingReplayPresenter.ReplayError
        XCTAssertEqual(replayError, .invalidURL)
    }

    // MARK: - loadRecording: Valid URL

    func test_DrawingReplayPresenter_loadRecordingValidURL_callsDidStartLoading() {
        // A syntactically valid URL triggers didStartLoading synchronously
        presenter.loadRecording(from: "https://example.com/recording.data")

        XCTAssertTrue(delegateMock.didStartLoadingCalled)
        XCTAssertEqual(delegateMock.didStartLoadingCount, 1)
    }

    // MARK: - stopReplay

    func test_DrawingReplayPresenter_stopReplayOnFreshPresenter_doesNotCrash() {
        presenter.stopReplay()
        // No crash means success
    }

    // MARK: - ReplayError Descriptions

    func test_DrawingReplayPresenter_replayErrorInvalidURL_hasDescription() {
        let error = DrawingReplayPresenter.ReplayError.invalidURL
        XCTAssertNotNil(error.errorDescription)
    }

    func test_DrawingReplayPresenter_replayErrorNoData_hasDescription() {
        let error = DrawingReplayPresenter.ReplayError.noData
        XCTAssertNotNil(error.errorDescription)
    }

    func test_DrawingReplayPresenter_replayErrorNoStrokes_hasDescription() {
        let error = DrawingReplayPresenter.ReplayError.noStrokes
        XCTAssertNotNil(error.errorDescription)
    }

    func test_DrawingReplayPresenter_replayErrors_haveDistinctDescriptions() {
        let descriptions = [
            DrawingReplayPresenter.ReplayError.invalidURL.errorDescription,
            DrawingReplayPresenter.ReplayError.noData.errorDescription,
            DrawingReplayPresenter.ReplayError.noStrokes.errorDescription
        ]
        let uniqueDescriptions = Set(descriptions.compactMap { $0 })
        XCTAssertEqual(uniqueDescriptions.count, 3, "Each error should have a unique description")
    }

    // MARK: - Delegate is Weak

    func test_DrawingReplayPresenter_delegate_isWeakAndDoesNotRetain() {
        var mock: DrawingReplayPresenterDelegateMock? = DrawingReplayPresenterDelegateMock()
        presenter.delegate = mock
        XCTAssertNotNil(presenter.delegate)

        mock = nil
        XCTAssertNil(presenter.delegate)
    }
}
