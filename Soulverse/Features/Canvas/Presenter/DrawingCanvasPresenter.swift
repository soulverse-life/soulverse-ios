//
//  DrawingCanvasPresenter.swift
//  Soulverse
//

import UIKit

// MARK: - Delegate Protocol

protocol DrawingCanvasPresenterDelegate: AnyObject {
    func didStartSavingDrawing()
    func didFinishSavingDrawing(drawingId: String, image: UIImage, reflectiveQuestion: String)
    func didFailSavingDrawing(error: Error)
}

// MARK: - Presenter Protocol

protocol DrawingCanvasPresenterType: AnyObject {
    var delegate: DrawingCanvasPresenterDelegate? { get set }
    func submitDrawing(
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?,
        templateName: String?,
        reflectiveQuestion: String
    )
}

// MARK: - Implementation

final class DrawingCanvasPresenter: DrawingCanvasPresenterType {

    weak var delegate: DrawingCanvasPresenterDelegate?

    private let user: UserProtocol
    private let drawingService: DrawingServiceProtocol
    private var isSaving = false

    init(user: UserProtocol = User.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared) {
        self.user = user
        self.drawingService = drawingService
    }

    func submitDrawing(
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?,
        templateName: String?,
        reflectiveQuestion: String
    ) {
        guard !isSaving else { return }
        guard let uid = user.userId else {
            delegate?.didFailSavingDrawing(
                error: FirestoreDrawingService.ServiceError.notLoggedIn
            )
            return
        }

        isSaving = true
        delegate?.didStartSavingDrawing()

        drawingService.submitDrawing(
            uid: uid,
            image: image,
            recordingData: recordingData,
            checkinId: checkinId,
            promptUsed: promptUsed,
            templateName: templateName,
            reflectiveQuestion: reflectiveQuestion
        ) { [weak self] result in

            guard let self = self else { return }
            self.isSaving = false

            switch result {
            case .success(let drawingId):
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: Notification.DrawingDidChange),
                    object: nil
                )
                self.delegate?.didFinishSavingDrawing(
                    drawingId: drawingId,
                    image: image,
                    reflectiveQuestion: reflectiveQuestion
                )
            case .failure(let error):
                self.delegate?.didFailSavingDrawing(error: error)
            }
        }
    }
}
