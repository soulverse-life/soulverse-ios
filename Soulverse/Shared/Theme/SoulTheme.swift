//
//  SoulTheme.swift
//  Soulverse
//

import UIKit

/// Soul Theme - Light, airy theme with cyan/turquoise gradient
struct SoulTheme: Theme {
    let id = "soul"
    let displayName = "Soul"
}

// MARK: - Primary & Neutral Colors
extension SoulTheme {
    var primaryColor: UIColor {
        UIColor(red: 0/255.0, green: 191.0/255.0, blue: 191.0/255.0, alpha: 1.0)
    }

    var secondaryColor: UIColor {
        UIColor(red: 0/255.0, green: 101.0/255.0, blue: 101.0/255.0, alpha: 0.8)
    }

    var neutralLight: UIColor {
        UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1.0)
    }

    var neutralMedium: UIColor {
        UIColor(red: 199.0/255.0, green: 199.0/255.0, blue: 199.0/255.0, alpha: 1.0)
    }

    var neutralDark: UIColor {
        UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    }
}

// MARK: - Background
extension SoulTheme {
    var backgroundImageName: String? {
        nil // Use gradient for Soul theme
    }

    var backgroundGradientColors: [UIColor] {
        [
            UIColor(red: 164.0/255.0, green: 193.0/255.0, blue: 252.0/255.0, alpha: 1.0),
            UIColor(red: 110.0/255.0, green: 212.0/255.0, blue: 250.0/255.0, alpha: 1.0),
            UIColor(red: 69.0/255.0, green: 202.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        ]
    }

    var backgroundGradientDirection: GradientDirection {
        .topToBottom
    }

    var backgroundGradientLocations: [NSNumber]? {
        nil // Evenly distributed
    }
}

// MARK: - Text Colors
extension SoulTheme {
    var textPrimary: UIColor {
        UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    }

    var textSecondary: UIColor {
        UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    }

    var textDisabled: UIColor {
        UIColor(red: 157.0/255.0, green: 157.0/255.0, blue: 157.0/255.0, alpha: 1.0)
    }
}

// MARK: - Component Colors
extension SoulTheme {
    var cardBackground: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.9)
    }

    var cardShadow: UIColor {
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    }

    var separator: UIColor {
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    }
}

// MARK: - Button Colors
extension SoulTheme {
    var buttonPrimaryBackground: UIColor {
        UIColor(red: 4.0/255.0, green: 18.0/255.0, blue: 44.0/255.0, alpha: 1.0)
    }

    var buttonPrimaryText: UIColor {
        UIColor.white
    }

    var buttonSecondaryBackground: UIColor {
        UIColor.white
    }

    var buttonSecondaryText: UIColor {
        UIColor(red: 4.0/255.0, green: 18.0/255.0, blue: 44.0/255.0, alpha: 1.0)
    }

    var buttonDisabledBackground: UIColor {
        UIColor(red: 199.0/255.0, green: 199.0/255.0, blue: 199.0/255.0, alpha: 1.0)
    }

    var buttonDisabledText: UIColor {
        UIColor(red: 157.0/255.0, green: 157.0/255.0, blue: 157.0/255.0, alpha: 1.0)
    }

    var circleUnselectedBackground: UIColor {
        UIColor(red: 174.0/255.0, green: 174.0/255.0, blue: 178.0/255.0, alpha: 1.0)
    }
}

// MARK: - Navigation Bar
extension SoulTheme {
    var navigationBarBackground: UIColor {
        .clear // Transparent to show gradient
    }

    var navigationBarText: UIColor {
        UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1.0)
    }

    var navigationBarTint: UIColor {
        UIColor(red: 0/255.0, green: 191.0/255.0, blue: 191.0/255.0, alpha: 1.0)
    }
}

// MARK: - Tab Bar
extension SoulTheme {
    var tabBarBackground: UIColor {
        UIColor(red: 0/255.0, green: 191.0/255.0, blue: 191.0/255.0, alpha: 0.95)
    }

    var tabBarSelectedTint: UIColor {
        UIColor(red: 4.0/255.0, green: 18.0/255.0, blue: 44.0/255.0, alpha: 1.0)
    }

    var tabBarUnselectedTint: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.7)
    }

    var tabBarSelectedItemGradientColors: [UIColor] {
        [
            UIColor(red: 0/255.0, green: 217.0/255.0, blue: 255.0/255.0, alpha: 1.0),
            UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
        ]
    }
}

// MARK: - Status Colors
extension SoulTheme {
    var errorColor: UIColor {
        UIColor(red: 246.0/255.0, green: 107.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    }

    var successColor: UIColor {
        UIColor(red: 0/255.0, green: 191.0/255.0, blue: 191.0/255.0, alpha: 1.0)
    }

    var warningColor: UIColor {
        UIColor(red: 241.0/255.0, green: 87.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    }
}

// MARK: - Progress Bar
extension SoulTheme {
    var progressBarActive: UIColor {
        UIColor(red: 224.0/255.0, green: 151.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var progressBarInactive: UIColor {
        UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1.0)
    }
}
