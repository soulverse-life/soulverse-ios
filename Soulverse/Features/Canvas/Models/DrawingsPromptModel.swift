//
//  DrawingsPromptModel.swift
//  Soulverse
//

import UIKit

/// Represents a drawing art-therapy prompt with its associated template.
struct DrawingsPrompt: Codable {
    let templateName: String?            // Name of the image asset in DrawingTemplate
    let artTherapyPrompt: String         // Main prompt question
    let reflectiveQuestion: String?      // Optional reflective question
    let category: DrawingsPromptCategory // Which pool this prompt belongs to

    /// Returns the UIImage for this prompt's template, if available.
    var templateImage: UIImage? {
        guard let name = templateName, !name.isEmpty else { return nil }
        return UIImage(named: name)
    }

    init(
        templateName: String?,
        artTherapyPrompt: String,
        reflectiveQuestion: String?,
        category: DrawingsPromptCategory
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
enum DrawingsPromptCategory: Equatable {
    case general
    case single(EmotionType)
    case mixed
}

/// Response structure for the JSON file
private struct DrawingsPromptsResponse: Codable {
    let prompts: [DrawingsPrompt]
}

/// Manager for accessing and filtering drawing prompts.
struct DrawingsPromptManager {

    private static var _cachedPrompts: [DrawingsPrompt]?

    /// Returns all available prompts (loaded from JSON)
    static var allPrompts: [DrawingsPrompt] {
        if let cached = _cachedPrompts {
            return cached
        }

        guard let url = Bundle.main.url(forResource: "drawings_prompts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(DrawingsPromptsResponse.self, from: data) else {
            return []
        }

        _cachedPrompts = response.prompts
        return response.prompts
    }

    // MARK: - Public API (RecordedEmotion-driven)

    /// Returns a random prompt drawn from the candidate pool for the user's
    /// recorded emotion. The pool can span multiple categories:
    /// - `nil` → `.general` ∪ `.mixed`
    /// - Combined dyad with sources (A, B) → `.single(A)` ∪ `.single(B)`
    /// - Intensity emotion → the family primary's pool (e.g. `.serenity`/
    ///   `.joy`/`.ecstasy` → `.single(.joy)`).
    ///
    /// `prompts` is exposed for testing; production callers omit it and the
    /// JSON-loaded pool is used.
    static func randomPrompt(
        for recordedEmotion: RecordedEmotion?,
        from prompts: [DrawingsPrompt] = allPrompts
    ) -> DrawingsPrompt? {
        let candidates = candidateCategories(for: recordedEmotion)
        return prompts.filter { candidates.contains($0.category) }.randomElement()
    }

    // MARK: - Category routing

    /// Maps a `RecordedEmotion` to the set of categories whose prompts are
    /// eligible to be shown. Returning a set (rather than a single category)
    /// lets combined dyads draw from both source primaries' pools and lets
    /// the no-emotion path mix `.general` and `.mixed` prompts together.
    static func candidateCategories(
        for recordedEmotion: RecordedEmotion?
    ) -> Set<DrawingsPromptCategory> {
        guard let recorded = recordedEmotion else {
            return [.general, .mixed]
        }
        if let sources = recorded.sourceEmotions {
            return [.single(sources.0), .single(sources.1)]
        }
        if let primary = recorded.primaryEmotion {
            return [.single(primary)]
        }
        return [.general]
    }
}

// MARK: - DrawingsPromptCategory + Hashable

extension DrawingsPromptCategory: Hashable {}
