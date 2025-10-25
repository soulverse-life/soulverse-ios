//
//  PromptOption.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum PromptOption: String, CaseIterable {
    case itFeelsLike = "It feels like"
    case itRemindsMeOf = "It reminds me of"
    case iSense = "I sense"
    case theEmotionIsLike = "The emotion is like"
    case inMyBodyIts = "In my body, it's"
    case theTextureIs = "The texture is"

    /// Display name for the prompt button
    var displayName: String {
        return rawValue
    }

    /// Placeholder text for the text field when this prompt is selected
    var placeholderText: String {
        switch self {
        case .itFeelsLike:
            return "\"It feels like _______.\"\nThink of an image, a movement, or an atmosphere that matches your feeling."
        case .itRemindsMeOf:
            return "\"It reminds me of _______.\"\nDescribe a memory, place, or experience that resonates with this emotion."
        case .iSense:
            return "\"I sense _______.\"\nWhat physical sensations or intuitions arise with this feeling?"
        case .theEmotionIsLike:
            return "\"The emotion is like _______.\"\nUse a metaphor or comparison to capture the essence of your emotion."
        case .inMyBodyIts:
            return "\"In my body, it's _______.\"\nWhere and how does this emotion manifest physically?"
        case .theTextureIs:
            return "\"The texture is _______.\"\nIf this emotion had a texture, what would it feel like?"
        }
    }
}
