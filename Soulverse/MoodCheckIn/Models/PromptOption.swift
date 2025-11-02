//
//  PromptOption.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum PromptOption: String, CaseIterable {
    case itFeelsLike
    case itRemindsMeOf
    case iSense
    case theEmotionIsLike
    case inMyBodyIts
    case theTextureIs

    /// Display name for the prompt button
    var displayName: String {
        switch self {
        case .itFeelsLike:
            return NSLocalizedString("prompt_option_it_feels_like", comment: "")
        case .itRemindsMeOf:
            return NSLocalizedString("prompt_option_it_reminds_me_of", comment: "")
        case .iSense:
            return NSLocalizedString("prompt_option_i_sense", comment: "")
        case .theEmotionIsLike:
            return NSLocalizedString("prompt_option_the_emotion_is_like", comment: "")
        case .inMyBodyIts:
            return NSLocalizedString("prompt_option_in_my_body_its", comment: "")
        case .theTextureIs:
            return NSLocalizedString("prompt_option_the_texture_is", comment: "")
        }
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
