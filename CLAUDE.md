# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 📚 Documentation

**For comprehensive development guides, see the [Documentation](Documentation/) folder:**

- **[Documentation/DEVELOPMENT_GUIDELINES.md](Documentation/DEVELOPMENT_GUIDELINES.md)** - **READ THIS FIRST**
  - Core development principles and code style
  - ⚠️ **Important**: Always reuse existing components before creating new ones
  - 🚨 **CRITICAL**: ALL new features MUST use theme-aware colors (`.themeTextPrimary`, `.themeTextSecondary`, etc.)
  - ❌ **NEVER** use hardcoded colors like `.black`, `.darkGray`, `.lightGray` for UI elements
- **[Documentation/THEMING_GUIDE.md](Documentation/THEMING_GUIDE.md)** - Complete theming system guide
- **[Documentation/THEME_TESTING_EXAMPLE.swift](Documentation/THEME_TESTING_EXAMPLE.swift)** - Theme testing examples
- **[Documentation/README.md](Documentation/README.md)** - Documentation index

## Project Overview

Soulverse is an iOS application built with Swift and UIKit, following a VIPER-inspired architecture with MVP (Model-View-Presenter) patterns. The app appears to be a spiritual/wellness platform with features including:

- **Home**: Main dashboard/content hub
- **Feeling Planet**: Emotional wellness features
- **Canvas**: Creative/drawing functionality  
- **Seed**: Growth/development content
- **Wall**: Social/community features

The project was originally named "KonoSummit" but has been rebranded to "Soulverse" (evident from bundle identifiers and legacy references).

## Build & Development Commands

### Building the Project
```bash
# Open workspace (required due to CocoaPods)
open Soulverse.xcworkspace

# Build via xcodebuild
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug build

# Install dependencies
pod install
```

### LSP/IDE Support
```bash
# Rebuild SourceKit-LSP configuration
make rebuild-lsp

# Clean and rebuild LSP configuration  
make clean-lsp

# Show current project configuration
make show-config

# Install required dependencies (xcode-build-server via Homebrew)
make install-deps
```

### Fastlane Deployment
```bash
# Deploy development build to TestFlight
fastlane ios development

# Deploy release build to TestFlight  
fastlane ios release
```

## Architecture

### VIPER-Inspired Structure
The app follows a modified VIPER architecture with:

```
Features/
  FeatureName/
    Presenter/     - View coordination, presentation logic
    Views/         - UI components (UIKit)
    ViewModels/    - Business logic, data processing
```

### Navigation
- **MainViewController**: Tab bar controller with 5 main sections
- **AppCoordinator**: Handles deep linking and in-app routing
- Uses traditional UIKit navigation patterns

### Key Architectural Components

**Views**: Pure UI rendering, communicate via protocols
**Presenters**: Mediate between Views and ViewModels, handle lifecycle
**ViewModels**: Framework-agnostic business logic
**Services**: Shared services (API, Auth, Analytics, Notifications)

## Dependencies & Frameworks

### Core Dependencies (CocoaPods)
- **Moya**: Network abstraction layer
- **SnapKit**: Auto Layout DSL
- **Kingfisher**: Image loading/caching
- **IQKeyboardManagerSwift**: Keyboard handling
- **Firebase**: Analytics, Crashlytics, Remote Config, Messaging
- **Google/Facebook SDK**: Third-party authentication
- **SwiftMessages**: Toast/alert presentations
- **Lottie**: Animation support

### Key Services
- **Authentication**: Apple, Facebook, Google Sign-In + custom auth
- **Analytics**: Firebase Analytics with custom event tracking
- **API**: RESTful API communication via Moya
- **Notifications**: Push notifications with Firebase Messaging

## Configuration

### Build Targets
- **Soulverse**: Production app
- **Soulverse Dev**: Development app (separate bundle ID)
- **SoulverseTests**: Unit tests
- **SoulverseUITests**: UI tests

### Environment Configuration
Development and production environments controlled via build schemes:
- Dev: `https://summit-dev.thekono.com/api`
- Production: `https://summit.thekono.com/api`

### Localization
- Primary: Traditional Chinese (`zh-TW`)
- Secondary: English (`en`)

## Development Guidelines

### Localization
- 🌍 **MANDATORY**: ALL user-facing strings MUST use `NSLocalizedString()`
- ❌ **NEVER** hardcode UI text strings directly in code
- Add strings to both `en.lproj/Localizable.strings` and `zh-TW.lproj/Localizable.strings`
- Use descriptive keys with feature prefix (e.g., "mood_checkin_naming_title")
- Test with both English and Traditional Chinese before submitting

### Layout Constants
- 📐 Use global constants from `ViewComponentConstants` for shared values
- Only use local `Layout` enum for view-specific spacing/sizing
- Common global constants:
  - `navigationButtonSize`: Navigation bar buttons (44pt)
  - `actionButtonHeight`: Primary action buttons (48pt)
  - `navigationBarHeight`: Navigation bar height (56pt)
  - `colorDisplaySize`: Color display circles (30pt)

### Code Style
- Follow existing Swift conventions and naming patterns
- Use dependency injection via protocols for testability
- Implement comprehensive error handling with Result types
- Keep ViewModels framework-agnostic (no UIKit imports)

### Testing
- Unit test Presenters and ViewModels with mocks
- UI test critical user flows
- Mock external dependencies (API calls, authentication)

### Memory Management
- Use weak references in closures to prevent retain cycles
- Properly dispose of observers and delegates

## Common Development Tasks

### Adding New Features
1. Create feature folder following existing structure (Presenter/Views/ViewModels)
2. Implement protocols for communication between layers
3. Register navigation routes in AppCoordinator if needed
4. Add necessary tab bar integration in MainViewController

### API Integration
- Use existing APIService pattern via Moya
- Add models in appropriate ViewModels
- Handle authentication tokens through existing auth services

### UI Development
- Follow existing color schemes defined in UIColor extensions
- Use SnapKit for constraints
- Implement proper accessibility support
- Test on multiple device sizes

### Adding Analytics
- Use existing SummitTracker/CoreTracker infrastructure
- Define events in Events/ folder following existing patterns
- Track user interactions and feature usage