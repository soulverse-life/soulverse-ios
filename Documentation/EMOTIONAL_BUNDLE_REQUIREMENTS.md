# Emotional Bundle - UI/UX Requirements Document

## 1. Navigation Flow

### Entry Point
**Self Care tab (Tools)** > tap "Emotional Bundle" card > **Bundle Hub** > tap any section card > **Section Editor**

### Presentation Strategy

| Transition | Type | Detail |
|---|---|---|
| Tools grid > Bundle Hub | **Push** (UINavigationController) | Standard push via `AppCoordinator.openEmotionBundle(from:)`. `hidesBottomBarWhenPushed = true`. Hero transition from the tapped `ToolsCollectionViewCell` (reuse existing `HeroTransitionID` pattern from `HeroTransitionID+Tools.swift`). |
| Bundle Hub > Section Editor | **Push** (same nav stack) | Push onto the same navigation controller. Custom `SoulverseNavigationView` with X (cancel) left, checkmark (save) right. |
| Section Editor > back to Hub | **Pop** (animated) | X button pops without saving. Checkmark button saves, then pops. |
| Bundle Hub > back to Tools | **Pop** (standard back) | Back arrow via `SoulverseNavigationView` with `showBackButton: true`. Uses default `SoulverseNavigationViewDelegate` behavior. |

### Back Gesture
- Swipe-to-go-back (`interactivePopGestureRecognizer`) enabled on all screens.
- On Section Editor screens, swipe-back should behave like X (cancel without saving). Show discard confirmation dialog if there are unsaved changes.

---

## 2. Screen-by-Screen Interaction Spec

### 2.1 Self Care Grid (tool_entry.png) - Existing Screen

**No new work required.** The `ToolsViewController` and `ToolsCollectionViewCell` already render the "Emotional Bundle" card. The only change needed is wiring the `.emotionBundle` case in `handleToolAction(_:sourceIndexPath:)` to call `AppCoordinator.openEmotionBundle(from:)`.

The Emotional Bundle cell should show a visual completion indicator (e.g., a small progress ring or checkmark badge overlay) once the user has filled at least one section. This requires a lightweight read of the local bundle data on `viewWillAppear`.

---

### 2.2 Bundle Hub (bundle_main.png)

**Purpose:** Overview of all 5 bundle sections with completion status at a glance.

#### Layout Hierarchy
```
ViewController (gradient background from base class)
  SoulverseNavigationView (title: "Emotional Bundle", showBackButton: true)
  UIScrollView
    UIStackView (vertical, spacing: 16)
      Header area
        Icon (sparkle/diamond, 32pt)
        Subtitle label ("Prepare helpful tools...")
      Section cards grid (2-column UICollectionView or manual grid)
        Red Flags card
        Support Me card
        Feel Calm card
        Stay Safe card
        Professional Support card
      Footer encouragement text
```

#### Layout Constants (private enum Layout)
| Constant | Value | Notes |
|---|---|---|
| `horizontalPadding` | 26 | Match `ViewComponentConstants.horizontalPadding` |
| `cardSpacing` | 12 | Horizontal gap between cards |
| `cardVerticalSpacing` | 16 | Vertical gap between card rows |
| `cardCornerRadius` | 20 | Match `ToolsCollectionViewCell` |
| `cardHeight` | 120 | Each section card |
| `iconSize` | 40 | Section icon in each card |
| `subtitleTopOffset` | 8 | Below navigation |
| `footerTopOffset` | 24 | Above bottom encouragement |
| `footerBottomInset` | 40 | Bottom breathing room |

#### Section Cards

Each card is a glass-effect card (iOS 26 `UIGlassEffect` with fallback per existing `ToolsCollectionViewCell` pattern):

| Section | Icon (SF Symbol) | Title | Completion indicator |
|---|---|---|---|
| Red Flags | `exclamationmark.triangle` | "Red Flags" | Checkmark overlay when >= 1 flag filled |
| Support Me | `person.2` | "Support Me" | Checkmark overlay when >= 1 contact filled |
| Feel Calm | `leaf` | "Feel Calm" | Checkmark overlay when >= 1 activity filled |
| Stay Safe | `shield` | "Stay Safe" | Checkmark overlay when action text is non-empty |
| Professional Support | `cross.case` | "Professional Support" | Checkmark overlay when >= 1 professional contact filled |

**Completion indicator**: A small filled circle with checkmark (SF Symbol `checkmark.circle.fill`, 20pt, `.themePrimary` tint) positioned at the top-trailing corner of the card, inset 12pt. Hidden when section is empty.

#### Interactive Elements
- Each card: tap to push corresponding Section Editor.
- Cards use subtle scale-down animation on press (`UIView.animate` scale 0.97, 0.1s), matching `SoulverseButton` tap feedback.

#### States
- **Empty bundle (first visit)**: All cards show without checkmarks. Footer text is visible. No special onboarding -- the subtitle + footer serve as guidance.
- **Partially filled**: Some cards have checkmarks, others do not.
- **Fully filled**: All 5 cards have checkmarks. Consider a subtle confetti animation or a "Bundle complete" badge on the header (future enhancement, not MVP).

#### Colors (theme-aware)
- Card background: glass effect (iOS 26) / `.themeCardBackground` fallback
- Title: `.themeTextPrimary`
- Subtitle/footer: `.themeTextSecondary`
- Icon tint: `.themeTextPrimary`
- Completion checkmark: `.themePrimary`

---

### 2.3 Red Flags Editor (bundle_red_flags.png)

**Purpose:** User documents 2 personal warning signs.

#### Navigation Bar
Custom `SoulverseNavigationView`-style bar:
- **Left**: X button (cancel) -- `UIImage(systemName: "xmark")`, tint `.themeTextPrimary`, 44pt touch target.
- **Right**: Checkmark button (save) -- `UIImage(systemName: "checkmark")`, tint `.themePrimary`, 44pt touch target. Disabled (alpha 0.4) when no changes have been made since last save.

Note: This is NOT a standard `SoulverseNavigationView` (which has back + title + right items). Build a reusable `BundleEditorNavigationView` with X-left, title-center (optional), checkmark-right pattern, since all 5 section editors share this layout.

#### Layout
```
BundleEditorNavigationView
UIScrollView (keyboard-aware, via IQKeyboardManagerSwift)
  UIStackView (vertical, spacing: 24)
    Section header
      Icon (exclamationmark.triangle, 24pt) + Title label
      "What tells me I'm having a hard time?"
    Red Flag 1 card (required)
      Label: "Red Flag 1"
      UITextView (multiline, 3-line min height, glass card background)
      Checkmark indicator (shown when text is non-empty)
    Red Flag 2 card (optional)
      Label: "Red Flag 2"
      UITextView (multiline, placeholder: "e.g., Being yelled at")
```

#### Text Input Component: `BundleTextEntryView`
A reusable component used across multiple editors:
- Glass-card background with `cornerRadius: 16`
- `UITextView` (NOT `UITextField` -- multiline support needed)
- Placeholder text in `.themeTextDisabled`
- Filled checkmark indicator (right side, `checkmark.circle.fill`, `.themePrimary`) when text is non-empty
- Min height: 48pt, max height: 120pt (auto-expands)
- Font: `.projectFont(ofSize: 14, weight: .regular)`, color `.themeTextPrimary`
- Character limit: 500 characters. No visible counter -- silently truncate at limit.

#### Validation
| Field | Required | Rule |
|---|---|---|
| Red Flag 1 | Yes | Must be non-empty to save. If empty on save tap, highlight border in `.primaryOrange` and shake animation. |
| Red Flag 2 | No | Can be empty. |

#### States
- **Empty**: Both fields show placeholder text. Save button disabled.
- **Partially filled**: Flag 1 has text (checkmark visible), Flag 2 empty. Save enabled.
- **Fully filled**: Both have text, both show checkmarks. Save enabled.
- **Pre-filled (return visit)**: Fields pre-populate with saved data.

#### Save Behavior
- Checkmark tap: validate, persist to local storage, pop to Hub.
- X tap: if changes exist since last save, show `SummitAlertView` discard confirmation dialog ("Discard changes?" / Cancel + Discard). If no changes, pop immediately.

---

### 2.4 Support Me Editor (bundle_support_me.png)

**Purpose:** User adds up to 2 emergency contacts.

#### Layout
```
BundleEditorNavigationView
UIScrollView
  UIStackView (vertical, spacing: 24)
    Section header (person.2 icon + "Who helps me feel safer or less alone?")
    Contact 1 card (required)
      "Contact 1" label
      BundleContactFormView
        Name field (SoulverseTextField, title: "Name", required)
        Phone field (SoulverseTextField, title: "Phone number", keyboard: .phonePad)
        Email field (SoulverseTextField, title: "Email", keyboard: .emailAddress)
        Relationship field (SoulverseTextField, title: "Relationship")
    Contact 2 card (optional)
      "Contact 2 (Optional)" label
      BundleContactFormView (same structure)
```

#### Reusable Component: `BundleContactFormView`
- Vertical stack of 4 `SoulverseTextField` instances
- Glass card background wrapping all fields
- Spacing between fields: 16pt
- Internal padding: 16pt on all sides

#### Validation
| Field | Contact 1 | Contact 2 |
|---|---|---|
| Name | Required | Optional (but required if any Contact 2 field is filled) |
| Phone | Optional | Optional |
| Email | Optional | Optional |
| Relationship | Optional | Optional |

- At least Name must be filled for Contact 1 to save.
- If Contact 2 has any field filled, Name becomes required for Contact 2 as well.
- Phone validation: allow digits, dashes, spaces, parentheses, plus sign. No strict format enforcement.
- Email validation: basic `contains("@")` check when non-empty. Show `.errorWithMessage("Invalid email")` via `SoulverseTextField.updateStatus()`.

#### States
- **Empty**: All fields show placeholders. Save disabled.
- **Minimum fill**: Contact 1 Name filled. Save enabled.
- **Full fill**: Both contacts fully filled.

---

### 2.5 Feel Calm Editor (bundle_feed_calm.png)

**Purpose:** User lists up to 3 self-soothing activities.

#### Layout
```
BundleEditorNavigationView
UIScrollView
  UIStackView (vertical, spacing: 20)
    Section header (leaf icon + "Things I can do to make me feel better")
    Activity 1 (required)
      BundleTextEntryView (placeholder: "e.g., Drawing helps me release stress")
    Activity 2 (Optional)
      "Activity 2 (Optional)" label
      BundleTextEntryView (placeholder: "e.g., Drinking cold water")
    Activity 3 (Optional)
      "Activity 3 (Optional)" label
      BundleTextEntryView (placeholder: "e.g., Go outside for 5 minutes")
```

#### Validation
| Field | Required |
|---|---|
| Activity 1 | Yes |
| Activity 2 | No |
| Activity 3 | No |

Same save/cancel behavior as Red Flags.

---

### 2.6 Stay Safe Editor (bundle_stay_safe.png)

**Purpose:** User documents one safety action.

#### Layout
```
BundleEditorNavigationView
UIScrollView
  UIStackView (vertical, spacing: 20)
    Section header (shield icon + "How can I make this moment feel safer?")
    Actions field
      "Actions" label
      BundleTextEntryView (larger, min 4 lines)
      Placeholder: "e.g., Remove risky objects, Step outside"
```

#### Validation
| Field | Required |
|---|---|
| Actions | Yes |

This is the simplest editor. Single text entry. Character limit: 1000.

---

### 2.7 Professional Support Editor (bundle_profession_support.png)

**Purpose:** Show hardcoded crisis resource + user's professional contact.

#### Layout
```
BundleEditorNavigationView
UIScrollView
  UIStackView (vertical, spacing: 24)
    Section header (cross.case icon + "Professional Support")

    Crisis Resource Card (NOT editable, always visible)
      Glass card, distinct styling (slightly different tint or border)
      "988 Suicide & Crisis Lifeline" title (.themeTextPrimary, semibold)
      "24/7" badge
      "Call or text 988" subtitle
      "Free and confidential support..." description (.themeTextSecondary)
      Tap action: prompt to call 988 (tel://988) via UIApplication.shared.open

    Professional Contact 1 (optional)
      "Professional Contact 1" label
      BundleProfessionalFormView
        Place/Clinic (SoulverseTextField, title: "Place / Clinic")
        Professional Name (SoulverseTextField, placeholder: "e.g., Dr. Louis Reves")
        Emergency Contact Number (SoulverseTextField, keyboard: .phonePad)
```

#### Crisis Resource Card: `CrisisResourceCardView`
- Static, non-editable, always present.
- Glass card with a subtle accent border (`.themePrimary` at 30% alpha, 1pt width).
- 988 icon or phone icon on the left.
- Tapping the card shows a `UIAlertController` confirmation: "Call 988 Suicide & Crisis Lifeline?" with Call and Cancel buttons. This ensures no accidental dialing.
- Accessibility: label reads "988 Suicide and Crisis Lifeline. 24/7 free and confidential support. Double tap to call."

#### Reusable Component: `BundleProfessionalFormView`
- Similar to `BundleContactFormView` but with 3 fields (Place, Name, Phone).
- All fields optional for save (the crisis resource is always there as a fallback).

#### Validation
- All professional contact fields are optional.
- Save button is always enabled on this screen (crisis resource counts as "filled").
- Phone validation same as Support Me.

---

## 3. Component Inventory

### New Reusable Components

| Component | Description | Used In |
|---|---|---|
| `BundleEditorNavigationView` | X (cancel) left, optional title center, checkmark (save) right. Delegate protocol with `didTapCancel()` and `didTapSave()`. | All 5 section editors |
| `BundleTextEntryView` | Glass-card text view with placeholder, checkmark indicator, auto-expand. | Red Flags, Feel Calm, Stay Safe |
| `BundleContactFormView` | Vertical stack of 4 `SoulverseTextField` in a glass card. Exposes contact data via struct. | Support Me |
| `BundleProfessionalFormView` | Vertical stack of 3 `SoulverseTextField` in a glass card. | Professional Support |
| `CrisisResourceCardView` | Static card showing 988 Lifeline info with tap-to-call. | Professional Support |
| `BundleSectionCardView` | Card used in Bundle Hub grid. Icon + title + completion indicator. Glass effect. | Bundle Hub |
| `BundleSectionHeaderView` | Icon + descriptive question label. Used at top of each editor. | All 5 editors |

### Existing Components Reused

| Component | Usage |
|---|---|
| `SoulverseNavigationView` | Bundle Hub screen (back button + title) |
| `SoulverseTextField` | Contact form fields (Name, Phone, Email, etc.) |
| `ViewController` (base class) | All new VCs inherit for gradient background |
| `SummitAlertView` | Discard confirmation dialogs |
| `ToolsCollectionViewCell` | Existing, no changes needed |
| Hero transitions | Cell-to-screen transition from Tools grid |

### Data Model

```swift
struct EmotionalBundle: Codable {
    var redFlags: RedFlagsSection
    var supportMe: SupportMeSection
    var feelCalm: FeelCalmSection
    var staySafe: StaySafeSection
    var professionalSupport: ProfessionalSupportSection
    var lastModified: Date
}

struct RedFlagsSection: Codable {
    var flag1: String  // required
    var flag2: String  // optional
}

struct SupportMeSection: Codable {
    var contacts: [EmergencyContact]  // max 2
}

struct EmergencyContact: Codable {
    var name: String
    var phone: String
    var email: String
    var relationship: String
}

struct FeelCalmSection: Codable {
    var activities: [String]  // max 3, index 0 required
}

struct StaySafeSection: Codable {
    var actions: String
}

struct ProfessionalSupportSection: Codable {
    var contacts: [ProfessionalContact]  // max 1 for now
}

struct ProfessionalContact: Codable {
    var placeName: String
    var professionalName: String
    var emergencyPhone: String
}
```

### Storage
- **Local persistence**: `UserDefaults` or a local JSON file via `FileManager` for the `EmotionalBundle` struct. Encoded/decoded via `Codable`.
- **Remote sync (future)**: Firestore document under `users/{uid}/emotionalBundle`. Not part of MVP.
- **Encryption consideration**: This data is sensitive. Use iOS Data Protection (`.completeUntilFirstUserAuthentication` minimum) on the stored file. For UserDefaults, rely on device-level encryption.

---

## 4. Accessibility Considerations

### VoiceOver Labels

| Element | Accessibility Label | Trait |
|---|---|---|
| Section card (Hub) | "{Section name}. {Completed/Not started}. Double tap to edit." | `.button` |
| X (cancel) button | "Cancel without saving" | `.button` |
| Checkmark (save) button | "Save changes" | `.button` |
| Text entry (empty) | "{Field name}. Empty. Double tap to edit." | `.none` (text field handles itself) |
| Text entry (filled) | "{Field name}. Filled. {Content preview}." | `.none` |
| Crisis resource card | "988 Suicide and Crisis Lifeline. Available 24/7. Free and confidential. Double tap to call." | `.button` |
| Completion checkmark | "Section complete" | `.image` |

### Dynamic Type
- All labels use `.projectFont(ofSize:weight:)`. Verify this supports Dynamic Type scaling. If not, add `.adjustsFontForContentSizeCategory = true` and use scaled fonts.
- Text entry views must grow vertically to accommodate larger text sizes.
- Ensure minimum touch target of 44x44pt on all interactive elements (already standard in codebase).

### Keyboard Navigation
- `IQKeyboardManagerSwift` handles keyboard avoidance automatically.
- Tab order should flow top-to-bottom through form fields.
- Return key on last field in a form should dismiss keyboard (not submit -- save is explicit via checkmark).

### Color Contrast
- All text must meet WCAG 2.1 AA contrast ratio (4.5:1 for body text, 3:1 for large text).
- Verify both Soul Theme (light) and Universe Theme (dark) meet requirements.
- Completion checkmark (`.themePrimary`) must be visible against card background in both themes.

---

## 5. Edge Cases

### First Visit (Empty Bundle)
- All section cards show "Not started" state (no checkmark).
- Each editor opens with empty fields and placeholders.
- Footer encouragement text on Hub is always visible regardless of completion state.

### Partial Save / Interrupted Editing
- Data is only persisted when user taps the checkmark (save) button.
- If user force-quits the app mid-edit, unsaved changes are lost. This is acceptable -- the discard dialog warns them.
- If user navigates away via swipe-back gesture with unsaved changes, show the same discard confirmation.

### Network Errors
- MVP uses local storage only. No network calls during save.
- Future Firestore sync should be fire-and-forget with local-first strategy (save locally immediately, sync in background, retry on failure).

### Very Long Text Input
- Character limits enforced silently: 500 chars for Red Flags / Feel Calm activities, 1000 chars for Stay Safe actions.
- `UITextView` must not allow input beyond the limit (implement `textView(_:shouldChangeTextIn:replacementText:)` delegate).
- Text that exceeds the visible area scrolls within the text view (natural `UITextView` behavior).

### Keyboard Overlap
- `IQKeyboardManagerSwift` handles scrolling the active field into view.
- Verify the scroll content inset adjusts correctly when keyboard appears on the Feel Calm editor (which has 3 text fields and could be long).

### Contact Data Edge Cases
- Phone field: allow any character combination. Do not auto-format. Users may enter international numbers, extensions, etc.
- Email field: only validate presence of `@` when non-empty. Do not enforce full RFC 5322.
- Name field: allow any Unicode characters. No length restriction beyond 200 chars.

### 988 Call Action
- If device cannot make calls (iPod touch, iPad without cellular), show an alert: "This device cannot make phone calls. You can reach the 988 Suicide & Crisis Lifeline by calling or texting 988 from a phone."
- Check `UIApplication.shared.canOpenURL(URL(string: "tel://988")!)` before attempting.

### Theme Changes Mid-Edit
- Since all colors are computed properties fetched from `ThemeManager`, theme changes (e.g., automatic time-based switch) will update on next `layoutSubviews()`. No special handling needed.

### Data Migration (Future)
- The `EmotionalBundle` struct uses `Codable`. If fields are added in future versions, use `decodeIfPresent` with defaults to ensure backward compatibility.
- If fixed item counts increase (e.g., 3 red flags instead of 2), the data model's arrays handle this naturally. Only the UI layer enforces the current fixed count.

---

## 6. File Structure

Following the existing VIPER-inspired architecture:

```
Soulverse/Features/EmotionalBundle/
  Models/
    EmotionalBundleModel.swift          // Data model structs
  Presenter/
    EmotionalBundlePresenter.swift      // Hub presenter
  ViewModels/
    EmotionalBundleViewModel.swift      // Hub view model
    EmotionalBundleSectionViewModel.swift  // Per-section view model
  Views/
    EmotionalBundleViewController.swift     // Hub screen
    RedFlagsEditorViewController.swift
    SupportMeEditorViewController.swift
    FeelCalmEditorViewController.swift
    StaySafeEditorViewController.swift
    ProfessionalSupportEditorViewController.swift
    Components/
      BundleEditorNavigationView.swift
      BundleTextEntryView.swift
      BundleContactFormView.swift
      BundleProfessionalFormView.swift
      BundleSectionCardView.swift
      BundleSectionHeaderView.swift
      CrisisResourceCardView.swift
  Storage/
    EmotionalBundleStorage.swift        // Local persistence layer
```

---

## 7. Localization Keys

All user-facing strings must use `NSLocalizedString()`. Prefix: `emotion_bundle_`.

```
// Hub
"emotion_bundle_title" = "Emotional Bundle";
"emotion_bundle_subtitle" = "Prepare helpful tools for difficult emotional moments";
"emotion_bundle_footer" = "This is your support plan for hard moments. You're filling this out now so we don't have to figure everything out when you feel overwhelmed.";

// Red Flags
"emotion_bundle_red_flags_title" = "Red Flags";
"emotion_bundle_red_flags_question" = "What tells me I'm having a hard time?";
"emotion_bundle_red_flag_1" = "Red Flag 1";
"emotion_bundle_red_flag_2" = "Red Flag 2";
"emotion_bundle_red_flag_placeholder" = "e.g., Being yelled at";

// Support Me
"emotion_bundle_support_me_title" = "Support Me";
"emotion_bundle_support_me_question" = "Who helps me feel safer or less alone?";
"emotion_bundle_contact_1" = "Contact 1";
"emotion_bundle_contact_2" = "Contact 2 (Optional)";
"emotion_bundle_contact_name" = "Name";
"emotion_bundle_contact_phone" = "Phone number";
"emotion_bundle_contact_email" = "Email";
"emotion_bundle_contact_relationship" = "Relationship";

// Feel Calm
"emotion_bundle_feel_calm_title" = "Feel Calm";
"emotion_bundle_feel_calm_question" = "Things I can do to make me feel better";
"emotion_bundle_activity_1" = "Activity 1";
"emotion_bundle_activity_2" = "Activity 2 (Optional)";
"emotion_bundle_activity_3" = "Activity 3 (Optional)";
"emotion_bundle_activity_1_placeholder" = "e.g., Drawing helps me release stress";
"emotion_bundle_activity_2_placeholder" = "e.g., Drinking cold water";
"emotion_bundle_activity_3_placeholder" = "e.g., Go outside for 5 minutes";

// Stay Safe
"emotion_bundle_stay_safe_title" = "Stay Safe";
"emotion_bundle_stay_safe_question" = "How can I make this moment feel safer?";
"emotion_bundle_actions_label" = "Actions";
"emotion_bundle_actions_placeholder" = "e.g., Remove risky objects, Step outside";

// Professional Support
"emotion_bundle_professional_title" = "Professional Support";
"emotion_bundle_crisis_988_title" = "988 Suicide & Crisis Lifeline";
"emotion_bundle_crisis_988_availability" = "24/7";
"emotion_bundle_crisis_988_action" = "Call or text 988";
"emotion_bundle_crisis_988_description" = "Free and confidential support for people in distress";
"emotion_bundle_crisis_call_confirmation" = "Call 988 Suicide & Crisis Lifeline?";
"emotion_bundle_crisis_no_phone" = "This device cannot make phone calls. You can reach the 988 Suicide & Crisis Lifeline by calling or texting 988 from a phone.";
"emotion_bundle_professional_contact_1" = "Professional Contact 1";
"emotion_bundle_place_clinic" = "Place / Clinic";
"emotion_bundle_professional_name" = "Professional Name";
"emotion_bundle_professional_name_placeholder" = "e.g., Dr. Louis Reves";
"emotion_bundle_emergency_number" = "Emergency Contact Number";
"emotion_bundle_emergency_number_placeholder" = "e.g., (222) 140-310";

// Common
"emotion_bundle_discard_title" = "Discard changes?";
"emotion_bundle_discard_message" = "Your changes will not be saved.";
"emotion_bundle_discard_action" = "Discard";
"emotion_bundle_section_complete" = "Section complete";
"emotion_bundle_section_not_started" = "Not started";
"emotion_bundle_invalid_email" = "Invalid email";
"emotion_bundle_required_field" = "This field is required";
```

---

## 8. Analytics Events

Follow existing `SummitTracker`/`CoreTracker` pattern:

| Event | Parameters | Trigger |
|---|---|---|
| `emotion_bundle_opened` | `source: "tools_grid"` | User opens Bundle Hub |
| `emotion_bundle_section_opened` | `section: String` | User taps a section card |
| `emotion_bundle_section_saved` | `section: String, fields_filled: Int` | User saves a section |
| `emotion_bundle_section_cancelled` | `section: String, had_changes: Bool` | User cancels editing |
| `emotion_bundle_crisis_988_tapped` | -- | User taps the 988 resource card |
| `emotion_bundle_completion_status` | `completed_sections: Int, total_sections: Int` | On Hub `viewWillAppear` |
