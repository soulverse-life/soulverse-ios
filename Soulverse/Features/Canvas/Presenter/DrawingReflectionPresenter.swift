//
//  DrawingReflectionPresenter.swift
//  Soulverse
//

import Foundation

// MARK: - Delegate Protocol

protocol DrawingReflectionPresenterDelegate: AnyObject {
    func didStartSavingReflection()
    func didFinishSavingReflection(answer: String)
    func didFailSavingReflection(error: Error)
}

// MARK: - Presenter Protocol

protocol DrawingReflectionPresenterType: AnyObject {
    var delegate: DrawingReflectionPresenterDelegate? { get set }
    func submitReflection(drawingId: String, answer: String)
}

// MARK: - Implementation

final class DrawingReflectionPresenter: DrawingReflectionPresenterType {

    weak var delegate: DrawingReflectionPresenterDelegate?

    private let user: UserProtocol
    private let drawingService: DrawingServiceProtocol
    private var isSaving = false

    init(user: UserProtocol = User.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared) {
        self.user = user
        self.drawingService = drawingService
    }

    func submitReflection(drawingId: String, answer: String) {
        guard !isSaving else { return }
        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let uid = user.userId else {
            delegate?.didFailSavingReflection(
                error: FirestoreDrawingService.ServiceError.notLoggedIn
            )
            return
        }

        isSaving = true
        delegate?.didStartSavingReflection()

        drawingService.updateDrawingReflection(
            uid: uid,
            drawingId: drawingId,
            answer: trimmed
        ) { [weak self] result in
            guard let self = self else { return }
            self.isSaving = false

            switch result {
            case .success:
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: Notification.DrawingDidChange),
                    object: nil
                )
                self.delegate?.didFinishSavingReflection(answer: trimmed)
            case .failure(let error):
                self.delegate?.didFailSavingReflection(error: error)
            }
        }
    }
}
