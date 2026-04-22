//
//  CanvasViewModel.swift
//

import Foundation

struct CanvasViewModel {
    var isLoading: Bool
    var currentPrompt: CanvasPrompt?
    var recordedEmotion: RecordedEmotion?  // The mood the user recorded, used to filter prompts
}
