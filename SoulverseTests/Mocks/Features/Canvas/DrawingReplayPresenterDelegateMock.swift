//
//  DrawingReplayPresenterDelegateMock.swift
//  SoulverseTests
//

import PencilKit
@testable import Soulverse

final class DrawingReplayPresenterDelegateMock: DrawingReplayPresenterDelegate {
    var didStartLoadingCalled = false
    var loadedStrokes: [PKStroke]?
    var loadedBounds: CGRect?
    var failError: Error?
    var replayedDrawing: PKDrawing?
    var didFinishReplayCalled = false

    func didStartLoading() {
        didStartLoadingCalled = true
    }

    func didFinishLoading(strokes: [PKStroke], bounds: CGRect) {
        loadedStrokes = strokes
        loadedBounds = bounds
    }

    func didFailLoading(error: Error) {
        failError = error
    }

    func didReplayStroke(drawing: PKDrawing) {
        replayedDrawing = drawing
    }

    func didFinishReplay() {
        didFinishReplayCalled = true
    }
}
