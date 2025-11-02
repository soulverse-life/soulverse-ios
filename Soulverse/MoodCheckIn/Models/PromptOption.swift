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
            return NSLocalizedString("prompt_placeholder_it_feels_like", comment: "")
        case .itRemindsMeOf:
            return NSLocalizedString("prompt_placeholder_it_reminds_me_of", comment: "")
        case .iSense:
            return NSLocalizedString("prompt_placeholder_i_sense", comment: "")
        case .theEmotionIsLike:
            return NSLocalizedString("prompt_placeholder_the_emotion_is_like", comment: "")
        case .inMyBodyIts:
            return NSLocalizedString("prompt_placeholder_in_my_body_its", comment: "")
        case .theTextureIs:
            return NSLocalizedString("prompt_placeholder_the_texture_is", comment: "")
        }
    }
}
