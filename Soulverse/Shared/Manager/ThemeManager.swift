//
//  ThemeManager.swift
//  Soulverse
//

import Foundation
import UIKit

/// Theme selection mode
enum ThemeMode {
    case manual           // User manually selects theme
    case automatic        // Theme changes based on time of day
}

/// Manages the app's current theme and handles theme switching
class ThemeManager {

    // MARK: - Singleton
    static let shared = ThemeManager()

    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let themeKey = "selectedTheme"
    private let themeModeKey = "themeMode"
    private var _currentTheme: Theme

    /// All available themes in the app
    let availableThemes: [Theme] = [
        SoulTheme(),
        UniverseTheme()
    ]

    /// The current theme selection mode
    var themeMode: ThemeMode {
        get {
            let modeRaw = userDefaults.integer(forKey: themeModeKey)
            return modeRaw == 1 ? .automatic : .manual
        }
        set {
            userDefaults.set(newValue == .automatic ? 1 : 0, forKey: themeModeKey)
            if newValue == .automatic {
                updateThemeBasedOnTime()
            }
        }
    }

    /// The currently active theme
    var currentTheme: Theme {
        if themeMode == .automatic {
            return getThemeForCurrentTime()
        }
        return _currentTheme
    }

    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Load saved theme or default to Soul theme
        if let savedThemeId = userDefaults.string(forKey: themeKey),
           let theme = availableThemes.first(where: { $0.id == savedThemeId }) {
            _currentTheme = theme
        } else {
            _currentTheme = UniverseTheme() // Default theme
        }

        // Update theme if in automatic mode
        if themeMode == .automatic {
            updateThemeBasedOnTime()
        }
    }

    // MARK: - Public Methods

    /// Switch to a specific theme by ID (sets mode to manual)
    /// - Parameter themeId: The ID of the theme to switch to
    /// - Returns: True if the theme was found and switched, false otherwise
    @discardableResult
    func switchTheme(to themeId: String) -> Bool {
        guard let theme = availableThemes.first(where: { $0.id == themeId }) else {
            print("⚠️ Theme '\(themeId)' not found")
            return false
        }

        themeMode = .manual
        _currentTheme = theme
        saveTheme()
        print("✅ Switched to theme: \(theme.displayName)")
        return true
    }

    /// Switch to a specific theme (sets mode to manual)
    /// - Parameter theme: The theme to switch to
    func switchTheme(to theme: Theme) {
        themeMode = .manual
        _currentTheme = theme
        saveTheme()
        print("✅ Switched to theme: \(theme.displayName)")
    }

    /// Toggle between available themes (useful for testing)
    func toggleTheme() {
        themeMode = .manual

        guard let currentIndex = availableThemes.firstIndex(where: { $0.id == _currentTheme.id }) else {
            return
        }

        let nextIndex = (currentIndex + 1) % availableThemes.count
        _currentTheme = availableThemes[nextIndex]
        saveTheme()
    }

    /// Update theme based on current time (if in automatic mode)
    func updateThemeBasedOnTime() {
        guard themeMode == .automatic else { return }

        let newTheme = getThemeForCurrentTime()
        if newTheme.id != _currentTheme.id {
            _currentTheme = newTheme
            print("✅ Auto-switched to theme: \(newTheme.displayName)")
        }
    }

    // MARK: - Private Methods

    private func saveTheme() {
        userDefaults.set(_currentTheme.id, forKey: themeKey)
    }

    /// Determines which theme to use based on current time
    /// Soul theme: 6am - 6pm
    /// Universe theme: 6pm - 6am
    private func getThemeForCurrentTime() -> Theme {
        let hour = Calendar.current.component(.hour, from: Date())

        // Soul theme during day (6am - 6pm), Universe at night (6pm - 6am)
        if hour >= 6 && hour < 18 {
            return SoulTheme()
        } else {
            return UniverseTheme()
        }
    }
}

// MARK: - Convenience Extensions

extension ThemeManager {
    /// Quick access to current theme colors
    var colors: Theme {
        return currentTheme
    }
}
