//
//  CanvasViewModel.swift
//

import Foundation

struct CanvasViewModel {
    var isLoading: Bool
    var currentPrompt: CanvasPrompt?
    var emotionFilter: EmotionType?  // The emotion filter passed from outside
} 