# InnerCosmo Architecture

Technical documentation for the InnerCosmo feature — the emotional wellness dashboard in Soulverse.

## Overview

InnerCosmo displays the user's recent emotional journey as an interactive planet visualization. The **Recent** tab shows the latest 7 mood check-ins as planets: a central planet (latest) surrounded by 6 orbital planets in a horseshoe arc. The **All** tab shows a paginated calendar view of historical data.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                  InnerCosmoViewController                    │
│  ┌─────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │  HeaderView      │  │  RecentView      │  │ AllPeriod  │ │
│  │  (greeting +     │  │  (planets)       │  │ View       │ │
│  │   segment)       │  │                  │  │ (calendar) │ │
│  └─────────────────┘  └──────────────────┘  └────────────┘ │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  MoodEntriesSection (horizontal card scroll)          │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
              InnerCosmoViewPresenter
                          │
                          ▼
             MoodEntriesDataAssembler
                          │
                          ▼
                  Firestore (checkIns + drawings)
```

### VIPER-Inspired Pattern

| Layer | File | Responsibility |
|-------|------|----------------|
| **View** | `InnerCosmoViewController` | UI setup, period switching, delegates |
| **Presenter** | `InnerCosmoViewPresenter` | Data fetching, conversion, state management |
| **ViewModel** | `InnerCosmoViewModel` | Dumb data carrier between presenter and view |
| **Service** | `MoodEntriesDataAssembler` | Firestore queries, card assembly |
| **Model** | `MoodCheckInModel` | Firestore document mapping |

---

## Data Flow

### Initial Load

```
viewDidLoad()
    │
    ▼
presenter.fetchData()
    │
    ▼
assembler.fetchInitial(limit: 7)
    │
    ├──► moodCheckInService.fetchLatestCheckIns(uid, limit: 7)
    │        → [MoodCheckInModel]
    │
    └──► drawingService.fetchDrawings(uid, from: startOfDay, to: nil)
             → [DrawingModel]
    │
    ▼
assembleCards(checkIns:, drawings:)
    → [MoodEntryCard]
    │
    ├──► convertToEmotionPlanets(cards)  →  [EmotionPlanetData] (7 items)
    │
    └──► convertToMoodEntries(cards)     →  [MoodEntryCardCellViewModel]
    │
    ▼
InnerCosmoViewModel(emotions:, moodEntries:)
    │
    ▼
delegate.didUpdate(viewModel:)
    │
    ├──► headerView.configure(userName:)
    ├──► recentView.configure(emotions:)
    └──► moodEntriesSection.configure(with:)
```

### Pagination (Mood Entry Cards)

```
MoodEntriesSection scroll near end
    → moodEntriesSectionDidRequestMore()
    → presenter.loadMoreMoodEntries()
    → assembler.fetchMore()  (cursor-based, next 7 entries)
    → convertToMoodEntries(newCards)
    → delegate.didAppendMoodEntries(newEntries)
    → moodEntriesSection.appendEntries()
```

### Period Switching

```
HeaderView segment changed
    → delegate.headerView(didSelectPeriod:)
    → switchToPeriod(.recent | .all)
        .recent → show RecentView, start animations
        .all    → show AllPeriodView, stop animations
```

---

## Data Mapper: `convertToEmotionPlanets`

The core transformation that maps Firestore data to planet UI models.

**Location:** `InnerCosmoViewPresenter.swift`

```
Input:  [MoodEntryCard]  (from assembler, may include orphan cards)
Output: [EmotionPlanetData]  (always exactly 7 items)
```

### Logic

1. **Filter** — only cards with a valid `checkIn` (orphan/drawing-only cards excluded via `compactMap`)
2. **Take first 7** — `prefix(totalPlanetCount)`
3. **Map each card** to `EmotionPlanetData`:
   - `emotion` = `RecordedEmotion(rawValue: checkIn.emotion)?.displayName` (localized)
   - `colorHex` = `checkIn.colorHex` (user-selected color from Sensing step)
   - `sizeMultiplier` = default 1.0
4. **Pad to 7** with grey placeholder planets:
   - `emotion` = `""` (empty → label hidden)
   - `colorHex` = `"#B0B0B0"` (light grey)
   - `sizeMultiplier` = varied `[0.8, 1.0, 0.6, 0.9, 0.7, 1.1, 0.75]` for organic sizing

### Usage in ViewModel

```swift
emotions[0]     → central planet (latest mood check-in)
emotions[1...6] → surrounding planets (2nd–7th most recent)
```

---

## UI Components

### InnerCosmoRecentView

The main planet visualization container.

**View hierarchy:**
```
InnerCosmoRecentView
├── CentralPlanetView (200×200, centered)
├── EmotionPlanetView × 6 (surrounding, frame-positioned)
└── AffirmationBubbleView (on-demand, overlay)
```

#### Horseshoe Arc Positioning

Surrounding planets are arranged in a horseshoe arc (open at top) using trigonometric positioning. The nearest planet (2nd most recent) orbits closest to center, with radius increasing linearly for older check-ins.

```
Parameters:
  startAngle       = 1.1π  (~200°, upper-left)
  arcSpan          = -1.15π (~207° clockwise sweep)
  nearestRadius    = 115pt  (2nd planet, closest to center)
  farthestRadius   = 150pt  (7th planet, furthest from center)
  jitter           = ±3pt

For planet at index i (0-based, out of count planets):
  spacing = arcSpan / (count - 1)
  angle   = startAngle + spacing × i
  t       = i / (count - 1)                           // 0.0 → 1.0
  radius  = nearestRadius + t × (farthestRadius - nearestRadius)
  x       = center.x + radius × cos(angle) + jitter
  y       = center.y + radius × sin(angle) + jitter
```

This creates a layout where:
- Planet 1 (2nd most recent): upper-left, radius 115pt (nearest)
- Planet 6 (7th most recent): upper-right, radius 150pt (farthest)
- Planets 2–5: sweep clockwise through the bottom

### CentralPlanetView

Displays the latest mood check-in as a large gradient sphere with the E.M.O pet overlaid and an emotion label inside the planet.

**View hierarchy:**
```
CentralPlanetView (200×200)
├── outerGlowView (200×200, clipped circle)
│   └── outerGlowGradientLayer (radial, faded emotion color → transparent)
├── haloView (176×176, clipped circle)
│   └── haloGradientLayer (radial, emotion color → transparent at edge)
├── innerPlanetView (160×160, clipped circle)
│   ├── emotionGradientLayer (radial, spotlight)
│   ├── emoPetImageView (64×64, centered, -8pt Y offset)
│   └── emotionLabel (centered below pet image, inside planet)
```

**Spotlight gradient (innerPlanetView):**
```
Type: radial
Start: (0.3, 0.3) — upper-left
End:   (1.0, 1.0) — lower-right

Colors:
  [0.0]  highlight = base RGB + 0.4 each channel (clamped to 1.0)
  [0.45] base      = original emotion color
  [1.0]  dark      = base RGB × 0.6
```

**Outer glow (outerGlowView, 200pt):**
```
Type: radial, centered
Colors: base @ 30% alpha → base @ 15% alpha → transparent
```

**Edge halo (haloView, 176pt = innerDiameter + 8pt × 2):**
```
Type: radial, centered
Colors:
  [0.0]        emotion color (solid — hidden behind innerPlanetView)
  [fadeStart]  emotion color (at planet edge ratio: 160/176 ≈ 0.91)
  [1.0]        transparent
Effect: Soft colored glow bleeding outward from the planet edge
```

### EmotionPlanetView

Individual surrounding planet with optional glass-morphism label and edge halo.

**View hierarchy:**
```
EmotionPlanetView
├── haloView (planet + 12pt, clipped circle)
│   └── haloGradientLayer (radial, emotion color → transparent at edge)
├── planetView (36pt × sizeMultiplier, clipped circle)
│   └── gradientLayer (radial, spotlight — same as central)
└── labelContainerView (glass pill)
    └── labelVisualEffectView (UIGlassEffect on iOS 26+, fallback: black 30%)
        └── emotionLabel
```

**Edge halo (haloView, planetSize + 6pt × 2):**
```
Type: radial, centered
Colors:
  [0.0]        emotion color (solid — hidden behind planetView)
  [fadeStart]  emotion color (at planet edge ratio: planetSize / haloSize)
  [1.0]        transparent
Effect: Soft colored glow at planet edge, blends into dark background
```

**Placeholder behavior** (when `emotion` is empty):
- Label container hidden
- Planet circle only (no text label)
- Grey color (#B0B0B0) with spotlight gradient + grey halo
- Dynamic `sizeMultiplier` for organic varied sizing
- Still participates in layout and floating animation

**Floating animation:**
```
Type: CABasicAnimation on position.y
Range: ±5pt from resting position
Duration: 2.5s
Phase offset: random [0...1] × duration (each planet unique)
Autoreverses: true
Repeat: infinite
Timing: easeInEaseOut
Respects: UIAccessibility.isReduceMotionEnabled
```

---

## Accessibility

- **VoiceOver**: Emotion planets set `accessibilityLabel` to emotion name; placeholders set `isAccessibilityElement = false`
- **Central planet**: `accessibilityLabel` set to emotion name
- **Reduce Motion**: Floating animations check `UIAccessibility.isReduceMotionEnabled` before starting

---

## Key Files

```
Features/InnerCosmo/
├── Views/
│   ├── InnerCosmoViewController.swift      # Main VC, period switching
│   └── Components/
│       ├── InnerCosmoRecentView.swift       # Planet layout + horseshoe arc
│       ├── InnerCosmoAllPeriodView.swift    # Calendar grid (All tab)
│       ├── CentralPlanetView.swift          # Large central emotion planet
│       ├── EmotionPlanetView.swift          # Surrounding planet + label
│       ├── InnerCosmoHeaderView.swift       # Greeting + segment control
│       ├── AffirmationBubbleView.swift      # Speech bubble overlay
│       ├── MoodEntriesSection.swift         # Horizontal card scroll
│       └── MoodEntryCardCell.swift          # Individual mood card
├── Presenter/
│   ├── InnerCosmoViewPresenter.swift        # Data fetching + planet mapper
│   └── InnerCosmoViewPresenterType.swift    # Protocols
├── ViewModels/
│   ├── InnerCosmoViewModel.swift            # View state container
│   ├── InnerCosmoEmotionData.swift          # EmotionPlanetData + period enum
│   ├── MoodEntryCardCellViewModel.swift     # Card display model
│   ├── CalendarMonthViewModel.swift         # Calendar grid model
│   └── AffirmationQuote.swift               # Quote model + loader
└── Constants+InnerCosmo.swift               # Layout constants

Shared/Service/MoodCheckInService/
├── MoodEntriesDataAssembler.swift           # Card assembly + pagination
└── MoodCheckInModel.swift                   # Firestore document model
```

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| 0 check-ins | 7 grey placeholder planets, no mood entry cards |
| 1 check-in | 1 colored central + 6 grey placeholders |
| 7+ check-ins | All 7 planets colored, cards paginate for more |
| Orphan cards (drawing-only) | Excluded from planets, shown as cards with nil emotion |
| Invalid colorHex | Falls back to `.themeTextSecondary` via `UIColor(hex:)` |
| Pull-to-refresh | `fetchData(isUpdate: true)`, no loading spinner |
| Reduce Motion enabled | Floating animations skipped |
