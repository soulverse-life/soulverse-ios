//
//  DrawingPromptPresenter.swift
//  Soulverse
//

import Foundation

final class DrawingPromptPresenter: DrawingPromptPresenterType {

    weak var delegate: DrawingPromptPresenterDelegate?

    private let recordedEmotion: RecordedEmotion?

    private(set) var viewModel: DrawingPromptViewModel {
        didSet {
            delegate?.didUpdate(viewModel: viewModel)
        }
    }

    init(checkinId: String?, recordedEmotion: RecordedEmotion?) {
        self.recordedEmotion = recordedEmotion
        self.viewModel = DrawingPromptViewModel(
            prompt: nil,
            checkinId: checkinId
        )
    }

    func loadPrompt() {
        let emotionMatched = DrawingsPromptManager.randomPrompt(for: recordedEmotion)
        if let emotionMatched = emotionMatched {
            viewModel.prompt = emotionMatched
            return
        }

        // Fall back to a general prompt if the emotion-specific pool is empty.
        viewModel.prompt = DrawingsPromptManager.randomPrompt(for: nil)
    }
}
