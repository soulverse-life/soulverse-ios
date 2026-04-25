# Emotional Bundle — Feature Design Spec

**Date:** 2026-04-15
**Status:** Approved
**Branch:** `feat/tool-emotional-bundle`

---

## 1. Overview

The Emotional Bundle is a **living safety plan** within the Soulverse iOS app. It provides a place for users to pre-fill helpful information they can reference when encountering emotional distress. One bundle per user, stored in Firestore, continuously editable.

### Entry Point
Self Care tab (renamed from Tools) → "Emotional Bundle" card → Bundle hub → 5 sections

### 5 Sections
| Section | Question | UI Items | Required |
|---------|----------|----------|----------|
| Red Flags | "What tells me I'm having a hard time?" | 2 text fields | First required |
| Support Me | "Who helps me feel safer or less alone?" | 2 contacts (name, phone, email, relationship) | All fields optional; empty string = not filled |
| Feel Calm | "Things I can do to make me feel better" | 3 activity fields | First required |
| Stay Safe | "How can I make this moment feel safer?" | 1 actions text field | Optional |
| Professional Support | 988 crisis line (hardcoded) + 1 professional contact (place, name, number) | 1 contact form | Optional |

---

## 2. Navigation Flow

All navigation is **push-based** via `UINavigationController`.

```
Self Care Tab (ToolsViewController)
  └─ tap "Emotional Bundle" card
     └─ AppCoordinator.openEmotionalBundle(from:)
        └─ EmotionalBundleCoordinator.start()
           └─ push EmotionalBundleMainViewController
              ├─ tap section card → push SectionViewController
              │   ├─ ✕ Cancel → pop (discard changes)
              │   └─ ✓ Save → Firestore updateData → pop → refresh indicators
              └─ ← Back → pop to ToolsViewController
```

### Rules
- Tab bar hidden on section editors, visible on main hub
- Swipe-back enabled on main hub, disabled on section editors (use ✕)
- Cancel discards changes without confirmation (short-form data)
- Save validates required fields before writing to Firestore

---

## 3. Screen Specifications

### 3.1 Bundle Main Hub
- **Title:** "Emotional Bundle"
- **Subtitle:** "Prepare helpful tools for difficult emotional moments"
- **Body:** 5 section cards in vertical stack, each showing:
  - Section icon
  - Section title
  - Completion indicator (checkmark when section has content)
- **Footer:** Deferred — will reuse an existing shared view component (not implemented in this phase)
- **Nav bar:** ← Back button (left)
- **States:** Loading (full-page loading indicator overlay, same pattern as InnerCosmo), loaded (cards with indicators), error (retry)

### 3.2 Red Flags Editor
- **Title:** "What tells me I'm having a hard time?"
- **Icon:** Warning triangle
- **Fields:** Red flag 1 (required), Red flag 2 (optional)
- **Placeholders:** "e.g., Being yelled at"
- **Nav bar:** ✕ (left) | "Red Flags" | ✓ (right)

### 3.3 Support Me Editor
- **Title:** "Who helps me feel safer or less alone?"
- **Fields per contact:** Name (optional), Phone number (optional), Email (optional), Relationship (optional)
- **Contacts:** Contact 1, Contact 2 — all fields optional; empty string = not filled
- **Keyboard types:** Default (name), Phone (phone), Email (email), Default (relationship)
- **Nav bar:** ✕ (left) | "Support me" | ✓ (right)

### 3.4 Feel Calm Editor
- **Title:** "Things I can do to make me feel better"
- **Fields:** Activity 1 (required), Activity 2 (optional), Activity 3 (optional)
- **Placeholders:** "e.g. Drinking cold water", "e.g. Go outside for 5 minutes"
- **Nav bar:** ✕ (left) | "Feel Calm" | ✓ (right)

### 3.5 Stay Safe Editor
- **Title:** "How can I make this moment feel safer?"
- **Fields:** 1 actions text field (optional)
- **Placeholder:** "e.g., Remove risky objects, Step outside"
- **Nav bar:** ✕ (left) | "Stay Safe" | ✓ (right)

### 3.6 Professional Support Editor
- **Title:** "Professional Support"
- **Crisis resource card:** Loaded from a locale-aware JSON mapping file (`CrisisResources.json`)
  - JSON maps country codes to crisis line info (name, number, description, availability)
  - Currently only US entry (`"US"`: 988 Suicide & Crisis Lifeline, 24/7)
  - At runtime, determine user's country via `Locale.current.region` and display matching resource
  - Fallback: if no matching country entry, hide the crisis card (don't show US info to non-US users)
  - Tappable to initiate phone call via `tel:{number}`
  - Shows system confirmation alert before dialing
  - On devices without telephony (iPad): opens link if available, otherwise no-op with graceful fallback
  - Future: add more country entries to the JSON without code changes
- **Fields:** Place/Clinic (optional), Professional Name (optional), Emergency Contact Number (optional)
- **Nav bar:** ✕ (left) | "Professional support" | ✓ (right)

---

## 4. Firestore Schema

### Document Path
```
users/{uid}/emotional_bundle/default
```

### Document Structure
```json
{
  "version": 1,
  "redFlags": [
    { "id": "rf_A1B2", "text": "...", "sortOrder": 0 }
  ],
  "supportMe": [
    { "id": "sm_C3D4", "name": "...", "phone": "...", "email": "...", "relationship": "...", "sortOrder": 0 }
  ],
  "feelCalm": [
    { "id": "fc_E5F6", "text": "...", "sortOrder": 0 }
  ],
  "staySafe": [
    { "id": "ss_G7H8", "text": "...", "sortOrder": 0 }
  ],
  "professionalSupport": [
    { "id": "ps_I9J0", "placeName": "...", "contactName": "...", "phone": "...", "sortOrder": 0 }
  ],
  "createdAt": "ServerTimestamp",
  "updatedAt": "ServerTimestamp"
}
```

### Design Rationale
| Decision | Choice | Why |
|----------|--------|-----|
| Single doc vs subcollection | Single doc | Data is ~1.5KB; 1 read per open vs 5 |
| Fixed doc ID `default` | Yes | Direct reference, no query needed |
| Item IDs in arrays | Prefixed UUIDs (rf_, sm_, etc.) | Stable identity for diffing |
| Section updates | `updateData` with field-level merge | Only touches edited section |
| Schema versioning | `version` integer | Client-side migration for evolution |
| Array max in security rules | 50 | Generous headroom for UI expansion |

### Read/Write Costs
| Operation | Cost |
|-----------|------|
| Open bundle | 1 read |
| Save section | 1 write |
| First-time creation | 1 write (setData merge) |
| Offline edits | 0 reads until sync |

### Security Rules
```javascript
match /users/{uid}/emotional_bundle/default {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow create, update: if request.auth != null && request.auth.uid == uid;
  allow delete: if request.auth != null && request.auth.uid == uid;
}
```

### Migration Strategy
- **New sections:** Add optional array with default `[]` — old docs decode fine
- **New fields on items:** Add as optional (`String?`) — existing items decode with nil
- **Increasing limits:** Only change UI logic + security rules max (currently 50)

---

## 5. Architecture

### File Structure (22 new files)
```
Features/Tools/EmotionalBundle/
├─ Models/
│  ├─ EmotionalBundleModel.swift
│  └─ CrisisResourceModel.swift
├─ Presenter/
│  ├─ EmotionalBundleCoordinator.swift
│  └─ EmotionalBundleMainPresenter.swift
├─ ViewModels/
│  ├─ EmotionalBundleMainViewModel.swift
│  ├─ RedFlagsSectionViewModel.swift
│  ├─ SupportMeSectionViewModel.swift
│  ├─ FeelCalmSectionViewModel.swift
│  ├─ StaySafeSectionViewModel.swift
│  └─ ProfessionalSupportSectionViewModel.swift
└─ Views/
   ├─ EmotionalBundleMainViewController.swift
   ├─ RedFlagsSectionViewController.swift
   ├─ SupportMeSectionViewController.swift
   ├─ FeelCalmSectionViewController.swift
   ├─ StaySafeSectionViewController.swift
   ├─ ProfessionalSupportSectionViewController.swift
   └─ Components/
      ├─ BundleSectionCardView.swift
      ├─ BundleFormFieldView.swift
      └─ CrisisResourceCardView.swift

Shared/Service/
├─ Protocols/
│  └─ EmotionalBundleServiceProtocol.swift
└─ EmotionalBundleService/
   └─ FirestoreEmotionalBundleService.swift

Resources/
└─ CrisisResources.json
```

### Edited Files
- `FirestoreSchema.swift` — add `emotionalBundle` collection constant
- `AppCoordinator.swift` — add `openEmotionalBundle(from:)`
- `ToolsViewController.swift` — wire `.emotionBundle` action (class name stays as-is; only the UI tab label changes to "Self Care")
- `en.lproj/Localizable.strings` — add ~40 `emotional_bundle_*` keys
- `zh-TW.lproj/Localizable.strings` — add ~40 `emotional_bundle_*` keys

### Service Protocol
```swift
protocol EmotionalBundleServiceProtocol {
    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void)
    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void)
}
```

### Swift Data Models
```swift
struct EmotionalBundleModel: Codable {
    @DocumentID var id: String?
    var version: Int
    var redFlags: [RedFlagItem]
    var supportMe: [SupportContact]
    var feelCalm: [CalmActivity]
    var staySafe: [SafetyAction]
    var professionalSupport: [ProfessionalContact]
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?
}

struct RedFlagItem: Codable, Identifiable {
    var id: String; var text: String; var sortOrder: Int
}
struct SupportContact: Codable, Identifiable {
    var id: String; var name: String; var phone: String?
    var email: String?; var relationship: String?; var sortOrder: Int
}
struct CalmActivity: Codable, Identifiable {
    var id: String; var text: String; var sortOrder: Int
}
struct SafetyAction: Codable, Identifiable {
    var id: String; var text: String; var sortOrder: Int
}
struct ProfessionalContact: Codable, Identifiable {
    var id: String; var placeName: String?; var contactName: String?
    var phone: String?; var sortOrder: Int
}

enum EmotionalBundleSection: String, CaseIterable {
    case redFlags, supportMe, feelCalm, staySafe, professionalSupport
}

enum EmotionalBundleSectionData {
    case redFlags([RedFlagItem])
    case supportMe([SupportContact])
    case feelCalm([CalmActivity])
    case staySafe([SafetyAction])
    case professionalSupport([ProfessionalContact])
}
```

### Crisis Resources JSON
```json
{
  "US": {
    "name": "988 Suicide & Crisis Lifeline",
    "number": "988",
    "description": "Free and confidential support for people in distress",
    "availability": "24/7"
  }
}
```

```swift
struct CrisisResource: Codable {
    let name: String
    let number: String
    let description: String
    let availability: String
}
```

Loaded at runtime via `Bundle.main.url(forResource:)`, keyed by `Locale.current.region?.identifier`. Adding a new country = adding a JSON entry, no code changes.

### Coordinator Pattern
- `EmotionalBundleCoordinator` manages the full flow (same pattern as `MoodCheckInCoordinator`)
- Self-retains during async operations via `strongSelf`
- Conforms to all 6 delegate protocols (main + 5 sections)
- On save: calls `service.saveSection` → pops VC → refreshes main page indicators
- On cancel: pops VC (no data mutation)

### Data Flow
```
READ:  Firestore → Service → Presenter → ViewModel → ViewController
WRITE: ViewController → Delegate → Coordinator → Service → Firestore → pop + refresh
```

---

## 6. Reusable Components

| Component | Purpose |
|-----------|---------|
| `BundleSectionCardView` | Glass-effect card on main hub showing section title + completion indicator |
| `BundleFormFieldView` | Labeled text input wrapper for section forms (wraps SoulverseTextField) |
| `CrisisResourceCardView` | Hardcoded 988 info card with tap-to-call (Professional Support only) |
| Existing `SoulverseTextField` | Text input with validation states |
| Existing `SoulverseNavigationView` | ✕/✓ navigation bar |
| Existing `SoulverseGlassContainer` | Glass card effect |

---

## 7. Testing Plan Summary

### Test Coverage: 76 test cases across 8 categories

| Category | Count | Priority Focus |
|----------|-------|---------------|
| Navigation flows | 11 | P0-P1: forward/back/cancel/save |
| Data entry & validation | 22 | P0: required fields, pre-fill, edit |
| Completion indicators | 5 | P0: empty/partial/full states |
| Data persistence | 9 | P0: Firestore round-trip, offline |
| Edge cases & errors | 11 | P0-P1: network failure, long text, rapid saves |
| UI/UX | 13 | P1-P2: theme, keyboard, device sizes |
| Localization | 8 | P0-P1: en + zh-TW strings |
| Performance | 5 | P2: load time, memory, retain cycles |

### P0 Critical Tests
- **DP-001:** Save to Firestore round trip (fill → save → kill app → reopen → data intact)
- **DP-003:** Offline save works (Firestore cache)
- **CI-004:** Completion indicator updates after saving a section
- **RF-001:** Required field validation blocks save
- **FT-002:** First save creates Firestore document (not duplicates)
- **NAV-007:** Cancel discards changes
- **NAV-008:** Save persists and pops

### Regression Risk Areas
| Area | Risk |
|------|------|
| ToolsViewController | New navigation path could break existing tool actions |
| Navigation stack | Swipe-back/Hero transitions for other tools |
| FirestoreSchema | New collection constant must follow existing pattern |
| SoulverseTextField | Heavy reuse — modifications could break login/onboarding |
| Theme system | All new views must use theme-aware colors exclusively |
| Localization | New keys must not conflict with existing keys |

### Unit Test Structure
```
SoulverseTests/Tests/Features/EmotionalBundle/
├─ EmotionalBundleMainPresenterTests.swift
├─ RedFlagsSectionViewModelTests.swift
├─ SupportMeSectionViewModelTests.swift
├─ FeelCalmSectionViewModelTests.swift
├─ StaySafeSectionViewModelTests.swift
├─ ProfessionalSupportSectionViewModelTests.swift
└─ EmotionalBundleCoordinatorTests.swift

SoulverseTests/Mocks/Features/EmotionalBundle/
└─ EmotionalBundleServiceMock.swift
```

---

## 8. Localization Keys

All keys prefixed with `emotional_bundle_`. ~40 keys total covering:
- Section titles and descriptions
- Field labels and placeholders
- Validation error messages
- 988 crisis line information
- Navigation bar titles
- Footer encouragement text

Both `en.lproj/Localizable.strings` and `zh-TW.lproj/Localizable.strings` must be updated.

---

## 9. Accessibility

- All interactive elements must have VoiceOver accessibility labels
- Section cards on main hub: announce title + completion state (e.g., "Red Flags, completed")
- 988 card: announce as phone number with call action available
- All text fields: use `SoulverseTextField` accessibility support
- Support Dynamic Type — text scales, no truncation of critical content
- Minimum touch target: 44pt (per `ViewComponentConstants.navigationButtonSize`)
- Add accessibility identifiers for UI testing

---

## 10. Completion Indicator Logic

A section shows as "completed" on the main hub when:

| Section | Completed When |
|---------|---------------|
| Red Flags | First red flag text is non-empty (trimmed) |
| Support Me | At least one contact has a non-empty name |
| Feel Calm | First activity text is non-empty (trimmed) |
| Stay Safe | Actions text is non-empty (trimmed) |
| Professional Support | At least one field (placeName, contactName, or phone) is non-empty |

---

## 11. Text Input Limits

| Field Type | Max Characters |
|------------|---------------|
| Red Flags text | 200 |
| Feel Calm activities | 100 |
| Stay Safe actions | 100 |
| Support Me contact fields (name, phone, email, relationship) | 100 |
| Professional Support fields (place, name, number) | 100 |

- Enforced client-side via `SoulverseTextField` maxLength
- **At-limit indicator:** When user reaches the character limit, the text field border turns red and a character count message appears at the bottom-right of the text field (e.g., "200/200") using `.errorWithMessage` state
- No Firestore security rule enforcement for text length (client is only writer)

---

## 12. Delete Rule

The Firestore security rules include `allow delete` for potential future use (e.g., account deletion cascade). There is **no delete flow in the UI**. The bundle is a living document that can only be edited, never deleted by the user.

---

## 13. Open Questions (None)

All design decisions have been resolved:
- ✅ Architecture: Single Firestore doc + Coordinator pattern
- ✅ Navigation: Push-based throughout
- ✅ UI item counts: Fixed in UI, extendable in data store
- ✅ Edit flow: Always-editable forms with completion indicators on hub
- ✅ Bundle lifecycle: One living document per user
