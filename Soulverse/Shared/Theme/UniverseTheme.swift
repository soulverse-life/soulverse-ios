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
        UIColor(red: 103.0/255.0, green: 18.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var secondaryColor: UIColor {
        UIColor(red: 102.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
    }

    var neutralLight: UIColor {
        UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1.0)
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

    var modalBackground: UIColor {
        UIColor(red: 26.0/255.0, green: 26.0/255.0, blue: 46.0/255.0, alpha: 1.0)
    }
}

// MARK: - Button Colors
extension UniverseTheme {
    var buttonPrimaryBackground: UIColor {
        UIColor(red: 103.0/255.0, green: 18.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var buttonPrimaryText: UIColor {
        UIColor.white
    }

    var buttonSecondaryBackground: UIColor {
        UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.6)
    }

    var buttonSecondaryText: UIColor {
        UIColor.white
    }

    var buttonDisabledBackground: UIColor {
        UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 0.6)
    }

    var buttonDisabledText: UIColor {
        UIColor(red: 136.0/255.0, green: 143.0/255.0, blue: 155.0/255.0, alpha: 1.0)
    }

    var circleUnselectedBackground: UIColor {
        UIColor(red: 174.0/255.0, green: 174.0/255.0, blue: 178.0/255.0, alpha: 1.0)
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

// MARK: - Progress Bar
extension UniverseTheme {
    var progressBarActive: UIColor {
        UIColor(red: 224.0/255.0, green: 151.0/255.0, blue: 255.0/255.0, alpha: 1.0)
    }

    var progressBarInactive: UIColor {
        UIColor(red: 217.0/255.0, green: 217.0/255.0, blue: 217.0/255.0, alpha: 1.0)
    }
}
