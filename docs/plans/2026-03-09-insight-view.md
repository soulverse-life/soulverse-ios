# InsightView Full Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build the complete InsightView with 6 sections: Time Range Toggle, Mood Score (existing), Topic Distribution, Habit Activity (mock), Mood Check-in Activity, and Reflection & Creation stats.

**Architecture:** Extend the existing InsightViewController (scroll + stack view pattern) by adding new card views as arranged subviews. Each card is an independent UIView with its own ViewModel. The InsightViewPresenter orchestrates data fetching from MoodCheckInService and DrawingService, assembles ViewModels, and pushes updates to the VC via delegate. A `TimeRange` enum drives the toggle, and all sections respond to range changes.

**Tech Stack:** UIKit, SnapKit, DGCharts (existing), Firebase/Firestore (via existing services), CocoaPods

---

## Architecture Overview

```
InsightViewController (scrollView + contentStackView)
  ├── TimeRangeToggleView          ← NEW (Task 1)
  ├── WeeklyMoodScoreView          ← EXISTING (wire to real data in Task 3)
  ├── TopicDistributionView        ← NEW (Task 4)
  ├── HabitActivityView            ← NEW (Task 5, mock data)
  ├── MoodCheckinActivityView      ← NEW (Task 6)
  └── ReflectionCreationView       ← NEW (Task 7)

InsightViewPresenter
  ├── Uses: MoodCheckInServiceProtocol (injected)
  ├── Uses: DrawingServiceProtocol (injected)
  ├── Uses: UserProtocol (injected)
  └── Manages: TimeRange state → re-fetches on toggle

InsightViewModel
  ├── isLoading: Bool
  ├── timeRange: TimeRange
  ├── weeklyMoodScore: WeeklyMoodScoreViewModel?
  ├── topicDistribution: TopicDistributionViewModel?
  ├── habitActivity: HabitActivityViewModel?
  ├── moodCheckinActivity: MoodCheckinActivityViewModel?
  └── reflectionCreation: ReflectionCreationViewModel?
```

**Data flow:** User taps toggle → VC tells Presenter → Presenter re-fetches from services with new date range → builds ViewModels → pushes InsightViewModel to VC → VC configures each card view.

---

### Task 1: TimeRange Model + TimeRangeToggleView

**Files:**
- Create: `Soulverse/Features/Insight/ViewModels/TimeRange.swift`
- Create: `Soulverse/Features/Insight/Views/TimeRangeToggleView.swift`

**Step 1: Create TimeRange enum**

```swift
// TimeRange.swift
import Foundation

enum TimeRange {
    case last7Days
    case all

    var displayTitle: String {
        switch self {
        case .last7Days:
            return NSLocalizedString("insight_last_7_days", comment: "")
        case .all:
            return NSLocalizedString("insight_all_time", comment: "")
        }
    }

    /// Returns the start date for Firestore queries (nil = no lower bound = "all")
    var startDate: Date? {
        switch self {
        case .last7Days:
            return Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .all:
            return nil
        }
    }
}
```

**Step 2: Create TimeRangeToggleView**

A segmented-control-style view with two buttons. Delegate notifies the VC on change.

```swift
// TimeRangeToggleView.swift
import UIKit
import SnapKit

protocol TimeRangeToggleViewDelegate: AnyObject {
    func timeRangeToggleView(_ view: TimeRangeToggleView, didSelect range: TimeRange)
}

class TimeRangeToggleView: UIView {
    // Two pill-shaped buttons, selected state uses .themePrimary background
    // Unselected uses .themeCardBackground
    // Labels use .themeButtonPrimaryText / .themeTextSecondary
    weak var delegate: TimeRangeToggleViewDelegate?
    private(set) var selectedRange: TimeRange = .last7Days
    // ... (full implementation by sub-agent)
}
```

**Step 3: Add localization strings**

Add to both `en.lproj/Localizable.strings` and `zh-TW.lproj/Localizable.strings`:
- `"insight_all_time"` = "All" / "全部"

**Step 4: Wire into InsightViewController**

Add `timeRangeToggleView` as the first arranged subview in `contentStackView` (above weeklyMoodScoreView). Set VC as delegate. On toggle, call `presenter.setTimeRange(_:)`.

**Step 5: Build and verify**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(insight): add TimeRange model and TimeRangeToggleView"
```

---

### Task 2: Expand InsightViewModel + Presenter with Real Data Fetching

**Files:**
- Modify: `Soulverse/Features/Insight/ViewModels/InsightViewModel.swift`
- Modify: `Soulverse/Features/Insight/Presenter/InsightViewPresenter.swift`

**Step 1: Expand InsightViewModel**

Add fields for all sections:

```swift
struct InsightViewModel {
    var isLoading: Bool
    var timeRange: TimeRange = .last7Days
    var weeklyMoodScore: WeeklyMoodScoreViewModel?
    var topicDistribution: TopicDistributionViewModel?
    var habitActivity: HabitActivityViewModel?
    var moodCheckinActivity: MoodCheckinActivityViewModel?
    var reflectionCreation: ReflectionCreationViewModel?
}
```

**Step 2: Refactor InsightViewPresenter to use real services**

Follow the pattern from `DrawingGalleryPresenter`:
- Inject `UserProtocol`, `MoodCheckInServiceProtocol`, `DrawingServiceProtocol` via init
- Add `setTimeRange(_:)` method that re-fetches data
- `fetchData()` uses `moodCheckInService.fetchCheckIns(uid:from:to:)` and `drawingService.fetchDrawings(uid:from:to:)` in parallel (DispatchGroup)
- Transform raw models into section ViewModels

```swift
class InsightViewPresenter: InsightViewPresenterType {
    weak var delegate: InsightViewPresenterDelegate?
    private let user: UserProtocol
    private let moodCheckInService: MoodCheckInServiceProtocol
    private let drawingService: DrawingServiceProtocol
    private var currentTimeRange: TimeRange = .last7Days
    // ...

    init(user: UserProtocol = User.shared,
         moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared) { ... }

    func setTimeRange(_ range: TimeRange) {
        currentTimeRange = range
        fetchData()
    }

    func fetchData(isUpdate: Bool = false) {
        // Use DispatchGroup to fetch check-ins + drawings in parallel
        // On completion, build all ViewModels and update loadedModel
    }
}
```

**Step 3: Update InsightViewController delegate**

Handle the new ViewModel fields (configure each card view if non-nil).

**Step 4: Build and verify**

**Step 5: Commit**

```bash
git add -A && git commit -m "feat(insight): expand ViewModel and Presenter with real Firestore data fetching"
```

---

### Task 3: Wire WeeklyMoodScoreView to Real Data

**Files:**
- Modify: `Soulverse/Features/Insight/Presenter/InsightViewPresenter.swift` (add score computation)
- Modify: `Soulverse/Features/Insight/ViewModels/WeeklyMoodScoreViewModel.swift` (add factory from MoodCheckInModel)

**Step 1a: Add `sentimentScore` to RecordedEmotion**

Modify: `Soulverse/MoodCheckIn/Models/RecordedEmotion.swift`

Add a computed `score: Double` property (-1.0 to 1.0) based on emotion valence:
- Positive base emotions (joy, trust, anticipation) → positive scores, scaled by intensity (e.g., serenity=0.3, joy=0.6, ecstasy=1.0)
- Negative base emotions (sadness, anger, fear, disgust) → negative scores, scaled by intensity (e.g., pensiveness=-0.3, sadness=-0.6, grief=-1.0)
- Surprise → near neutral (~0.1), scaled by intensity
- Combined emotions → average of their two constituent base emotions' scores

**Step 1b: Add factory method on WeeklyMoodScoreViewModel**

```swift
extension WeeklyMoodScoreViewModel {
    static func from(checkIns: [MoodCheckInModel]) -> WeeklyMoodScoreViewModel {
        // Parse each check-in's emotion string via RecordedEmotion.from(uniqueKey:)
        // Use emotion.score for the daily score
        // Group check-ins by day (last 7 days)
        // Compute daily average score
        // Determine trend direction (compare last 3 days vs first 4 days)
        // Return populated ViewModel
    }
}
```

**Step 2: Replace mock data in Presenter**

Replace `WeeklyMoodScoreViewModel.mockData()` with `WeeklyMoodScoreViewModel.from(checkIns:)`.

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git add -A && git commit -m "feat(insight): wire WeeklyMoodScoreView to real Firestore data"
```

---

### Task 4: TopicDistributionView

**Files:**
- Create: `Soulverse/Features/Insight/ViewModels/TopicDistributionViewModel.swift`
- Create: `Soulverse/Features/Insight/Views/TopicDistributionView.swift`

**Step 1: Create ViewModel**

```swift
struct TopicDistributionViewModel {
    let title: String  // "Dimensions"
    let items: [TopicDistributionItem]

    struct TopicDistributionItem {
        let topic: Topic
        let count: Int
        let percentage: Double  // 0.0 to 1.0 (relative to max)
    }
}

extension TopicDistributionViewModel {
    /// Fixed order: Topic.allCases, each topic's count from check-ins
    static func from(checkIns: [MoodCheckInModel]) -> TopicDistributionViewModel { ... }
}
```

**Step 2: Create TopicDistributionView**

Card view (same glass effect pattern as WeeklyMoodScoreView) showing:
- Title "Dimensions" at top
- For each `Topic.allCases` (fixed order): a horizontal row with:
  - Topic icon (SF Symbol, tinted with `topic.mainColor`)
  - Topic localized name
  - Horizontal bar (filled width = percentage, bar color = `topic.mainColor`)
  - Count label on the right

Use `UIStackView` for the list of rows. Each row uses SnapKit for the bar width constraint (percentage of available width).

**Step 3: Add localization strings**

- `"insight_dimensions_title"` = "Dimensions" / "面向分佈"

**Step 4: Wire into InsightViewController** (add as arranged subview after weeklyMoodScoreView)

**Step 5: Wire into Presenter** (build TopicDistributionViewModel from fetched check-ins)

**Step 6: Build and verify**

**Step 7: Commit**

```bash
git add -A && git commit -m "feat(insight): add TopicDistributionView with horizontal bar chart"
```

---

### Task 5: HabitActivityView (Mock Data)

**Files:**
- Create: `Soulverse/Features/Insight/ViewModels/HabitActivityViewModel.swift`
- Create: `Soulverse/Features/Insight/Views/HabitActivityView.swift`

**Step 1: Create ViewModel**

```swift
struct HabitActivityViewModel {
    let title: String  // "Habit Activity"
    let habits: [HabitItem]

    struct HabitItem {
        let name: String
        let iconName: String     // SF Symbol name
        let currentStreak: Int
        let totalCount: Int
        let isBuiltIn: Bool
    }

    static func mockData() -> HabitActivityViewModel {
        return HabitActivityViewModel(
            title: NSLocalizedString("insight_habit_activity_title", comment: ""),
            habits: [
                HabitItem(name: NSLocalizedString("insight_habit_exercise", comment: ""),
                          iconName: "figure.run", currentStreak: 3, totalCount: 12, isBuiltIn: true),
                HabitItem(name: NSLocalizedString("insight_habit_water", comment: ""),
                          iconName: "drop.fill", currentStreak: 5, totalCount: 20, isBuiltIn: true),
                HabitItem(name: NSLocalizedString("insight_habit_meditation", comment: ""),
                          iconName: "brain.head.profile", currentStreak: 2, totalCount: 8, isBuiltIn: true),
                HabitItem(name: NSLocalizedString("insight_habit_custom", comment: ""),
                          iconName: "star.fill", currentStreak: 1, totalCount: 4, isBuiltIn: false),
            ]
        )
    }
}
```

**Step 2: Create HabitActivityView**

Card view showing:
- Title row
- For each habit: icon + name + streak badge + total count
- Use same glass effect card pattern

**Step 3: Add localization strings**

- `"insight_habit_activity_title"` = "Habit Activity" / "習慣活動"
- `"insight_habit_exercise"` = "Exercise" / "運動"
- `"insight_habit_water"` = "Water" / "喝水"
- `"insight_habit_meditation"` = "Meditation" / "冥想"
- `"insight_habit_custom"` = "Reading" / "閱讀"
- `"insight_habit_streak"` = "%d day streak" / "連續 %d 天"
- `"insight_habit_total"` = "%d total" / "共 %d 次"

**Step 4: Wire into InsightViewController and Presenter (using mock data)**

**Step 5: Build and verify**

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(insight): add HabitActivityView with mock data"
```

---

### Task 6: MoodCheckinActivityView

**Files:**
- Create: `Soulverse/Features/Insight/ViewModels/MoodCheckinActivityViewModel.swift`
- Create: `Soulverse/Features/Insight/Views/MoodCheckinActivityView.swift`

**Step 1: Create ViewModel**

```swift
struct MoodCheckinActivityViewModel {
    let title: String               // "Mood Check-in Activity"
    let totalCheckins: Int
    let currentStreak: Int          // consecutive days with at least 1 check-in
    let averagePerWeek: Double

    static func from(checkIns: [MoodCheckInModel]) -> MoodCheckinActivityViewModel {
        // Count total
        // Compute streak: iterate from today backwards, count consecutive days with check-ins
        // Average per week: totalCheckins / (dateRange in weeks)
    }
}
```

**Step 2: Create MoodCheckinActivityView**

Card view (glass effect) with:
- Title
- Three stat items in a horizontal layout:
  - Total check-ins (large number + label)
  - Current streak (large number + "days" label)
  - Avg per week (large number + label)

**Step 3: Add localization strings**

- `"insight_mood_checkin_activity_title"` = "Mood Check-in Activity" / "情緒打卡紀錄"
- `"insight_total_checkins"` = "Total" / "總計"
- `"insight_current_streak"` = "Streak" / "連續天數"
- `"insight_avg_per_week"` = "Avg/Week" / "週平均"

**Step 4: Wire into InsightViewController and Presenter**

**Step 5: Build and verify**

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(insight): add MoodCheckinActivityView with real data"
```

---

### Task 7: ReflectionCreationView

**Files:**
- Create: `Soulverse/Features/Insight/ViewModels/ReflectionCreationViewModel.swift`
- Create: `Soulverse/Features/Insight/Views/ReflectionCreationView.swift`

**Step 1: Create ViewModel**

```swift
struct ReflectionCreationViewModel {
    let journalCount: Int
    let drawingCount: Int

    static func from(checkIns: [MoodCheckInModel], drawings: [DrawingModel]) -> ReflectionCreationViewModel {
        // Journal count = check-ins where journal is non-nil and non-empty
        // Drawing count = drawings.count
    }
}
```

**Step 2: Create ReflectionCreationView**

Two side-by-side mini cards in a horizontal UIStackView:
- **Journal card**: book icon + count + "Journals" label
- **Drawing card**: paintbrush icon + count + "Drawings" label

Each mini card uses the glass effect pattern, occupies half width.

**Step 3: Add localization strings**

- `"insight_reflection_creation_title"` = "Reflection & Creation" / "反思與創作"
- `"insight_journals"` = "Journals" / "日記"
- `"insight_drawings"` = "Drawings" / "繪畫"

**Step 4: Wire into InsightViewController and Presenter**

**Step 5: Build and verify**

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(insight): add ReflectionCreationView with journal and drawing counts"
```

---

### Task 8: Final Integration & Polish

**Files:**
- Modify: `Soulverse/Features/Insight/Views/InsightViewController.swift`
- Modify: `Soulverse/Features/Insight/Presenter/InsightViewPresenter.swift`

**Step 1: Ensure correct ordering in contentStackView**

```
1. timeRangeToggleView
2. weeklyMoodScoreView
3. topicDistributionView
4. habitActivityView
5. moodCheckinActivityView
6. reflectionCreationView  (horizontal pair)
```

**Step 2: Handle empty states**

- If no check-ins exist, show empty state text in each card
- If user is not logged in, show a prompt to log in

**Step 3: Handle loading state**

- Show loading indicator while data fetches
- Hide individual cards that have no data

**Step 4: Add bottom padding to content stack** (safe area + extra spacing for comfortable scrolling)

**Step 5: Full build and test on simulator**

**Step 6: Commit**

```bash
git add -A && git commit -m "feat(insight): final integration, empty states, and polish"
```

---

## Soulverse Checklist
- [ ] Theme-aware colors only (`.themeTextPrimary`, `.themeCardBackground`, etc.)
- [ ] `NSLocalizedString` for all user-facing text
- [ ] `[weak self]` in all escaping closures
- [ ] ViewModels have no UIKit imports
- [ ] SnapKit for all Auto Layout
- [ ] `private enum Layout` for view-specific constants
- [ ] Services injected via protocol for testability

## HIG Checklist
- [ ] Touch targets >= 44pt (toggle buttons)
- [ ] Dynamic Type support via `projectFont`
- [ ] Dark mode tested (Universe theme)
- [ ] VoiceOver labels on interactive elements
