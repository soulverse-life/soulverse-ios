//
//  DrawingReplayPresenterDelegateMock.swift
//  SoulverseTests
//

import PencilKit
import XCTest
@testable import Soulverse

final class DrawingReplayPresenterDelegateMock: DrawingReplayPresenterDelegate {
    var didStartLoadingCalled = false
    var didStartLoadingCount = 0

    var loadedStrokes: [PKStroke]?
    var loadedBounds: CGRect?

    var failError: Error?
    var failCount = 0

    var replayedDrawings: [PKDrawing] = []
    var replayedDrawing: PKDrawing? { replayedDrawings.last }
    var replayStrokeCount: Int { replayedDrawings.count }

    var didFinishReplayCalled = false
    var didFinishReplayCount = 0

    /// Set before triggering async actions; fulfilled when didFinishReplay is called.
    var finishReplayExpectation: XCTestExpectation?

    /// Fulfilled on didReplayStroke — useful for verifying at least one stroke fires.
    var replayStrokeExpectation: XCTestExpectation?

    func didStartLoading() {
        didStartLoadingCalled = true
        didStartLoadingCount += 1
    }

    func didFinishLoading(strokes: [PKStroke], bounds: CGRect) {
        loadedStrokes = strokes
        loadedBounds = bounds
    }

    func didFailLoading(error: Error) {
        failError = error
        failCount += 1
    }

    func didReplayStroke(drawing: PKDrawing) {
        replayedDrawings.append(drawing)
        replayStrokeExpectation?.fulfill()
    }

    func didFinishReplay() {
        didFinishReplayCalled = true
        didFinishReplayCount += 1
        finishReplayExpectation?.fulfill()
    }
}
