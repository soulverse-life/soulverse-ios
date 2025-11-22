# Soulverse Development Guidelines

## Overview

This document provides essential guidelines for developing the Soulverse iOS application. Following these guidelines ensures code consistency, maintainability, and leverages the project's existing infrastructure.

## Core Principle: Reuse Before Creating

**⚠️ IMPORTANT: Always check for existing shared components and extensions before implementing new features.**

Before writing custom code, check these locations:
1. **Shared Components**: `Soulverse/Shared/ViewComponent/`
2. **Extensions**: `Soulverse/Extensions/`
3. **Theme System**: `Soulverse/Shared/Theme/`
4. **Managers**: `Soulverse/Shared/Manager/`
5. **Services**: `Soulverse/Shared/Services/`

## Quick Start Checklist

- [ ] Read this guide completely
- [ ] Review `CLAUDE.md` for project overview
- [ ] Check `THEMING_GUIDE.md` for theming system
- [ ] Review existing components in `Shared/ViewComponent/`
- [ ] Review existing extensions in `Extensions/`
- [ ] Understand the VIPER-inspired architecture

## Architecture

### VIPER-Inspired Structure

```
Features/
  FeatureName/
    Presenter/     - View coordination, presentation logic
    Views/         - UI components (UIKit)
    ViewModels/    - Business logic, data processing
```

### Key Architectural Principles

1. **Separation of Concerns**: Keep Views, Presenters, and ViewModels separate
2. **Protocol-Oriented**: Use protocols for communication between layers
3. **Dependency Injection**: Pass dependencies through initializers
4. **Framework-Agnostic ViewModels**: No UIKit imports in ViewModels

## Using Existing Shared Components

### Available Shared Components

Located in `Soulverse/Shared/ViewComponent/`:

#### 1. **SoulverseNavigationView**
Custom navigation bar for all feature screens.

```swift
private lazy var navigationView: SoulverseNavigationView = {
    let view = SoulverseNavigationView(title: NSLocalizedString("my_screen", comment: ""))
    return view
}()
```

#### 2. **SoulverseTabBar**
Custom tab bar controller with theme support.

```swift
// Already implemented in MainViewController
// Supports 5 tabs: InnerCosmo, Insight, Canvas, Tools, Quest
```

#### 3. **SoulverseButton**
Standard button component with delegate pattern.

```swift
let button = SoulverseButton(
    title: "Click Me",
    image: UIImage(named: "icon"),
    delegate: self
)
```

#### 4. **ViewController (Base Class)**
Base view controller with automatic gradient background and loading support.

```swift
class MyViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Gradient background automatically applied
        // Access to showLoading property
    }
}
```

#### 5. **SummitInputTextField**
Custom text field component.

```swift
let textField = SummitInputTextField()
// Pre-styled text field
```

### Available Extensions

Located in `Soulverse/Extensions/`:

#### UIColor Extensions
**✅ Always use theme-aware colors**

```swift
// Theme-aware colors (automatically adapt to current theme)
label.textColor = .themeTextPrimary
button.backgroundColor = .themeButtonPrimaryBackground
separator.backgroundColor = .themeSeparator

// Legacy static colors (use sparingly)
.primaryGray, .primaryOrange, .errorRed
```

#### UIFont Extensions
**✅ Always use project fonts**

```swift
// Use project font (Noto Sans TC)
label.font = .projectFont(ofSize: 16, weight: .medium)
titleLabel.font = .projectFont(ofSize: 24, weight: .bold)

// Available weights: .ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black
```

#### Other Extensions
- `UIViewController+Extensions` - Common view controller utilities
- `UIButton+Extensions` - Button utilities
- `UITextField+Extensions` - Text field utilities
- `String+Extension` - String utilities
- `Array+Extensions` - Array utilities

## Development Rules

### 1. Component Reuse

**❌ DON'T:**
```swift
// Creating custom button when SoulverseButton exists
class MyCustomButton: UIButton {
    // Duplicating functionality...
}
```

**✅ DO:**
```swift
// Use existing SoulverseButton
let button = SoulverseButton(
    title: "Action",
    image: nil,
    delegate: self
)
```

### 2. Color Usage ⚠️ CRITICAL

**🚨 MANDATORY: ALL new features MUST use theme-aware colors. No exceptions.**

Never use hardcoded colors like `.black`, `.white`, `.gray`, `.darkGray`, `.lightGray` for any UI elements.

**❌ DON'T:**
```swift
// Hardcoded colors - NEVER DO THIS
label.textColor = .black
label.textColor = .darkGray
label.textColor = .lightGray
button.tintColor = .black
view.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
layer.borderColor = UIColor.black.cgColor
```

**✅ DO:**
```swift
// Theme-aware colors - ALWAYS USE THESE
label.textColor = .themeTextPrimary        // Primary text (titles, labels)
label.textColor = .themeTextSecondary      // Secondary text (subtitles, descriptions)
label.textColor = .themeTextDisabled       // Disabled/placeholder text
button.tintColor = .themeTextPrimary       // Button tints
view.backgroundColor = .themeCardBackground // Card backgrounds
layer.borderColor = UIColor.themeTextPrimary.cgColor // For borders/shadows
```

**Available Theme Colors:**
- **Text**: `.themeTextPrimary`, `.themeTextSecondary`, `.themeTextDisabled`
- **Theme**: `.themePrimary`, `.themeSecondary`
- **Backgrounds**: `.themeCardBackground`, `.themeNavigationBackground`, `.themeTabBarBackground`
- **Buttons**: `.themeButtonPrimaryBackground`, `.themeButtonPrimaryText`, `.themeButtonDisabledBackground`, `.themeButtonDisabledText`
- **Navigation**: `.themeNavigationText`, `.themeNavigationBackground`
- **Tab Bar**: `.themeTabBarSelectedTint`, `.themeTabBarUnselectedTint`
- **Other**: `.themeSeparator`

**Why This Matters:**
- ✅ Ensures visual consistency across the entire app
- ✅ Automatically adapts when users switch themes
- ✅ Makes the codebase maintainable and scalable
- ✅ Follows the established design system
- ✅ Prevents visual bugs when themes change

**Real Example:**
```swift
// ❌ WRONG - Feature will break with theme changes
private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = .black  // Hard to read on dark backgrounds!
    return label
}()

// ✅ CORRECT - Feature adapts to any theme
private lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.textColor = .themeTextPrimary  // Always readable!
    return label
}()
```

### 3. Font Usage

**❌ DON'T:**
```swift
// System fonts
label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
```

**✅ DO:**
```swift
// Project fonts
label.font = .projectFont(ofSize: 16, weight: .medium)
```

### 4. View Controller Structure

**❌ DON'T:**
```swift
// Direct UIViewController subclass
class MyViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // No gradient background, no loading support
    }
}
```

**✅ DO:**
```swift
// Use base ViewController
class MyViewController: ViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Automatic gradient background
        // Access to showLoading property
    }
}
```

### 5. Navigation Bar

**❌ DON'T:**
```swift
// Custom navigation implementation
let titleLabel = UILabel()
titleLabel.text = "Screen Title"
// ... custom styling
```

**✅ DO:**
```swift
// Use SoulverseNavigationView
private lazy var navigationView: SoulverseNavigationView = {
    let view = SoulverseNavigationView(title: NSLocalizedString("screen_title", comment: ""))
    return view
}()
```

## Code Style Guidelines

### 1. Naming Conventions

```swift
// Classes: PascalCase
class MyViewController: ViewController { }

// Properties/Variables: camelCase
private let presenter: MyPresenterType
var isLoading: Bool = false

// Constants: camelCase
private let maximumRetries = 3

// Protocols: PascalCase with descriptive suffix
protocol MyViewPresenterType { }
protocol MyViewPresenterDelegate: AnyObject { }
```

### 2. File Organization

```swift
class MyViewController: ViewController {

    // MARK: - UI Elements
    private lazy var titleLabel: UILabel = { }()

    // MARK: - Properties
    private var presenter: MyPresenterType

    // MARK: - Lifecycle
    override func viewDidLoad() { }

    // MARK: - Setup
    private func setupUI() { }

    // MARK: - Actions
    @objc private func buttonTapped() { }
}

// MARK: - MyPresenterDelegate
extension MyViewController: MyPresenterDelegate { }
```

### 3. Layout with SnapKit

```swift
// Use SnapKit for constraints
view.addSubview(label)
label.snp.makeConstraints { make in
    make.top.equalTo(view.safeAreaLayoutGuide)
    make.left.right.equalToSuperview().inset(20)
}
```

### 4. Localization

```swift
// Always use localized strings
label.text = NSLocalizedString("key_name", comment: "")

// Never hardcode user-facing strings
label.text = "Hello" // ❌
```

## Theme System Integration

### Using Theme Colors

```swift
// Update colors that should adapt to theme
private func applyTheme() {
    titleLabel.textColor = .themeTextPrimary
    subtitleLabel.textColor = .themeTextSecondary
    cardView.backgroundColor = .themeCardBackground
}
```

### Custom Themed Views

```swift
class MyThemedView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        updateThemeColors()
    }

    private func updateThemeColors() {
        backgroundColor = .themeCardBackground
        layer.shadowColor = ThemeManager.shared.currentTheme.cardShadow.cgColor
    }
}
```

## Dependency Management

### Using CocoaPods

Key dependencies:
- **Moya**: Network layer
- **SnapKit**: Auto Layout DSL
- **Kingfisher**: Image loading
- **Firebase**: Analytics, Crashlytics, Remote Config
- **IQKeyboardManagerSwift**: Keyboard handling

```bash
# Install dependencies
pod install

# Always open workspace, not project
open Soulverse.xcworkspace
```

## Testing

### Running Tests

```bash
# Run unit tests
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -destination 'platform=iOS Simulator,name=iPhone 15' test

# Or use Fastlane
fastlane ios test
```

### Writing Tests

```swift
// Test ViewModels and Presenters
// Mock external dependencies
// Use dependency injection
```

## Git Workflow

### Commit Messages

```bash
# Good commit messages
git commit -m "feat: add user profile screen"
git commit -m "fix: resolve tab bar color issue"
git commit -m "refactor: organize theme files with extensions"
git commit -m "docs: update theming guide"

# Prefixes: feat, fix, refactor, docs, test, chore
```

### Branch Naming

```bash
feature/feature-name
fix/bug-description
refactor/what-was-refactored
```

## Common Patterns

### 1. Creating a New Feature Screen

```swift
// 1. Create ViewController
class NewFeatureViewController: ViewController {

    // 2. Add navigation view
    private lazy var navigationView: SoulverseNavigationView = {
        let view = SoulverseNavigationView(title: NSLocalizedString("feature_title", comment: ""))
        return view
    }()

    // 3. Add presenter
    private var presenter: NewFeaturePresenterType

    // 4. Initialize with dependency injection
    init(presenter: NewFeaturePresenterType = NewFeaturePresenter()) {
        self.presenter = presenter
        super.init(nibName: nil, bundle: nil)
        self.presenter.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 5. Setup UI
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.addSubview(navigationView)
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
    }
}

// 6. Implement presenter delegate
extension NewFeatureViewController: NewFeaturePresenterDelegate {
    func didUpdate(viewModel: NewFeatureViewModel) {
        // Update UI
    }
}
```

### 2. Adding a New Shared Component

```swift
// 1. Create in Soulverse/Shared/ViewComponent/
// 2. Use protocol-delegate pattern if needed
// 3. Make theme-aware
// 4. Document in this guide
```

### 3. Adding a New Extension

```swift
// 1. Create in Soulverse/Extensions/
// 2. Use clear, descriptive names
// 3. Document complex utilities
```

## Documentation Locations

- **`CLAUDE.md`**: Project overview and build instructions
- **`Documentation/THEMING_GUIDE.md`**: Complete theming system guide
- **`Documentation/THEME_TESTING_EXAMPLE.swift`**: Theme testing examples
- **`Documentation/DEVELOPMENT_GUIDELINES.md`**: This document

## Resources

### Project Structure
```
Soulverse/
├── Features/              # Feature modules
│   ├── InnerCosmo/
│   ├── Insight/
│   ├── Canvas/
│   ├── Tools/
│   └── Quest/
├── Shared/
│   ├── ViewComponent/     # Reusable UI components ⭐
│   ├── Theme/            # Theme system
│   ├── Manager/          # Managers (Theme, User, etc.)
│   └── Services/         # API, Auth, Analytics services
├── Extensions/           # Swift extensions ⭐
├── Onboarding/          # Onboarding flow
└── Main/                # Main tab bar controller
```

### Key Files to Review

1. **Base Classes**:
   - `Shared/ViewComponent/ViewController.swift`
   - `Shared/ViewComponent/SoulverseNavigationView.swift`

2. **Theme System**:
   - `Shared/Theme/Theme.swift`
   - `Shared/Theme/UniverseTheme.swift`
   - `Shared/Theme/SoulTheme.swift`
   - `Shared/Manager/ThemeManager.swift`

3. **Extensions**:
   - `Extensions/UIColor+Extensions.swift`
   - `Extensions/UIFont+Extensions.swift`

## Troubleshooting

### Issue: Colors not updating
**Solution**: Use theme-aware colors (`.themeTextPrimary`) not static colors

### Issue: Gradient background not showing
**Solution**: Inherit from `ViewController` base class, not `UIViewController`

### Issue: Custom font not working
**Solution**: Use `.projectFont(ofSize:weight:)` extension

### Issue: Component already exists
**Solution**: Review `Shared/ViewComponent/` before creating new components

## Getting Help

1. Check this documentation first
2. Review existing similar features in the codebase
3. Check `CLAUDE.md` for project-specific information
4. Review theme guide for theme-related questions

## Summary

**Remember the golden rule**:
> Always check for existing shared components and extensions before implementing new features.

This ensures:
- Code consistency across the app
- Reduced duplication
- Easier maintenance
- Faster development
- Better theme integration

Happy coding! 🚀
