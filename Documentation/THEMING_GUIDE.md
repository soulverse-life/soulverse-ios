# Soulverse Theming System Guide

## Overview

The Soulverse app now has a flexible theming system that supports multiple color schemes with automatic time-based switching. Two themes are currently available:

- **Soul Theme** (Light): Light blue/cyan gradient, ideal for daytime use (6am - 6pm)
- **Universe Theme** (Dark): Deep purple/navy gradient, ideal for nighttime use (6pm - 6am)

## Architecture

### Core Components

1. **Theme Protocol** (`Soulverse/Shared/Theme/Theme.swift`)
   - Defines the structure for all themes
   - Includes colors for backgrounds, text, buttons, navigation, etc.

2. **Theme Implementations**
   - `SoulTheme.swift` - Light theme
   - `UniverseTheme.swift` - Dark theme

3. **ThemeManager** (`Soulverse/Shared/Manager/ThemeManager.swift`)
   - Singleton managing the current theme
   - Supports manual and automatic theme selection
   - Automatic mode switches themes based on time of day

4. **GradientView** (`Soulverse/Shared/Theme/GradientView.swift`)
   - Custom view for gradient backgrounds
   - Automatically checks for theme changes during layout updates

5. **UIColor Extensions** (`Soulverse/Extensions/UIColor+Extensions.swift`)
   - Dynamic theme-aware color properties
   - All theme colors are computed properties that fetch the current theme

## Usage

### Using Theme Colors in Your Code

Instead of hardcoded colors, use the theme-aware color properties:

```swift
// ✅ Good - Uses theme-aware colors
label.textColor = .themeTextPrimary
button.backgroundColor = .themeButtonPrimaryBackground
separatorView.backgroundColor = .themeSeparator

// ❌ Avoid - Hardcoded colors
label.textColor = .black
button.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
```

### Available Theme Colors

#### Text Colors
- `.themeTextPrimary` - Primary text color
- `.themeTextSecondary` - Secondary/subtitle text
- `.themeTextDisabled` - Disabled state text

#### Component Colors
- `.themeCardBackground` - Card/panel backgrounds
- `.themeSeparator` - Dividers and separators
- `.themePrimary` - Primary accent color
- `.themeSecondary` - Secondary accent color

#### Button Colors
- `.themeButtonPrimaryBackground` - Primary button background
- `.themeButtonPrimaryText` - Primary button text
- `.themeButtonDisabledBackground` - Disabled button background
- `.themeButtonDisabledText` - Disabled button text

#### Navigation & Tab Bar
- `.themeNavigationBackground` - Navigation bar background
- `.themeNavigationText` - Navigation bar text
- `.themeTabBarBackground` - Tab bar background
- `.themeTabBarSelectedTint` - Selected tab tint
- `.themeTabBarUnselectedTint` - Unselected tab tint

### Using Gradient Backgrounds

All ViewControllers that inherit from the base `ViewController` class automatically get gradient backgrounds:

```swift
class MyViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Gradient background is automatically applied!
    }
}
```

To disable gradient background for a specific view controller:

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    useGradientBackground = false
    view.backgroundColor = .white // Use custom background
}
```

### Manual Theme Switching

```swift
// Switch to a specific theme by ID
ThemeManager.shared.switchTheme(to: "soul")
ThemeManager.shared.switchTheme(to: "universe")

// Or switch to a theme instance
ThemeManager.shared.switchTheme(to: SoulTheme())

// Toggle between themes (useful for testing)
ThemeManager.shared.toggleTheme()
```

### Automatic Theme Switching (Time-based)

```swift
// Enable automatic theme switching based on time of day
ThemeManager.shared.themeMode = .automatic

// Disable automatic mode and use manual selection
ThemeManager.shared.themeMode = .manual
```

When in automatic mode:
- **Soul theme**: 6:00 AM - 6:00 PM
- **Universe theme**: 6:00 PM - 6:00 AM

### Accessing Current Theme

```swift
// Get current theme
let currentTheme = ThemeManager.shared.currentTheme
print("Current theme: \(currentTheme.displayName)")

// Access theme properties directly
let primaryColor = currentTheme.primaryColor
let backgroundColor = currentTheme.backgroundGradientStart
```

## Adding a New Theme

To add a new theme:

1. Create a new struct conforming to `Theme` protocol with organized extensions:

```swift
/// My New Theme - Description
struct MyNewTheme: Theme {
    let id = "myNewTheme"  // Unique identifier (from Identifiable)
    let displayName = "My New Theme"
}

// MARK: - Primary & Neutral Colors
extension MyNewTheme {
    var primaryColor: UIColor {
        UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0)
    }

    var secondaryColor: UIColor {
        UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1.0)
    }

    // ... other neutral colors
}

// MARK: - Background
extension MyNewTheme {
    var backgroundGradientColors: [UIColor] {
        [/* gradient colors */]
    }

    var backgroundGradientDirection: GradientDirection {
        .topToBottom
    }

    var backgroundGradientLocations: [NSNumber]? {
        nil
    }
}

// MARK: - Text Colors
extension MyNewTheme {
    var textPrimary: UIColor {
        // ...
    }
    // ... other text colors
}

// Continue with other extension sections:
// - Component Colors
// - Button Colors
// - Navigation Bar
// - Tab Bar
// - Status Colors
```

2. Add it to `ThemeManager.availableThemes`:

```swift
let availableThemes: [Theme] = [
    SoulTheme(),
    UniverseTheme(),
    MyNewTheme() // Add your new theme here
]
```

**Note**: Organizing theme properties into extensions by category (as shown above) makes the code more maintainable and easier to navigate. See `UniverseTheme.swift` and `SoulTheme.swift` for complete examples.

## How Theme Changes Work

The theming system uses a **pull-based approach** instead of notifications:

1. All theme colors are **computed properties** that always fetch from `ThemeManager.shared.currentTheme`
2. Views update their colors in `layoutSubviews()` by checking if the theme has changed
3. No need for notification observers or manual cleanup
4. Colors are always current when accessed

This design is perfect for automatic time-based theme switching, as views naturally update when they're laid out.

## Best Practices

### ✅ DO

- Use theme-aware color properties (`.themeTextPrimary`, etc.)
- Update theme colors in `layoutSubviews()` for custom views
- Inherit from base `ViewController` for automatic gradient backgrounds
- Use `GradientView` for gradient backgrounds in custom views

### ❌ DON'T

- Hardcode color values
- Cache theme colors in variables (they won't update when theme changes)
- Use deprecated color properties like `.appThemeColor`, `.themeMainColor`

## Testing Themes

### Quick Theme Toggle

For testing, you can add a debug gesture to toggle themes:

```swift
#if DEBUG
let tapGesture = UITapGestureRecognizer(target: self, action: #selector(debugToggleTheme))
tapGesture.numberOfTaps = 3
view.addGestureRecognizer(tapGesture)

@objc func debugToggleTheme() {
    ThemeManager.shared.toggleTheme()
}
#endif
```

### Test Automatic Mode

```swift
// Enable automatic mode
ThemeManager.shared.themeMode = .automatic

// Force update (useful in simulators)
ThemeManager.shared.updateThemeBasedOnTime()
```

## Migration from Old Colors

The following colors are deprecated and should be migrated:

| Old Color | New Color |
|-----------|-----------|
| `.appThemeColor` | Use `GradientView` instead |
| `.themeMainColor` | `.themePrimary` |
| `.themeSubColor` | `.themeSecondary` |
| `.primaryBlack` | `.themeTextPrimary` |
| `.primaryWhite` | `.themeTextPrimary` (or context-specific) |

## Theme Color Palette Reference

### Soul Theme (Light)
- Background: Light blue to cyan gradient (#87CEEB → #B0E0E6)
- Primary: Teal (#00BFBF)
- Text: Dark gray/black
- Buttons: Dark navy background, white text

### Universe Theme (Dark)
- Background: Deep purple to navy gradient (#1A1A2E → #2D1B69)
- Primary: Bright cyan (#00D9FF)
- Text: White
- Buttons: White background, dark text

## Troubleshooting

**Q: Colors aren't updating when I switch themes**
A: Make sure you're using theme-aware color properties (`.themeTextPrimary`) not static colors (`.black`)

**Q: Gradient background not showing**
A: Ensure your view controller inherits from `ViewController` and calls `super.viewDidLoad()`

**Q: How do I customize the automatic theme switching time?**
A: Edit the `getThemeForCurrentTime()` method in `ThemeManager.swift`

**Q: Can I add more than 2 themes?**
A: Yes! Just create new theme structs and add them to `availableThemes` in `ThemeManager`

## Support

For questions or issues with the theming system, check:
- Theme protocol: `Soulverse/Shared/Theme/Theme.swift`
- Theme manager: `Soulverse/Shared/Manager/ThemeManager.swift`
- Color extensions: `Soulverse/Extensions/UIColor+Extensions.swift`
