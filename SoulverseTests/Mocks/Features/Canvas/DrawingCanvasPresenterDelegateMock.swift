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
    var didFinishDrawingId: String?
    var didFinishReflectiveQuestion: String?
    var didFailError: Error?

    /// Set before triggering the async action; fulfilled when didFinish or didFail is called.
    var expectation: XCTestExpectation?

    func didStartSavingDrawing() {
        didStartSaving = true
    }

    func didFinishSavingDrawing(drawingId: String, image: UIImage, reflectiveQuestion: String) {
        didFinishDrawingId = drawingId
        didFinishImage = image
        didFinishReflectiveQuestion = reflectiveQuestion
        expectation?.fulfill()
    }

    func didFailSavingDrawing(error: Error) {
        didFailError = error
        expectation?.fulfill()
    }
}
