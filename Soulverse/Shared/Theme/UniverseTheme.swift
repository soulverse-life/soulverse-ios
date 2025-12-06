//
//  UniverseTheme.swift
//  Soulverse
//

import UIKit

/// Universe Theme - Dark, cosmic theme with deep purple/navy gradient
struct UniverseTheme: Theme {
    let id = "universe"
    let displayName = "Universe"
}

// MARK: - Primary & Neutral Colors
extension UniverseTheme {
    var primaryColor: UIColor {
        UIColor(red: 157.0/255.0, green: 92.0/255.0, blue: 195.0/255.0, alpha: 1.0)
    }

    var secondaryColor: UIColor {
        UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    }

    var neutralLight: UIColor {
        UIColor(red: 199.0/255.0, green: 199.0/255.0, blue: 199.0/255.0, alpha: 1.0)
    }

    var neutralMedium: UIColor {
        UIColor(red: 136.0/255.0, green: 143.0/255.0, blue: 155.0/255.0, alpha: 1.0)
    }

    var neutralDark: UIColor {
        UIColor(red: 26.0/255.0, green: 26.0/255.0, blue: 46.0/255.0, alpha: 1.0)
    }
}

// MARK: - Background
extension UniverseTheme {
    var backgroundImageName: String? {
        "appBackground" // Use fixed background image
    }

    var backgroundGradientColors: [UIColor] {
        // Fallback gradient if image is not available
        [
            UIColor(red: 10.0/255.0, green: 6.0/255.0, blue: 20.0/255.0, alpha: 1.0),
            UIColor(red: 26.0/255.0, green: 20.0/255.0, blue: 85.0/255.0, alpha: 1.0),
            UIColor(red: 45.0/255.0, green: 27.0/255.0, blue: 105.0/255.0, alpha: 1.0)
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
extension UniverseTheme {
    var textPrimary: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var textSecondary: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.8)
    }

    var textDisabled: UIColor {
        UIColor(red: 136.0/255.0, green: 143.0/255.0, blue: 155.0/255.0, alpha: 1.0)
    }
}

// MARK: - Component Colors
extension UniverseTheme {
    var cardBackground: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.95)
    }

    var cardShadow: UIColor {
        UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)
    }

    var separator: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.1)
    }
}

// MARK: - Button Colors
extension UniverseTheme {
    var buttonPrimaryBackground: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var buttonPrimaryText: UIColor {
        UIColor(red: 26.0/255.0, green: 26.0/255.0, blue: 46.0/255.0, alpha: 1.0)
    }

    var buttonSecondaryBackground: UIColor {
        UIColor(red: 45.0/255.0, green: 27.0/255.0, blue: 105.0/255.0, alpha: 0.5)
    }

    var buttonSecondaryText: UIColor {
        UIColor.white
    }

    var buttonDisabledBackground: UIColor {
        UIColor(red: 30.0/255.0, green: 42.0/255.0, blue: 66.0/255.0, alpha: 1.0)
    }

    var buttonDisabledText: UIColor {
        UIColor(red: 136.0/255.0, green: 143.0/255.0, blue: 155.0/255.0, alpha: 1.0)
    }

    var buttonGradientColors: [UIColor] {
        [
            UIColor(red: 107.0/255.0, green: 46.0/255.0, blue: 157.0/255.0, alpha: 1.0),
            UIColor(red: 93.0/255.0, green: 219.0/255.0, blue: 207.0/255.0, alpha: 1.0)
        ]
    }
}

// MARK: - Navigation Bar
extension UniverseTheme {
    var navigationBarBackground: UIColor {
        .clear // Transparent to show gradient
    }

    var navigationBarText: UIColor {
        UIColor.white
    }

    var navigationBarTint: UIColor {
        UIColor(red: 0/255.0, green: 217.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }
}

// MARK: - Tab Bar
extension UniverseTheme {
    var tabBarBackground: UIColor {
        UIColor(red: 136.0/255.0, green: 143.0/255.0, blue: 155.0/255.0, alpha: 0.95)
    }

    var tabBarSelectedTint: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var tabBarUnselectedTint: UIColor {
        UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.5)
    }

    var tabBarSelectedItemGradientColors: [UIColor] {
        [
            UIColor(red: 0/255.0, green: 217.0/255.0, blue: 255.0/255.0, alpha: 1.0),
            UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
        ]
    }
}

// MARK: - Status Colors
extension UniverseTheme {
    var errorColor: UIColor {
        UIColor(red: 246.0/255.0, green: 107.0/255.0, blue: 100.0/255.0, alpha: 1.0)
    }

    var successColor: UIColor {
        UIColor(red: 0/255.0, green: 217.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var warningColor: UIColor {
        UIColor(red: 241.0/255.0, green: 87.0/255.0, blue: 0.0/255.0, alpha: 1.0)
    }
}
