//
//  CanvasPromptModel.swift
//  Soulverse
//

import UIKit

/// Represents a canvas art therapy prompt with its associated template.
struct CanvasPrompt: Codable {
    let templateName: String?          // Name of the image asset in DrawingTemplate
    let artTherapyPrompt: String       // Main prompt question
    let reflectiveQuestion: String?    // Optional reflective question
    let category: CanvasPromptCategory // Which pool this prompt belongs to

    /// Returns the UIImage for this prompt's template, if available.
    var templateImage: UIImage? {
        guard let name = templateName, !name.isEmpty else { return nil }
        return UIImage(named: name)
    }

    init(
        templateName: String?,
        artTherapyPrompt: String,
        reflectiveQuestion: String?,
        category: CanvasPromptCategory
    ) {
        self.templateName = templateName
        self.artTherapyPrompt = artTherapyPrompt
        self.reflectiveQuestion = reflectiveQuestion
        self.category = category
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case templateName
        case artTherapyPrompt
        case reflectiveQuestion
        case emotion // flat JSON key: null / "joy" / "mixed" / …
    }

    /// Sentinel string used in the JSON `"emotion"` field for the mixed pool.
    private static let mixedEmotionJSONValue = "mixed"

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.templateName = try container.decodeIfPresent(String.self, forKey: .templateName)
        self.artTherapyPrompt = try container.decode(String.self, forKey: .artTherapyPrompt)
        self.reflectiveQuestion = try container.decodeIfPresent(String.self, forKey: .reflectiveQuestion)

        let raw = try container.decodeIfPresent(String.self, forKey: .emotion)
        switch raw {
        case nil, "":
            self.category = .general
        case Self.mixedEmotionJSONValue:
            self.category = .mixed
        case let value?:
            self.category = EmotionType(rawValue: value).map { .single($0) } ?? .general
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(templateName, forKey: .templateName)
        try container.encode(artTherapyPrompt, forKey: .artTherapyPrompt)
        try container.encode(reflectiveQuestion, forKey: .reflectiveQuestion)
        switch category {
        case .general:
            try container.encodeNil(forKey: .emotion)
        case .single(let emotion):
            try container.encode(emotion.rawValue, forKey: .emotion)
        case .mixed:
            try container.encode(Self.mixedEmotionJSONValue, forKey: .emotion)
        }
    }
}

/// The pool a prompt belongs to.
/// - `general`: no specific emotion — shown in the Canvas tab without a mood filter.
/// - `single`: tied to one primary emotion from Plutchik's 8 petals (joy, anger, …).
/// - `mixed`: tied to any dyad (two-emotion combination, e.g. optimism = joy + anticipation).
enum CanvasPromptCategory: Equatable {
    case general
    case single(EmotionType)
    case mixed
}

/// Response structure for the JSON file
private struct CanvasPromptsResponse: Codable {
    let prompts: [CanvasPrompt]
}

/// Manager for accessing and filtering canvas prompts.
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

    // MARK: - Public API (RecordedEmotion-driven)

    /// Returns a random prompt that matches the user's recorded emotion.
    /// - `nil` → general prompt.
    /// - Combined dyad → mixed-pool prompt.
    /// - Intensity emotion → that primary's pool (e.g. `.serenity`/`.joy`/`.ecstasy` → joy pool).
    static func randomPrompt(for recordedEmotion: RecordedEmotion?) -> CanvasPrompt? {
        let target = category(for: recordedEmotion)
        return allPrompts.filter { $0.category == target }.randomElement()
    }

    // MARK: - Category routing

    /// Maps a `RecordedEmotion` to the category of prompts that should be shown.
    static func category(for recordedEmotion: RecordedEmotion?) -> CanvasPromptCategory {
        guard let recorded = recordedEmotion else { return .general }
        if recorded.isCombinedEmotion { return .mixed }
        guard let primary = recorded.primaryEmotion else { return .general }
        return .single(primary)
    }
}
