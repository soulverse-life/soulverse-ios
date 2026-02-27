//
//  DrawingReplayPresenter.swift
//  Soulverse
//

import Foundation
import PencilKit

// MARK: - Delegate Protocol

protocol DrawingReplayPresenterDelegate: AnyObject {
    func didStartLoading()
    func didFinishLoading(strokes: [PKStroke], bounds: CGRect)
    func didFailLoading(error: Error)
    func didReplayStroke(drawing: PKDrawing)
    func didFinishReplay()
}

// MARK: - Presenter Protocol

protocol DrawingReplayPresenterType: AnyObject {
    var delegate: DrawingReplayPresenterDelegate? { get set }
    func loadRecording(from urlString: String)
    func startReplay(strokes: [PKStroke], transform: CGAffineTransform)
    func stopReplay()
}

// MARK: - Implementation

final class DrawingReplayPresenter: DrawingReplayPresenterType {

    weak var delegate: DrawingReplayPresenterDelegate?

    private var replayTimer: Timer?
    private var currentStrokeIndex: Int = 0
    private var allStrokes: [PKStroke] = []
    private var replayTransform: CGAffineTransform = .identity

    // MARK: - Loading

    func loadRecording(from urlString: String) {
        guard let url = URL(string: urlString) else {
            delegate?.didFailLoading(error: ReplayError.invalidURL)
            return
        }

        delegate?.didStartLoading()

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.delegate?.didFailLoading(error: error)
                    return
                }

                guard let data = data else {
                    self.delegate?.didFailLoading(error: ReplayError.noData)
                    return
                }

                do {
                    let pkDrawing = try PKDrawing(data: data)
                    let strokes = pkDrawing.strokes
                    if strokes.isEmpty {
                        self.delegate?.didFailLoading(error: ReplayError.noStrokes)
                    } else {
                        self.delegate?.didFinishLoading(
                            strokes: strokes,
                            bounds: pkDrawing.bounds
                        )
                    }
                } catch {
                    self.delegate?.didFailLoading(error: error)
                }
            }
        }.resume()
    }

    // MARK: - Replay

    func startReplay(strokes: [PKStroke], transform: CGAffineTransform) {
        stopReplay()
        allStrokes = strokes
        replayTransform = transform
        currentStrokeIndex = 0

        let interval = max(0.05, 3.0 / Double(strokes.count))

        replayTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            guard self.currentStrokeIndex < self.allStrokes.count else {
                timer.invalidate()
                self.replayTimer = nil
                self.delegate?.didFinishReplay()
                return
            }

            self.currentStrokeIndex += 1
            let visibleStrokes = Array(self.allStrokes.prefix(self.currentStrokeIndex))
            var drawing = PKDrawing()
            drawing.strokes = visibleStrokes
            let transformed = drawing.transformed(using: self.replayTransform)

            self.delegate?.didReplayStroke(drawing: transformed)
        }
    }

    func stopReplay() {
        replayTimer?.invalidate()
        replayTimer = nil
    }

    deinit {
        stopReplay()
    }

    // MARK: - Errors

    enum ReplayError: LocalizedError {
        case invalidURL
        case noData
        case noStrokes

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid recording URL"
            case .noData:
                return "No recording data received"
            case .noStrokes:
                return "Recording contains no strokes"
            }
        }
    }
}
