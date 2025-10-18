//
//  Theme.swift
//  Soulverse
//

import UIKit

/// Protocol defining the theme color scheme and visual properties
protocol Theme: Identifiable where ID == String {
    // Theme identity
    var displayName: String { get }

    // Primary colors
    var primaryColor: UIColor { get }
    var secondaryColor: UIColor { get }

    // Neutral colors
    var neutralLight: UIColor { get }
    var neutralMedium: UIColor { get }
    var neutralDark: UIColor { get }

    // Background - supports multiple gradient colors
    var backgroundGradientColors: [UIColor] { get }
    var backgroundGradientDirection: GradientDirection { get }
    var backgroundGradientLocations: [NSNumber]? { get } // Optional: specify where each color stops (0.0 to 1.0)

    // Text colors
    var textPrimary: UIColor { get }
    var textSecondary: UIColor { get }
    var textDisabled: UIColor { get }

    // Component colors
    var cardBackground: UIColor { get }
    var cardShadow: UIColor { get }
    var separator: UIColor { get }

    // Button colors
    var buttonPrimaryBackground: UIColor { get }
    var buttonPrimaryText: UIColor { get }
    var buttonSecondaryBackground: UIColor { get }
    var buttonSecondaryText: UIColor { get }
    var buttonDisabledBackground: UIColor { get }
    var buttonDisabledText: UIColor { get }
    var buttonGradientColors: [UIColor] { get }

    // Navigation
    var navigationBarBackground: UIColor { get }
    var navigationBarText: UIColor { get }
    var navigationBarTint: UIColor { get }

    // Tab Bar
    var tabBarBackground: UIColor { get }
    var tabBarSelectedTint: UIColor { get }
    var tabBarUnselectedTint: UIColor { get }
    var tabBarSelectedItemGradientColors: [UIColor] { get }

    // Status
    var errorColor: UIColor { get }
    var successColor: UIColor { get }
    var warningColor: UIColor { get }
}

/// Gradient direction for background
enum GradientDirection {
    case topToBottom
    case bottomToTop
    case leftToRight
    case rightToLeft
    case topLeftToBottomRight
    case topRightToBottomLeft

    var startPoint: CGPoint {
        switch self {
        case .topToBottom:
            return CGPoint(x: 0.5, y: 0.0)
        case .bottomToTop:
            return CGPoint(x: 0.5, y: 1.0)
        case .leftToRight:
            return CGPoint(x: 0.0, y: 0.5)
        case .rightToLeft:
            return CGPoint(x: 1.0, y: 0.5)
        case .topLeftToBottomRight:
            return CGPoint(x: 0.0, y: 0.0)
        case .topRightToBottomLeft:
            return CGPoint(x: 1.0, y: 0.0)
        }
    }

    var endPoint: CGPoint {
        switch self {
        case .topToBottom:
            return CGPoint(x: 0.5, y: 1.0)
        case .bottomToTop:
            return CGPoint(x: 0.5, y: 0.0)
        case .leftToRight:
            return CGPoint(x: 1.0, y: 0.5)
        case .rightToLeft:
            return CGPoint(x: 0.0, y: 0.5)
        case .topLeftToBottomRight:
            return CGPoint(x: 1.0, y: 1.0)
        case .topRightToBottomLeft:
            return CGPoint(x: 0.0, y: 1.0)
        }
    }
}
