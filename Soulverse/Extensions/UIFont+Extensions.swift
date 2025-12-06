//
//  UIFont+Extensions.swift
//  Soulverse
//
//  Custom font extensions with flexible font configuration
//

import UIKit

// MARK: - Font Configuration

/// Configuration for the project's font system
/// To change the app's font, simply modify the `current` property
enum FontConfiguration {
    case sfPro              // Apple's system font (SF Pro)
    case notoSansTC         // Custom Noto Sans TC font
    case custom(String)     // Any other custom font by name

    /// Current font configuration - Change this to switch fonts app-wide
    static let current: FontConfiguration = .sfPro

    /// Returns the font name for the configuration
    var fontName: String? {
        switch self {
        case .sfPro:
            return nil  // Use system font
        case .notoSansTC:
            return "NotoSansTC"
        case .custom(let name):
            return name
        }
    }

    /// Whether this configuration uses a variable font
    var isVariableFont: Bool {
        switch self {
        case .sfPro:
            return false
        case .notoSansTC:
            return true
        case .custom:
            return false  // Default to false, can be customized if needed
        }
    }
}

// MARK: - UIFont Extensions

extension UIFont {

    /// Returns the project font with the specified size and weight
    /// Supports Dynamic Type scaling based on system accessibility settings
    ///
    /// - Parameters:
    ///   - size: The point size of the font
    ///   - weight: The weight of the font
    ///   - scalable: Whether the font should scale with accessibility text size settings (default: true)
    /// - Returns: UIFont instance based on current FontConfiguration, scaled if requested
    static func projectFont(
        ofSize size: CGFloat,
        weight: UIFont.Weight = .regular,
        scalable: Bool = true
    ) -> UIFont {
        let baseFont: UIFont

        // Create font based on current configuration
        if let fontName = FontConfiguration.current.fontName {
            // Custom font
            if FontConfiguration.current.isVariableFont {
                baseFont = createVariableFont(name: fontName, size: size, weight: weight)
            } else {
                baseFont = createCustomFont(name: fontName, size: size, weight: weight)
            }
        } else {
            // System font (SF Pro)
            baseFont = UIFont.systemFont(ofSize: size, weight: weight)
        }

        // Return scaled font if scalable is true
        guard scalable else {
            return baseFont
        }

        // Use UIFontMetrics to scale the font based on accessibility settings
        let fontMetrics = UIFontMetrics.default
        return fontMetrics.scaledFont(for: baseFont)
    }

    /// Convenience method to get project font with regular weight
    /// - Parameters:
    ///   - size: The point size of the font
    ///   - scalable: Whether the font should scale with accessibility text size settings (default: true)
    /// - Returns: UIFont instance with regular weight
    static func projectFont(ofSize size: CGFloat, scalable: Bool = true) -> UIFont {
        return projectFont(ofSize: size, weight: .regular, scalable: scalable)
    }

    // MARK: - Private Helper Methods

    /// Creates a variable font with the specified weight
    private static func createVariableFont(name: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        // Map UIFont.Weight to font weight value (100-900)
        let weightValue: CGFloat = {
            switch weight {
            case .ultraLight:
                return 100
            case .thin:
                return 200
            case .light:
                return 300
            case .regular:
                return 400
            case .medium:
                return 500
            case .semibold:
                return 600
            case .bold:
                return 700
            case .heavy:
                return 800
            case .black:
                return 900
            default:
                return 400
            }
        }()

        // Create font descriptor with variation attributes for variable font
        let fontDescriptor = UIFontDescriptor(fontAttributes: [
            .name: name,
            .size: size
        ]).addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weightValue
            ]
        ])

        return UIFont(descriptor: fontDescriptor, size: size)
    }

    /// Creates a custom font with the specified weight
    private static func createCustomFont(name: String, size: CGFloat, weight: UIFont.Weight) -> UIFont {
        // For non-variable custom fonts, you may need to use specific font family names
        // based on the weight (e.g., "CustomFont-Bold", "CustomFont-Medium")
        let weightSuffix = fontWeightSuffix(for: weight)
        let fullFontName = weightSuffix.isEmpty ? name : "\(name)-\(weightSuffix)"

        if let customFont = UIFont(name: fullFontName, size: size) {
            return customFont
        }

        // Fallback to system font if custom font is not available
        print("⚠️ Warning: Custom font '\(fullFontName)' not found. Falling back to system font.")
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    /// Returns the font weight suffix for custom fonts
    private static func fontWeightSuffix(for weight: UIFont.Weight) -> String {
        switch weight {
        case .ultraLight:
            return "UltraLight"
        case .thin:
            return "Thin"
        case .light:
            return "Light"
        case .regular:
            return ""
        case .medium:
            return "Medium"
        case .semibold:
            return "Semibold"
        case .bold:
            return "Bold"
        case .heavy:
            return "Heavy"
        case .black:
            return "Black"
        default:
            return ""
        }
    }
}
