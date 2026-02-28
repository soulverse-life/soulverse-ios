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

    // MARK: - loadRecording with Invalid URL

    func test_DrawingReplayPresenter_loadRecordingEmptyString_callsDidFailLoading() {
        presenter.loadRecording(from: "")

        XCTAssertNotNil(delegateMock.failError)
    }

    // MARK: - ReplayError Descriptions

    func test_DrawingReplayPresenter_replayErrorInvalidURL_errorDescriptionIsNonNil() {
        let error = DrawingReplayPresenter.ReplayError.invalidURL
        XCTAssertNotNil(error.errorDescription)
    }

    func test_DrawingReplayPresenter_replayErrorNoData_errorDescriptionIsNonNil() {
        let error = DrawingReplayPresenter.ReplayError.noData
        XCTAssertNotNil(error.errorDescription)
    }

    func test_DrawingReplayPresenter_replayErrorNoStrokes_errorDescriptionIsNonNil() {
        let error = DrawingReplayPresenter.ReplayError.noStrokes
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - stopReplay

    func test_DrawingReplayPresenter_stopReplayOnFreshPresenter_doesNotCrash() {
        presenter.stopReplay()
        // No crash means success
    }
}
