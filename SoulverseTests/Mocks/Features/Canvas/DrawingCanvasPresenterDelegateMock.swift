//
//  DrawingCanvasPresenterDelegateMock.swift
//  SoulverseTests
//

import UIKit
import XCTest
@testable import Soulverse

final class DrawingCanvasPresenterDelegateMock: DrawingCanvasPresenterDelegate {
    var didStartSaving = false
    var didFinishImage: UIImage?
    var didFailError: Error?

    /// Set before triggering the async action; fulfilled when didFinish or didFail is called.
    var expectation: XCTestExpectation?

    func didStartSavingDrawing() {
        didStartSaving = true
    }

    func didFinishSavingDrawing(image: UIImage) {
        didFinishImage = image
        expectation?.fulfill()
    }

    func didFailSavingDrawing(error: Error) {
        didFailError = error
        expectation?.fulfill()
    }
}
