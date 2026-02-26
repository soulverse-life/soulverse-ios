//
//  DrawingCanvasPresenter.swift
//  Soulverse
//

import UIKit

// MARK: - Delegate Protocol

protocol DrawingCanvasPresenterDelegate: AnyObject {
    func didStartSavingDrawing()
    func didFinishSavingDrawing(image: UIImage)
    func didFailSavingDrawing(error: Error)
}

// MARK: - Presenter Protocol

protocol DrawingCanvasPresenterType: AnyObject {
    var delegate: DrawingCanvasPresenterDelegate? { get set }
    func submitDrawing(
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?
    )
}

// MARK: - Implementation

final class DrawingCanvasPresenter: DrawingCanvasPresenterType {

    weak var delegate: DrawingCanvasPresenterDelegate?

    private var isSaving = false

    func submitDrawing(
        image: UIImage,
        recordingData: Data,
        checkinId: String?,
        promptUsed: String?
    ) {
        guard !isSaving else { return }
        guard let uid = User.shared.userId else {
            delegate?.didFailSavingDrawing(
                error: FirestoreDrawingService.ServiceError.notLoggedIn
            )
            return
        }

        isSaving = true
        delegate?.didStartSavingDrawing()

        FirestoreDrawingService.submitDrawing(
            uid: uid,
            image: image,
            recordingData: recordingData,
            checkinId: checkinId,
            promptUsed: promptUsed
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isSaving = false

                switch result {
                case .success:
                    self.delegate?.didFinishSavingDrawing(image: image)
                case .failure(let error):
                    self.delegate?.didFailSavingDrawing(error: error)
                }
            }
        }
    }
}
