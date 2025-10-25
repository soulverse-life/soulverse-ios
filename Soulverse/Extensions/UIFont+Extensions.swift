//
//  UIFont+Extensions.swift
//  Soulverse
//
//  Custom font extensions for Noto Sans TC
//

import UIKit

extension UIFont {

    /// Returns Noto Sans TC font with the specified size and weight
    /// Supports Dynamic Type scaling based on system accessibility settings
    ///
    /// - Parameters:
    ///   - size: The point size of the font
    ///   - weight: The weight of the font
    ///   - scalable: Whether the font should scale with accessibility text size settings (default: true)
    /// - Returns: UIFont instance with Noto Sans TC, scaled if requested
    static func projectFont(
        ofSize size: CGFloat,
        weight: UIFont.Weight = .regular,
        scalable: Bool = true
    ) -> UIFont {
        let fontName = "NotoSansTC"

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
            .name: fontName,
            .size: size
        ]).addingAttributes([
            UIFontDescriptor.AttributeName.traits: [
                UIFontDescriptor.TraitKey.weight: weightValue
            ]
        ])

        // Create custom font
        let customFont = UIFont(descriptor: fontDescriptor, size: size)

        // Return scaled font if scalable is true
        guard scalable else {
            return customFont
        }

        // Use UIFontMetrics to scale the font based on accessibility settings
        let fontMetrics = UIFontMetrics.default
        return fontMetrics.scaledFont(for: customFont)
    }

    /// Convenience method to get Noto Sans TC with regular weight
    /// - Parameters:
    ///   - size: The point size of the font
    ///   - scalable: Whether the font should scale with accessibility text size settings (default: true)
    /// - Returns: UIFont instance with regular weight
    static func projectFont(ofSize size: CGFloat, scalable: Bool = true) -> UIFont {
        return projectFont(ofSize: size, weight: .regular, scalable: scalable)
    }
}
