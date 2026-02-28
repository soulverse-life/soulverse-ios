//
//  DrawingServiceMock.swift
//  SoulverseTests
//

import UIKit
@testable import Soulverse

final class DrawingServiceMock: DrawingServiceProtocol {

    /// Simulates real Firebase behavior: completions arrive on a background thread.
    private let callbackQueue = DispatchQueue(label: "mock.drawing.callback")

    // MARK: - Stubbed Results

    var submitResult: Result<String, Error> = .success("mock-drawing-id")
    var fetchByDateResult: Result<[DrawingModel], Error> = .success([])
    var fetchByCheckinResult: Result<[DrawingModel], Error> = .success([])
    var deleteResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking

    var submitCallCount = 0
    var fetchByDateCallCount = 0
    var fetchByCheckinCallCount = 0
    var deleteCallCount = 0

    var lastSubmitUID: String?
    var lastFetchUID: String?
    var lastDeleteDrawingId: String?

    // MARK: - Protocol Methods

    func submitDrawing(
        uid: String,
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?,
        templateName: String?,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        submitCallCount += 1
        lastSubmitUID = uid
        let result = submitResult
        callbackQueue.async { completion(result) }
    }

    func fetchDrawings(
        uid: String,
        from startDate: Date,
        to endDate: Date?,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    ) {
        fetchByDateCallCount += 1
        lastFetchUID = uid
        let result = fetchByDateResult
        callbackQueue.async { completion(result) }
    }

    func fetchDrawings(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    ) {
        fetchByCheckinCallCount += 1
        lastFetchUID = uid
        let result = fetchByCheckinResult
        callbackQueue.async { completion(result) }
    }

    func deleteDrawing(
        uid: String,
        drawingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        deleteCallCount += 1
        lastDeleteDrawingId = drawingId
        let result = deleteResult
        callbackQueue.async { completion(result) }
    }
}
