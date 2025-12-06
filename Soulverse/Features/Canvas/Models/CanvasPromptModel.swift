//
//  CanvasPromptModel.swift
//  Soulverse
//

import UIKit

/// Represents a canvas art therapy prompt with its associated template
struct CanvasPrompt: Codable {
    let templateName: String?  // Name of the image asset in DrawingTemplate
    let artTherapyPrompt: String  // Main prompt question
    let reflectiveQuestion: String?  // Optional reflective question
    let emotionStr: String?  // nil for general prompts, or specific emotion

    /// Returns the UIImage for this prompt's template, if available
    var templateImage: UIImage? {
        guard let name = templateName, !name.isEmpty else { return nil }
        return UIImage(named: name)
    }
    
    var emotion: EmotionType? {
          guard let emotionStr = emotionStr, !emotionStr.isEmpty else { return nil }
          return EmotionType(rawValue: emotionStr)
    }

    enum CodingKeys: String, CodingKey {
        case templateName
        case artTherapyPrompt
        case reflectiveQuestion
        case emotionStr = "emotion"
    }
}

/// Response structure for the JSON file
private struct CanvasPromptsResponse: Codable {
    let prompts: [CanvasPrompt]
        
}

/// Manager for accessing and filtering canvas prompts
struct CanvasPromptManager {

    private static var _cachedPrompts: [CanvasPrompt]?

    /// Returns all available prompts (loaded from JSON)
    static var allPrompts: [CanvasPrompt] {
        if let cached = _cachedPrompts {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "canvas_prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(CanvasPromptsResponse.self, from: data) else {
            return []
        }

        _cachedPrompts = response.prompts
        return response.prompts
    }

    /// Returns prompts filtered by emotion type
    /// - Parameter emotion: The emotion to filter by, or nil for general prompts (emotion = nil in data)
    static func prompts(for emotion: EmotionType?) -> [CanvasPrompt] {
        return allPrompts.filter { $0.emotion == emotion }
    }

    /// Returns a random prompt for the specified emotion
    /// - Parameter emotion: The emotion to filter by, or nil for general prompts
    static func randomPrompt(for emotion: EmotionType?) -> CanvasPrompt? {
        return prompts(for: emotion).randomElement()
    }
}
