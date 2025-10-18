# Soulverse Documentation

Welcome to the Soulverse iOS app documentation! This folder contains all the guides and resources you need to start developing for Soulverse.

## 📚 Documentation Index

### Getting Started

1. **[DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md)** - **START HERE**
   - Core development principles
   - Code style guidelines
   - Architecture overview
   - Common patterns and best practices
   - **Important**: Always reuse existing components before creating new ones

### Feature-Specific Guides

2. **[THEMING_GUIDE.md](THEMING_GUIDE.md)**
   - Complete theming system documentation
   - How to use theme-aware colors
   - Adding new themes
   - Theme switching (manual and automatic)
   - Best practices for theme integration

3. **[THEME_TESTING_EXAMPLE.swift](THEME_TESTING_EXAMPLE.swift)**
   - Code examples for theme testing
   - Toggle buttons and gestures
   - Custom themed components
   - Theme-aware table cells

## 🚀 Quick Start

### For New Developers

1. Read the main project [CLAUDE.md](../CLAUDE.md) in the root directory
2. Read [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md) (this is essential!)
3. Review [THEMING_GUIDE.md](THEMING_GUIDE.md)
4. Check existing components in `Soulverse/Shared/ViewComponent/`
5. Check existing extensions in `Soulverse/Extensions/`

### Before Writing Any Code

**⚠️ Always check for existing components first!**

Ask yourself:
- Does this component already exist in `Shared/ViewComponent/`?
- Is there an extension that does this in `Extensions/`?
- Can I use the theming system for these colors?
- Am I inheriting from the correct base class?

## 📖 Documentation Structure

```
Documentation/
├── README.md                          # This file
├── DEVELOPMENT_GUIDELINES.md          # Core development guide ⭐
├── THEMING_GUIDE.md                  # Theme system guide
└── THEME_TESTING_EXAMPLE.swift       # Theme testing examples
```

## 🔑 Key Principles

### 1. Reuse Before Creating
Always check for existing shared components and extensions before implementing new features.

### 2. Theme-Aware
Use theme-aware colors (`.themeTextPrimary`) instead of hardcoded colors (`.black`).

### 3. Project Fonts
Use `.projectFont(ofSize:weight:)` instead of system fonts.

### 4. Consistent Architecture
Follow the VIPER-inspired architecture with Presenter/Views/ViewModels structure.

### 5. Base Classes
Inherit from `ViewController` for automatic gradient backgrounds and theme support.

## 🛠️ Available Shared Components

Located in `Soulverse/Shared/ViewComponent/`:

- **ViewController** - Base view controller with gradient background
- **SoulverseNavigationView** - Custom navigation bar
- **SoulverseTabBar** - Custom tab bar controller
- **SoulverseButton** - Standard button component
- **SummitInputTextField** - Custom text field

## 🎨 Theme System

The app supports multiple themes with automatic time-based switching:

- **Soul Theme** (Light): 6am - 6pm
- **Universe Theme** (Dark): 6pm - 6am

All UI should use theme-aware colors from `UIColor+Extensions.swift`.

## 📱 Architecture Overview

```
Features/
  FeatureName/
    Presenter/      # View coordination
    Views/          # UI components (UIKit)
    ViewModels/     # Business logic

Shared/
  ViewComponent/    # Reusable UI components ⭐
  Theme/           # Theme system
  Manager/         # Managers (Theme, User)
  Services/        # API, Auth, Analytics

Extensions/        # Swift extensions ⭐
```

## 🔍 Finding Information

### Need to...

**Add a new feature screen?**
→ See [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md) - "Creating a New Feature Screen"

**Use custom colors?**
→ See [THEMING_GUIDE.md](THEMING_GUIDE.md) - "Using Theme Colors"

**Style text or buttons?**
→ Check `Shared/ViewComponent/` first, then [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md)

**Understand the theme system?**
→ See [THEMING_GUIDE.md](THEMING_GUIDE.md)

**Test theme switching?**
→ See [THEME_TESTING_EXAMPLE.swift](THEME_TESTING_EXAMPLE.swift)

## 💡 Best Practices

✅ **DO:**
- Use existing shared components
- Use theme-aware colors
- Use project fonts
- Inherit from `ViewController`
- Follow the VIPER architecture
- Localize all user-facing strings

❌ **DON'T:**
- Create duplicate components
- Hardcode colors
- Use system fonts
- Inherit directly from `UIViewController`
- Mix business logic in views

## 🆘 Getting Help

1. Check the documentation in this folder
2. Review existing similar features in the codebase
3. Check the main [CLAUDE.md](../CLAUDE.md) for build/setup issues
4. Look at extensions in `Extensions/` for utilities

## 📝 Contributing to Documentation

When adding new shared components or patterns:

1. Update [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md)
2. Add examples if needed
3. Update this README if adding new documentation files

## 🔗 Related Files

- **[../CLAUDE.md](../CLAUDE.md)** - Main project documentation
- **Shared/ViewComponent/** - Shared UI components
- **Extensions/** - Swift extensions
- **Shared/Theme/** - Theme system implementation

---

**Happy coding! 🚀**

Remember: **Reuse existing components before creating new ones!**
