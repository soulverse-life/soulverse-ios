//
//  DrawingServiceProtocol.swift
//  Soulverse
//

import UIKit

protocol DrawingServiceProtocol {
    func submitDrawing(
        uid: String,
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?,
        templateName: String?,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func fetchDrawings(
        uid: String,
        from startDate: Date,
        to endDate: Date?,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    )

    func fetchDrawings(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<[DrawingModel], Error>) -> Void
    )

    func deleteDrawing(
        uid: String,
        drawingId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}
