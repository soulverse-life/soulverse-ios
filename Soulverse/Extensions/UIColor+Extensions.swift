import UIKit

extension UIColor {

    // MARK: - Hex Color Initializer

    /// Initialize UIColor from a hex string (e.g., "#FF5733" or "FF5733")
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: CGFloat

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // MARK: - Theme-Aware Colors (Dynamic)

    /// Primary theme color - adapts to current theme
    static var themePrimary: UIColor {
        ThemeManager.shared.currentTheme.primaryColor
    }

    /// Secondary theme color - adapts to current theme
    static var themeSecondary: UIColor {
        ThemeManager.shared.currentTheme.secondaryColor
    }

    /// Primary text color - adapts to current theme
    static var themeTextPrimary: UIColor {
        ThemeManager.shared.currentTheme.textPrimary
    }

    /// Secondary text color - adapts to current theme
    static var themeTextSecondary: UIColor {
        ThemeManager.shared.currentTheme.textSecondary
    }

    /// Disabled text color - adapts to current theme
    static var themeTextDisabled: UIColor {
        ThemeManager.shared.currentTheme.textDisabled
    }

    /// Card background color - adapts to current theme
    static var themeCardBackground: UIColor {
        ThemeManager.shared.currentTheme.cardBackground
    }

    /// Separator color - adapts to current theme
    static var themeSeparator: UIColor {
        ThemeManager.shared.currentTheme.separator
    }

    /// Modal background color - adapts to current theme
    static var themeModalBackground: UIColor {
        ThemeManager.shared.currentTheme.modalBackground
    }

    /// Button primary background - adapts to current theme
    static var themeButtonPrimaryBackground: UIColor {
        ThemeManager.shared.currentTheme.buttonPrimaryBackground
    }

    /// Button secondary background - adapts to current theme
    static var themeButtonSecondaryBackground: UIColor {
        ThemeManager.shared.currentTheme.buttonSecondaryBackground
    }
    
    /// Button primary text - adapts to current theme
    static var themeButtonPrimaryText: UIColor {
        ThemeManager.shared.currentTheme.buttonPrimaryText
    }
    
    /// Button secondary text - adapts to current theme
    static var themeButtonSecondaryText: UIColor {
        ThemeManager.shared.currentTheme.buttonSecondaryText
    }

    /// Button disabled background - adapts to current theme
    static var themeButtonDisabledBackground: UIColor {
        ThemeManager.shared.currentTheme.buttonDisabledBackground
    }

    /// Button disabled text - adapts to current theme
    static var themeButtonDisabledText: UIColor {
        ThemeManager.shared.currentTheme.buttonDisabledText
    }

    /// Circle unselected background - adapts to current theme
    static var themeCircleUnselectedBackground: UIColor {
        ThemeManager.shared.currentTheme.circleUnselectedBackground
    }

    /// Navigation bar background - adapts to current theme
    static var themeNavigationBackground: UIColor {
        ThemeManager.shared.currentTheme.navigationBarBackground
    }

    /// Navigation bar text - adapts to current theme
    static var themeNavigationText: UIColor {
        ThemeManager.shared.currentTheme.navigationBarText
    }

    /// Tab bar background - adapts to current theme
    static var themeTabBarBackground: UIColor {
        ThemeManager.shared.currentTheme.tabBarBackground
    }

    /// Tab bar selected tint - adapts to current theme
    static var themeTabBarSelectedTint: UIColor {
        ThemeManager.shared.currentTheme.tabBarSelectedTint
    }

    /// Tab bar unselected tint - adapts to current theme
    static var themeTabBarUnselectedTint: UIColor {
        ThemeManager.shared.currentTheme.tabBarUnselectedTint
    }

    /// Progress bar active color (current step) - adapts to current theme
    static var themeProgressBarActive: UIColor {
        ThemeManager.shared.currentTheme.progressBarActive
    }

    /// Progress bar inactive color (completed and remaining) - adapts to current theme
    static var themeProgressBarInactive: UIColor {
        ThemeManager.shared.currentTheme.progressBarInactive
    }

    // MARK: - Legacy Theme Colors (Deprecated - use theme-aware colors above)

    @available(*, deprecated, message: "Use themePrimary instead")
    static let themeMainColor = UIColor(red: 0/255.0, green: 191.0/255.0, blue: 191.0/255.0, alpha: 1)

    // MARK: - Primary Colors (Static)

    static let primaryGray = UIColor(red: 199.0/255.0, green: 199.0/255.0, blue: 199.0/255.0, alpha: 1)
    static let primaryWhite = UIColor(red: 240.0/255.0, green: 240.0/255.0, blue: 240.0/255.0, alpha: 1)
    static let primaryBlack = UIColor(red: 34.0/255.0, green: 34.0/255.0, blue: 34.0/255.0, alpha: 1)
    static let primaryOrange = UIColor(red: 241.0/255.0, green: 87.0/255.0, blue: 0.0/255.0, alpha: 1)
    static let errorRed = UIColor(red: 246.0/255.0, green: 107.0/255.0, blue: 100.0/255.0, alpha: 1)

    static let subBlack = UIColor(red: 51.0/255.0, green: 51.0/255.0, blue: 51.0/255.0, alpha: 1)
    static let subGray = UIColor(red: 136.0/255.0, green: 143.0/255.0, blue: 155.0/255.0, alpha: 1)
    static let textGray = UIColor(red: 157.0/255.0, green: 157.0/255.0, blue: 157.0/255.0, alpha: 1)
    static let actionButtonBlack = UIColor(red: 4.0/255.0, green: 18.0/255.0, blue: 44.0/255.0, alpha: 1)

    static let actionButtonDisableGray = UIColor(red: 30.0/255.0, green: 42.0/255.0, blue: 66.0/255.0, alpha: 1)

    static let disableGray = UIColor(red: 199.0/255.0, green: 199.0/255.0, blue: 199.0/255.0, alpha: 1)
    static let basicSeparatorColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)

    static let shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.4)

    // MARK: - Background Colors (Static - Legacy)

    @available(*, deprecated, message: "Use GradientView for backgrounds instead")
    static let appThemeColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
    static let backgroundBlack = UIColor(red: 4.0/255.0, green: 18.0/255.0, blue: 44.0/255.0, alpha: 1)
    static let backgroundBlackClear = UIColor(red: 4.0/255.0, green: 18.0/255.0, blue: 44.0/255.0, alpha: 0)
    static let subBackgroundBlack = UIColor(red: 0/255.0, green: 48.0/255.0, blue: 77.0/255.0, alpha: 1)
    static let groupAreaBackgroundBlack = UIColor(red: 1, green: 1, blue: 1, alpha: 0.05)
}
