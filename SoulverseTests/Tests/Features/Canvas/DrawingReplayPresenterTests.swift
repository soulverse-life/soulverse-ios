//
//  DrawingReplayPresenterTests.swift
//  SoulverseTests
//

import PencilKit
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
        presenter.stopReplay()
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

    func test_DrawingReplayPresenter_loadRecordingValidURL_callsDidStartLoading() {
        // A syntactically valid URL triggers didStartLoading synchronously
        presenter.loadRecording(from: "https://example.com/recording.data")

        XCTAssertTrue(delegateMock.didStartLoadingCalled)
        XCTAssertEqual(delegateMock.didStartLoadingCount, 1)
    }

    // MARK: - startReplay: Basic Behavior

    func test_DrawingReplayPresenter_startReplayWithStrokes_callsDidReplayStroke() {
        let strokes = makeStrokes(count: 3)
        let exp = expectation(description: "at least one stroke replayed")
        delegateMock.replayStrokeExpectation = exp

        presenter.startReplay(strokes: strokes, transform: .identity)

        wait(for: [exp], timeout: 1.0)
        XCTAssertGreaterThan(delegateMock.replayStrokeCount, 0)
    }

    func test_DrawingReplayPresenter_startReplayWithStrokes_callsDidFinishReplay() {
        let strokes = makeStrokes(count: 3)
        let exp = expectation(description: "replay finishes")
        delegateMock.finishReplayExpectation = exp

        presenter.startReplay(strokes: strokes, transform: .identity)

        wait(for: [exp], timeout: 5.0)
        XCTAssertTrue(delegateMock.didFinishReplayCalled)
    }

    func test_DrawingReplayPresenter_startReplayStrokeCount_equalsInputStrokeCount() {
        let strokeCount = 5
        let strokes = makeStrokes(count: strokeCount)
        let exp = expectation(description: "replay finishes")
        delegateMock.finishReplayExpectation = exp

        presenter.startReplay(strokes: strokes, transform: .identity)

        wait(for: [exp], timeout: 5.0)
        XCTAssertEqual(delegateMock.replayStrokeCount, strokeCount)
    }

    func test_DrawingReplayPresenter_startReplay_strokesAreAddedIncrementally() {
        let strokeCount = 4
        let strokes = makeStrokes(count: strokeCount)
        let exp = expectation(description: "replay finishes")
        delegateMock.finishReplayExpectation = exp

        presenter.startReplay(strokes: strokes, transform: .identity)

        wait(for: [exp], timeout: 5.0)

        // Each replayed drawing should have incrementally more strokes
        for (index, drawing) in delegateMock.replayedDrawings.enumerated() {
            XCTAssertEqual(
                drawing.strokes.count,
                index + 1,
                "Drawing at replay step \(index) should have \(index + 1) strokes"
            )
        }
    }

    // MARK: - startReplay: Transform

    func test_DrawingReplayPresenter_startReplayWithTransform_appliesTransformToDrawing() {
        // Use enough strokes so timer interval is short (max(0.05, 3.0/60) = 0.05s)
        let strokeCount = 60
        let strokes = makeStrokes(count: strokeCount)
        let scale: CGFloat = 2.0
        let transform = CGAffineTransform(scaleX: scale, y: scale)
        let exp = expectation(description: "replay finishes")
        delegateMock.finishReplayExpectation = exp

        presenter.startReplay(strokes: strokes, transform: transform)

        wait(for: [exp], timeout: 5.0)

        // The replayed drawing bounds should differ from the original
        // because the transform was applied
        let replayedDrawing = delegateMock.replayedDrawing
        XCTAssertNotNil(replayedDrawing)

        var originalDrawing = PKDrawing()
        originalDrawing.strokes = strokes
        let originalBounds = originalDrawing.bounds

        if let replayed = replayedDrawing, !originalBounds.isEmpty {
            // Scaled drawing bounds should be approximately 2x the original
            XCTAssertEqual(
                replayed.bounds.width,
                originalBounds.width * scale,
                accuracy: 5.0
            )
        }
    }

    // MARK: - startReplay: Called Twice (Restart)

    func test_DrawingReplayPresenter_startReplayCalledTwice_resetsReplay() {
        let strokes = makeStrokes(count: 3)
        let exp = expectation(description: "second replay finishes")
        delegateMock.finishReplayExpectation = exp

        // Start first replay, then immediately restart
        presenter.startReplay(strokes: strokes, transform: .identity)
        delegateMock.replayedDrawings.removeAll()
        presenter.startReplay(strokes: strokes, transform: .identity)

        wait(for: [exp], timeout: 5.0)

        // After the second (fresh) replay completes, stroke count should match
        XCTAssertEqual(delegateMock.replayStrokeCount, 3)
    }

    // MARK: - stopReplay

    func test_DrawingReplayPresenter_stopReplayDuringActiveReplay_stopsCallbacks() {
        let strokes = makeStrokes(count: 20)
        let exp = expectation(description: "at least one stroke replayed")
        delegateMock.replayStrokeExpectation = exp

        presenter.startReplay(strokes: strokes, transform: .identity)

        wait(for: [exp], timeout: 2.0)

        let countBeforeStop = delegateMock.replayStrokeCount
        presenter.stopReplay()

        // Wait a bit to confirm no more callbacks fire
        let noMore = expectation(description: "no more callbacks")
        noMore.isInverted = true
        delegateMock.finishReplayExpectation = noMore

        wait(for: [noMore], timeout: 0.3)
        XCTAssertEqual(delegateMock.replayStrokeCount, countBeforeStop)
        XCTAssertFalse(delegateMock.didFinishReplayCalled)
    }

    func test_DrawingReplayPresenter_stopReplayOnFreshPresenter_doesNotCrash() {
        presenter.stopReplay()
        // No crash means success
    }

    func test_DrawingReplayPresenter_stopReplayCalledMultipleTimes_doesNotCrash() {
        let strokes = makeStrokes(count: 3)
        presenter.startReplay(strokes: strokes, transform: .identity)

        presenter.stopReplay()
        presenter.stopReplay()
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

// MARK: - Test Helpers

private extension DrawingReplayPresenterTests {

    /// Creates an array of simple PKStrokes for testing.
    func makeStrokes(count: Int) -> [PKStroke] {
        (0..<count).map { index in
            let offset = CGFloat(index) * 20
            let points = [
                PKStrokePoint(
                    location: CGPoint(x: offset, y: offset),
                    timeOffset: 0,
                    size: CGSize(width: 2, height: 2),
                    opacity: 1,
                    force: 1,
                    azimuth: 0,
                    altitude: .pi / 2
                ),
                PKStrokePoint(
                    location: CGPoint(x: offset + 10, y: offset + 10),
                    timeOffset: 0.1,
                    size: CGSize(width: 2, height: 2),
                    opacity: 1,
                    force: 1,
                    azimuth: 0,
                    altitude: .pi / 2
                )
            ]
            let path = PKStrokePath(controlPoints: points, creationDate: Date())
            return PKStroke(ink: PKInk(.pen, color: .black), path: path)
        }
    }
}
