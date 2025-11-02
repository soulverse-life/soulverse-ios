//
//  MoodCheckInData.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation
import UIKit

/// Data model to store all information collected during the mood check-in flow
struct MoodCheckInData {

    // MARK: - Sensing Step

    /// Selected color from the gradient slider (RGB)
    var selectedColor: UIColor?

    /// Color intensity selected (0.0 to 1.0, maps to 5 circles)
    var colorIntensity: Double = 0.5

    // MARK: - Naming Step

    /// Selected emotions with their intensities (max 2 emotions)
    var emotions: [(emotion: EmotionType, intensity: Double)] = []

    // MARK: - Shaping Step

    /// Selected prompt option
    var selectedPrompt: PromptOption?

    /// User's text response to the prompt
    var promptResponse: String?

    // MARK: - Attributing Step

    /// Selected life area
    var lifeArea: LifeAreaOption?

    // MARK: - Evaluating Step

    /// Selected evaluation option
    var evaluation: EvaluationOption?

    // MARK: - Validation

    /// Check if Sensing step is complete
    var isSensingComplete: Bool {
        return selectedColor != nil
    }

    /// Check if Naming step is complete (at least 1 emotion selected, max 2)
    var isNamingComplete: Bool {
        return !emotions.isEmpty && emotions.count <= 2
    }

    /// Check if Shaping step is complete
    var isShapingComplete: Bool {
        return selectedPrompt != nil && !(promptResponse?.isEmpty ?? true)
    }

    /// Check if Attributing step is complete
    var isAttributingComplete: Bool {
        return lifeArea != nil
    }

    /// Check if Evaluating step is complete
    var isEvaluatingComplete: Bool {
        return evaluation != nil
    }

    /// Check if all required data is collected
    var isComplete: Bool {
        return isSensingComplete &&
               isNamingComplete &&
               isShapingComplete &&
               isAttributingComplete &&
               isEvaluatingComplete
    }

    // MARK: - Convenience

    /// Get a hex string representation of the selected color
    var colorHexString: String? {
        guard let color = selectedColor else { return nil }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return String(format: "#%02X%02X%02X",
                     Int(red * 255),
                     Int(green * 255),
                     Int(blue * 255))
    }
}
