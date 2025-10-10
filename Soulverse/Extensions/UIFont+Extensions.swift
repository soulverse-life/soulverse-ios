//
//  UIFont+Extensions.swift
//  Soulverse
//
//  Custom font extensions for Noto Sans TC
//

import UIKit

extension UIFont {

    /// Returns Noto Sans TC font with the specified size and weight
    /// Falls back to system font if custom font is unavailable
    ///
    /// - Parameters:
    ///   - size: The point size of the font
    ///   - weight: The weight of the font
    /// - Returns: UIFont instance with Noto Sans TC or system font as fallback
    static func projectFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
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

        // Create and return custom font
        return UIFont(descriptor: fontDescriptor, size: size)
    }

    /// Convenience method to get Noto Sans TC with regular weight
    /// - Parameter size: The point size of the font
    /// - Returns: UIFont instance with regular weight
    static func projectFont(ofSize size: CGFloat) -> UIFont {
        return projectFont(ofSize: size, weight: .regular)
    }
}
