# Onboarding Quest — Plan 5 of 7: Survey Section Composition + Radar Chart Refactor

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the server-derived survey state into the Quest tab and refactor the existing `QuestRadarChartView` into the State-of-Change-driven visualization defined by §5.2 of the design spec. After this plan, the Quest tab shows a real `SurveySection` (deck-of-cards PendingSurveyDeck + RecentResultCardList) backed by a Firestore listener, the 8-Dimensions card renders per-axis dots / lock icons / center EmoPet (no polygon fill), and the Day-7 → Importance → 8-Dim end-to-end flow updates the UI in real time without a manual refresh.

**Architecture:** All composition logic is a pure function of `QuestState` + a recent-submissions array — implemented in `SurveySectionComposer` (framework-agnostic) and unit-tested without UIKit. The deck and result list are pure UIKit subviews wired through `QuestPresenter` (from Plan 2). The radar chart keeps DGCharts for axis web/grid/labels and gains an overlay `UIImageView` layer driven by an `EightDimensionsRenderModel` enum-per-axis state machine. The `SurveySection` and 8-Dimensions overlay both react to a single Firestore listener on `users/{uid}/quest_state` (already wired by Plan 2's `FirestoreQuestService`). No new Firestore writes; reads only.

**Tech Stack:** Swift 5, UIKit, SnapKit, DGCharts (existing), `NSLocalizedString` (en for MVP), Firebase Firestore (listener already wired by Plan 2). Tests use XCTest + the existing iOS test target.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md` (§4.1, §5.1, §5.2, §6.5, §10, §11)

---

## File structure

After this plan, the iOS app will have:

```
Soulverse/Features/Quest/
  Presenter/
    QuestViewPresenter.swift                           # MODIFIED — listener wires SurveySection composition
  ViewModels/
    QuestViewModel.swift                               # MODIFIED — adds SurveySectionModel + EightDimensionsRenderModel
    SurveySectionComposer.swift                        # NEW — pure-function survey section composer
    EightDimensionsRenderModelBuilder.swift            # NEW — pure-function radar render model builder
    DimensionAxisState.swift                           # NEW — per-axis enum state machine
  Views/
    QuestRadarChartView.swift                          # MODIFIED — disable polygon fill, add overlay layer
    QuestRadarOverlayView.swift                        # NEW — UIImageView-based dots/locks/EmoPet overlay
    StateOfChangeIndicatorView.swift                   # NEW — 5-dot SoC indicator below the radar
    EightDimensionsCardView.swift                      # NEW — wraps radar + SoC indicator + lock affordance
    SurveySection/
      SurveySectionView.swift                          # NEW — container, hides when day < 7
      PendingSurveyDeckView.swift                      # NEW — deck-of-cards visual
      PendingSurveyCardView.swift                      # NEW — single deck card
      RecentResultCardListView.swift                   # NEW — vertical stack of result cards
      RecentResultCardView.swift                       # NEW — single result card
    QuestViewController.swift                          # MODIFIED — embed EightDimensionsCardView + SurveySectionView

SoulverseTests/Features/Quest/
  SurveySectionComposerTests.swift                     # NEW
  EightDimensionsRenderModelBuilderTests.swift         # NEW
  PendingSurveyDeckOrderingTests.swift                 # NEW
  StateOfChangeIndicatorViewModelTests.swift           # NEW

SoulverseUITests/
  QuestDay7ToImportanceFlowUITests.swift               # NEW (best-effort UI test)

Soulverse/en.lproj/Localizable.strings                 # MODIFIED — add SurveySection + radar copy
```

The rest of the codebase is untouched in this plan.

---

## Cross-plan dependencies

These names come from earlier plans. If they ship under different names, fix the references in this plan up-front rather than mid-task:

- **Plan 2 supplies:** `QuestPresenter`, `QuestViewModel` (extend with new fields), `FirestoreQuestService.observeQuestState(uid:onChange:)`, `FirestoreSurveyService.observeRecentSubmissions(uid:windowDays:onChange:)`, locked-card affordance helper.
- **Plan 3 supplies:** `HabitCheckerSection` (independent — embedded by `QuestViewController` already; this plan only adds peer subviews).
- **Plan 4 supplies:** `enum SurveyType` (`.importanceCheckIn`, `.eightDim`, `.stateOfChange`, `.satisfactionCheckIn`), `struct SurveyDefinition`, `class SurveyViewController`, `class SurveyResultViewController`, `enum WellnessDimension`, `struct SurveySubmission` (Swift mirror of Firestore doc), `FirestoreSurveyService`, scoring functions, all localized question banks.

If any of those types use a different name when their PR lands, do a single rename pass against the plan files before starting. Do **not** silently translate while implementing.

---

## Pre-launch operational items (NOT TDD tasks)

- [ ] **Pre-launch 1:** EmoPet center icon asset confirmed. The asset catalog already contains `EMOPet/basic_first_level.imageset`. If product wants a distinct radar-center variant, source it before Task 11; otherwise Task 11 reuses the existing asset.
- [ ] **Pre-launch 2:** Lock-icon asset for radar axes confirmed. Reuse the existing lock-icon asset that Plan 2's locked-card affordance uses; if missing, add one before Task 9.
- [ ] **Pre-launch 3:** Verify `.themeChartAxis` and `.themeAccent` tokens exist in `Soulverse/Shared/Theme/`. If absent, add both during Task 8 — do not fall back to hardcoded values.

---

## Task 1: Add SurveySection model types to `QuestViewModel`

**Files:**
- Modify: `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift`

Plan 2's `QuestViewModel` already exists. This task extends it with the model types this plan composes.

- [ ] **Step 1: Write a failing test**

Create `SoulverseTests/Features/Quest/SurveySectionComposerTests.swift` (initial scaffold only — full coverage in Task 3):

```swift
import XCTest
@testable import Soulverse

final class SurveySectionModelTests: XCTestCase {
    func testHiddenIsAValidCase() {
        // Compile-only smoke check — establishes that the symbol exists.
        let model: SurveySectionModel = .hidden
        switch model {
        case .hidden: XCTAssertTrue(true)
        case .composed: XCTFail("Unexpected composed case")
        }
    }
}
```

- [ ] **Step 2: Run the test and verify it fails to compile**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/SurveySectionModelTests -quiet
```

Expected: build error — `SurveySectionModel` not found.

- [ ] **Step 3: Add the model types**

Append to `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift`:

```swift
// MARK: - Survey Section Model

/// Single card in the PendingSurveyDeck.
struct PendingSurveyCardModel: Equatable {
    let surveyType: SurveyType        // from Plan 4
    let eligibleSince: Date
    let titleKey: String              // localization key, e.g. "quest_pending_card_importance_title"
    let bodyKey: String
}

/// Deck-of-cards container; first card is "front".
struct PendingSurveyDeckModel: Equatable {
    let cards: [PendingSurveyCardModel]   // sorted oldest-eligibleSince first

    var frontCard: PendingSurveyCardModel? { cards.first }
    var stackedBehindCount: Int { max(0, cards.count - 1) }
    var moreBadgeCount: Int { cards.count >= 3 ? cards.count - 2 : 0 }
}

/// Single completed-recently card in RecentResultCardList.
struct RecentResultCardModel: Equatable {
    let surveyType: SurveyType
    let submissionId: String
    let submittedAt: Date
    let summaryKey: String            // e.g. "quest_result_card_8dim_emotional_stage_2"
}

/// The Survey section's full composed state.
enum SurveySectionModel: Equatable {
    case hidden                                                // distinctCheckInDays < 7
    case composed(deck: PendingSurveyDeckModel, results: [RecentResultCardModel])
}

// MARK: - 8-Dimensions Render Model

/// Per-axis state machine driving the radar overlay.
enum DimensionAxisState: Equatable {
    /// distinctCheckInDays < 7. All 8 axes are in this state, EmoPet at center.
    case stage1Locked
    /// User's current focus dim, no SoC yet — 5 outline dots, no solid dot.
    case currentFocusNoSoC
    /// User's current focus dim, SoC submitted at the given stage (1–5).
    case currentFocusWithSoC(stage: Int)
    /// Previously focused (post-v1.1 only). Single dim dot at last reached stage.
    case previouslyFocused(stage: Int)
    /// Never assessed — lock icon at outermost position.
    case neverAssessed
}

/// One render entry per dimension, in canonical order.
struct EightDimensionsRenderModel: Equatable {
    /// Always 8 entries, indexed in canonical order: physical, emotional, social,
    /// intellectual, spiritual, occupational, environmental, financial.
    let axes: [DimensionAxisState]
    /// The State-of-Change indicator state — `nil` means "indicator hidden".
    let stateOfChangeIndicator: StateOfChangeIndicatorModel?
    /// Whether the whole card is locked (stage-1 affordance).
    let isCardLocked: Bool
}

/// Friendly-label SoC indicator (5 dots).
struct StateOfChangeIndicatorModel: Equatable {
    let activeStage: Int    // 1–5
    let stageLabelKeys: [String]   // length 5: ["quest_stage_soc_1_label" … "quest_stage_soc_5_label"]
    let stageMessageKey: String    // for the active stage
}
```

Add (extending the existing `QuestViewModel` struct):

```swift
extension QuestViewModel {
    /// Survey section composition — driven by SurveySectionComposer.
    var surveySection: SurveySectionModel { _surveySection ?? .hidden }
    /// 8-Dimensions card render model — driven by EightDimensionsRenderModelBuilder.
    var eightDimensions: EightDimensionsRenderModel? { _eightDimensions }
}
```

Then refactor `QuestViewModel` to store these as private properties:

```swift
struct QuestViewModel {
    var isLoading: Bool
    var radarChartData: QuestRadarData?
    var lineChartData: QuestLineData?

    fileprivate var _surveySection: SurveySectionModel?
    fileprivate var _eightDimensions: EightDimensionsRenderModel?

    init(
        isLoading: Bool = false,
        radarChartData: QuestRadarData? = nil,
        lineChartData: QuestLineData? = nil,
        surveySection: SurveySectionModel? = nil,
        eightDimensions: EightDimensionsRenderModel? = nil
    ) {
        self.isLoading = isLoading
        self.radarChartData = radarChartData
        self.lineChartData = lineChartData
        self._surveySection = surveySection
        self._eightDimensions = eightDimensions
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/SurveySectionModelTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/QuestViewModel.swift SoulverseTests/Features/Quest/SurveySectionComposerTests.swift
git commit -m "feat(quest): add SurveySectionModel and EightDimensionsRenderModel types to QuestViewModel"
```

---

## Task 2: Extract `DimensionAxisState` into its own file

**Files:**
- Create: `Soulverse/Features/Quest/ViewModels/DimensionAxisState.swift`
- Modify: `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift` (move out)

Keeps the per-axis state machine scannable; later tests target it directly.

- [ ] **Step 1: Move the type**

Create `Soulverse/Features/Quest/ViewModels/DimensionAxisState.swift`:

```swift
import Foundation

/// Per-axis render state for the 8-Dimensions radar overlay.
/// Mapped from `QuestState` by `EightDimensionsRenderModelBuilder`.
enum DimensionAxisState: Equatable {
    case stage1Locked
    case currentFocusNoSoC
    case currentFocusWithSoC(stage: Int)
    case previouslyFocused(stage: Int)
    case neverAssessed
}
```

Remove the duplicate definition from `QuestViewModel.swift`.

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/DimensionAxisState.swift Soulverse/Features/Quest/ViewModels/QuestViewModel.swift
git commit -m "refactor(quest): extract DimensionAxisState into its own file"
```

---

## Task 3: `SurveySectionComposer` (pure function)

**Files:**
- Create: `Soulverse/Features/Quest/ViewModels/SurveySectionComposer.swift`
- Modify: `SoulverseTests/Features/Quest/SurveySectionComposerTests.swift`

Implements the §6.5 pseudocode as a pure, framework-agnostic function. No UIKit, no Firestore.

- [ ] **Step 1: Write failing tests**

Replace `SoulverseTests/Features/Quest/SurveySectionComposerTests.swift` with:

```swift
import XCTest
@testable import Soulverse

final class SurveySectionComposerTests: XCTestCase {

    private func makeState(
        days: Int = 0,
        pending: [SurveyType] = [],
        eligibleSinceMap: [SurveyType: Date] = [:]
    ) -> QuestState {
        QuestState(
            distinctCheckInDays: days,
            lastDistinctDayKey: nil,
            questCompletedAt: nil,
            focusDimension: nil,
            focusDimensionAssignedAt: nil,
            pendingSurveys: pending,
            surveyEligibleSinceMap: eligibleSinceMap,
            importanceCheckInSubmittedAt: nil,
            lastEightDimSubmittedAt: nil,
            lastEightDimDimension: nil,
            lastEightDimSummary: nil,
            lastStateOfChangeSubmittedAt: nil,
            lastStateOfChangeStage: nil,
            satisfactionCheckInSubmittedAt: nil,
            lastSatisfactionTopCategory: nil,
            lastSatisfactionLowestCategory: nil,
            notificationHour: 1,
            timezoneOffsetMinutes: 480
        )
    }

    private let now = Date(timeIntervalSince1970: 1_777_000_000) // 2026-04-29

    func testHiddenWhenDaysBelow7() {
        let state = makeState(days: 6)
        let result = SurveySectionComposer.compose(state: state, recent: [], now: now)
        XCTAssertEqual(result, .hidden)
    }

    func testEmptyDeckEmptyResultsAtDay7() {
        let state = makeState(days: 7)
        let result = SurveySectionComposer.compose(state: state, recent: [], now: now)
        guard case .composed(let deck, let results) = result else {
            return XCTFail("Expected .composed")
        }
        XCTAssertTrue(deck.cards.isEmpty)
        XCTAssertTrue(results.isEmpty)
    }

    func testDeckSortsByEligibleSinceOldestFirst() {
        let older = now.addingTimeInterval(-3 * 86400)
        let newer = now.addingTimeInterval(-1 * 86400)
        let state = makeState(
            days: 21,
            pending: [.eightDim, .importanceCheckIn],
            eligibleSinceMap: [.eightDim: newer, .importanceCheckIn: older]
        )
        let result = SurveySectionComposer.compose(state: state, recent: [], now: now)
        guard case .composed(let deck, _) = result else { return XCTFail() }
        XCTAssertEqual(deck.cards.first?.surveyType, .importanceCheckIn) // oldest = front
        XCTAssertEqual(deck.cards.last?.surveyType, .eightDim)
    }

    func testRecentResultSuppressedWhenSameTypePending() {
        let eligibleSince = now.addingTimeInterval(-2 * 86400)
        let state = makeState(
            days: 21,
            pending: [.eightDim],
            eligibleSinceMap: [.eightDim: eligibleSince]
        )
        let recentSubmission = SurveySubmission(
            submissionId: "s1",
            surveyType: .eightDim,
            submittedAt: now.addingTimeInterval(-3 * 86400),
            payload: .empty
        )
        let result = SurveySectionComposer.compose(state: state, recent: [recentSubmission], now: now)
        guard case .composed(_, let results) = result else { return XCTFail() }
        XCTAssertTrue(results.isEmpty, "Same-type pending must suppress result card")
    }

    func testRecentResultDroppedWhenOlderThan7Days() {
        let state = makeState(days: 21)
        let oldSubmission = SurveySubmission(
            submissionId: "s2",
            surveyType: .importanceCheckIn,
            submittedAt: now.addingTimeInterval(-8 * 86400),
            payload: .empty
        )
        let result = SurveySectionComposer.compose(state: state, recent: [oldSubmission], now: now)
        guard case .composed(_, let results) = result else { return XCTFail() }
        XCTAssertTrue(results.isEmpty)
    }

    func testRecentResultsSortedNewestFirst() {
        let state = makeState(days: 21)
        let s1 = SurveySubmission(
            submissionId: "a",
            surveyType: .importanceCheckIn,
            submittedAt: now.addingTimeInterval(-5 * 86400),
            payload: .empty
        )
        let s2 = SurveySubmission(
            submissionId: "b",
            surveyType: .eightDim,
            submittedAt: now.addingTimeInterval(-1 * 86400),
            payload: .empty
        )
        let result = SurveySectionComposer.compose(state: state, recent: [s1, s2], now: now)
        guard case .composed(_, let results) = result else { return XCTFail() }
        XCTAssertEqual(results.first?.submissionId, "b")
        XCTAssertEqual(results.last?.submissionId, "a")
    }

    func testMoreBadgeAt3PlusPending() {
        let base = now.addingTimeInterval(-1 * 86400)
        let state = makeState(
            days: 21,
            pending: [.importanceCheckIn, .eightDim, .stateOfChange],
            eligibleSinceMap: [
                .importanceCheckIn: base.addingTimeInterval(-3 * 86400),
                .eightDim:          base.addingTimeInterval(-2 * 86400),
                .stateOfChange:     base.addingTimeInterval(-1 * 86400)
            ]
        )
        let result = SurveySectionComposer.compose(state: state, recent: [], now: now)
        guard case .composed(let deck, _) = result else { return XCTFail() }
        XCTAssertEqual(deck.cards.count, 3)
        XCTAssertEqual(deck.moreBadgeCount, 1)        // count - 2
        XCTAssertEqual(deck.stackedBehindCount, 2)
    }

    func testPendingWithoutEligibleSinceIsDropped() {
        // Defensive: Cloud Function should always populate the map, but if a
        // surveyType is in pendingSurveys without a map entry, drop it.
        let state = makeState(
            days: 21,
            pending: [.eightDim],
            eligibleSinceMap: [:]
        )
        let result = SurveySectionComposer.compose(state: state, recent: [], now: now)
        guard case .composed(let deck, _) = result else { return XCTFail() }
        XCTAssertTrue(deck.cards.isEmpty)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/SurveySectionComposerTests -quiet
```

Expected: FAIL — `SurveySectionComposer` symbol not found.

- [ ] **Step 3: Implement the composer**

Create `Soulverse/Features/Quest/ViewModels/SurveySectionComposer.swift`:

```swift
import Foundation

/// Pure function from `(QuestState, recent submissions, now)` → `SurveySectionModel`.
/// Mirrors the design spec §6.5 pseudocode. No UIKit, no Firestore.
enum SurveySectionComposer {
    /// 7-day window for all surveys per spec Phase 5 / Q-1.
    static let recentResultWindowDays: Int = 7

    static func compose(
        state: QuestState,
        recent: [SurveySubmission],
        now: Date = Date()
    ) -> SurveySectionModel {
        // Stage-1: section is hidden entirely (no placeholder card).
        guard state.distinctCheckInDays >= 7 else { return .hidden }

        // 1. Build pending deck — sort oldest eligibleSince first.
        let pendingCards: [PendingSurveyCardModel] = state.pendingSurveys
            .compactMap { surveyType -> PendingSurveyCardModel? in
                guard let since = state.surveyEligibleSinceMap[surveyType] else {
                    // Defensive: skip if Cloud Function hasn't populated map yet.
                    return nil
                }
                return PendingSurveyCardModel(
                    surveyType: surveyType,
                    eligibleSince: since,
                    titleKey: PendingCardCopy.titleKey(for: surveyType),
                    bodyKey: PendingCardCopy.bodyKey(for: surveyType)
                )
            }
            .sorted { $0.eligibleSince < $1.eligibleSince }

        let deck = PendingSurveyDeckModel(cards: pendingCards)

        // 2. Build recent results — suppress same-type-as-pending; window-limit; sort newest first.
        let pendingTypes = Set(state.pendingSurveys)
        let windowSeconds = TimeInterval(recentResultWindowDays * 86_400)
        let cutoff = now.addingTimeInterval(-windowSeconds)

        let resultCards: [RecentResultCardModel] = recent
            .filter { !pendingTypes.contains($0.surveyType) }
            .filter { $0.submittedAt >= cutoff }
            .sorted { $0.submittedAt > $1.submittedAt }
            .map { sub in
                RecentResultCardModel(
                    surveyType: sub.surveyType,
                    submissionId: sub.submissionId,
                    submittedAt: sub.submittedAt,
                    summaryKey: ResultCardCopy.summaryKey(for: sub)
                )
            }

        return .composed(deck: deck, results: resultCards)
    }
}

// MARK: - Localization-key helpers (private — keys live in en.lproj)
private enum PendingCardCopy {
    static func titleKey(for type: SurveyType) -> String {
        switch type {
        case .importanceCheckIn:    return "quest_pending_card_importance_title"
        case .eightDim:             return "quest_pending_card_8dim_title"
        case .stateOfChange:        return "quest_pending_card_soc_title"
        case .satisfactionCheckIn:  return "quest_pending_card_satisfaction_title"
        }
    }
    static func bodyKey(for type: SurveyType) -> String {
        switch type {
        case .importanceCheckIn:    return "quest_pending_card_importance_body"
        case .eightDim:             return "quest_pending_card_8dim_body"
        case .stateOfChange:        return "quest_pending_card_soc_body"
        case .satisfactionCheckIn:  return "quest_pending_card_satisfaction_body"
        }
    }
}

private enum ResultCardCopy {
    static func summaryKey(for sub: SurveySubmission) -> String {
        // Plan 4 stores per-type summary keys in the payload's `computed` block.
        // The composer just plumbs the prebuilt key through.
        sub.summaryLocalizationKey ?? "quest_result_card_generic_summary"
    }
}
```

> Plan 4's `SurveySubmission` should expose a `summaryLocalizationKey: String?` accessor that maps to the right `quest_stage_*` key for the survey's computed result. If Plan 4 named it differently, fix the call site here.

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/SurveySectionComposerTests -quiet
```

Expected: all 8 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/SurveySectionComposer.swift SoulverseTests/Features/Quest/SurveySectionComposerTests.swift
git commit -m "feat(quest): add SurveySectionComposer pure function for deck + result composition"
```

---

## Task 4: `EightDimensionsRenderModelBuilder` (pure function)

**Files:**
- Create: `Soulverse/Features/Quest/ViewModels/EightDimensionsRenderModelBuilder.swift`
- Create: `SoulverseTests/Features/Quest/EightDimensionsRenderModelBuilderTests.swift`

Maps `QuestState` → per-axis state for all 8 dimensions in canonical order.

- [ ] **Step 1: Write failing tests**

Create `SoulverseTests/Features/Quest/EightDimensionsRenderModelBuilderTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class EightDimensionsRenderModelBuilderTests: XCTestCase {

    private let canonicalOrder: [WellnessDimension] = [
        .physical, .emotional, .social, .intellectual,
        .spiritual, .occupational, .environmental, .financial
    ]

    private func makeState(
        days: Int = 0,
        focus: WellnessDimension? = nil,
        socStage: Int? = nil
    ) -> QuestState {
        QuestState(
            distinctCheckInDays: days,
            lastDistinctDayKey: nil,
            questCompletedAt: nil,
            focusDimension: focus,
            focusDimensionAssignedAt: focus.map { _ in Date() },
            pendingSurveys: [],
            surveyEligibleSinceMap: [:],
            importanceCheckInSubmittedAt: nil,
            lastEightDimSubmittedAt: nil,
            lastEightDimDimension: nil,
            lastEightDimSummary: nil,
            lastStateOfChangeSubmittedAt: socStage.map { _ in Date() },
            lastStateOfChangeStage: socStage,
            satisfactionCheckInSubmittedAt: nil,
            lastSatisfactionTopCategory: nil,
            lastSatisfactionLowestCategory: nil,
            notificationHour: 1,
            timezoneOffsetMinutes: 480
        )
    }

    func testStage1Locked_AllAxesLocked_CardLocked() {
        let model = EightDimensionsRenderModelBuilder.build(state: makeState(days: 3))
        XCTAssertTrue(model.isCardLocked)
        XCTAssertNil(model.stateOfChangeIndicator)
        XCTAssertEqual(model.axes.count, 8)
        XCTAssertTrue(model.axes.allSatisfy { $0 == .stage1Locked })
    }

    func testStage2_FocusAssignedNoSoC_FocusAxisShows5OutlineDots() {
        let model = EightDimensionsRenderModelBuilder.build(
            state: makeState(days: 10, focus: .emotional)
        )
        XCTAssertFalse(model.isCardLocked)
        XCTAssertNil(model.stateOfChangeIndicator)
        let emotionalIndex = canonicalOrder.firstIndex(of: .emotional)!
        XCTAssertEqual(model.axes[emotionalIndex], .currentFocusNoSoC)
        for (idx, dim) in canonicalOrder.enumerated() where dim != .emotional {
            XCTAssertEqual(model.axes[idx], .neverAssessed,
                           "Non-focus dim \(dim) should be .neverAssessed; got \(model.axes[idx])")
        }
    }

    func testStage3_FocusAssignedSoCSubmitted_SolidDotAtStage() {
        let model = EightDimensionsRenderModelBuilder.build(
            state: makeState(days: 21, focus: .physical, socStage: 3)
        )
        XCTAssertFalse(model.isCardLocked)
        XCTAssertNotNil(model.stateOfChangeIndicator)
        XCTAssertEqual(model.stateOfChangeIndicator?.activeStage, 3)
        let idx = canonicalOrder.firstIndex(of: .physical)!
        XCTAssertEqual(model.axes[idx], .currentFocusWithSoC(stage: 3))
    }

    func testNeverAssessed_AllAxesLocked_CardUnlockedAtDay7() {
        // Day ≥ 7 but focusDimension still null — Importance not submitted yet.
        let model = EightDimensionsRenderModelBuilder.build(
            state: makeState(days: 7, focus: nil)
        )
        XCTAssertFalse(model.isCardLocked)
        XCTAssertTrue(model.axes.allSatisfy { $0 == .neverAssessed })
    }

    func testCanonicalAxisOrderingIsStable() {
        let model = EightDimensionsRenderModelBuilder.build(state: makeState(days: 21))
        XCTAssertEqual(EightDimensionsRenderModelBuilder.canonicalDimensionOrder, canonicalOrder)
        XCTAssertEqual(model.axes.count, canonicalOrder.count)
    }

    func testSoCStageOutOfRange_ClampedTo1() {
        // Defensive: server should never write 0 or 6, but clamp to keep the renderer safe.
        let model = EightDimensionsRenderModelBuilder.build(
            state: makeState(days: 21, focus: .social, socStage: 99)
        )
        XCTAssertEqual(model.stateOfChangeIndicator?.activeStage, 5,
                       "Out-of-range stage clamps to 5")
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/EightDimensionsRenderModelBuilderTests -quiet
```

Expected: FAIL — `EightDimensionsRenderModelBuilder` not found.

- [ ] **Step 3: Implement the builder**

Create `Soulverse/Features/Quest/ViewModels/EightDimensionsRenderModelBuilder.swift`:

```swift
import Foundation

/// Pure function from `QuestState` → `EightDimensionsRenderModel`.
enum EightDimensionsRenderModelBuilder {
    /// Canonical axis order — must match the radar chart's xAxis labels and the
    /// tie-breaker fallback order in spec §6.4.
    static let canonicalDimensionOrder: [WellnessDimension] = [
        .physical, .emotional, .social, .intellectual,
        .spiritual, .occupational, .environmental, .financial
    ]

    /// SoC stage label keys — friendly names (spec §9.4).
    private static let socStageLabelKeys: [String] = (1...5).map { "quest_stage_soc_\($0)_label" }

    static func build(state: QuestState) -> EightDimensionsRenderModel {
        let isStage1 = state.distinctCheckInDays < 7
        let socStage = state.lastStateOfChangeStage.map { clampStage($0) }

        let axes: [DimensionAxisState] = canonicalDimensionOrder.map { dim in
            if isStage1 { return .stage1Locked }

            // Current focus dimension
            if let focus = state.focusDimension, focus == dim {
                if let stage = socStage {
                    return .currentFocusWithSoC(stage: stage)
                }
                return .currentFocusNoSoC
            }

            // Previously focused (post-v1.1 — unreachable in MVP, code path retained)
            // Hook reserved for v1.1 dim-switching: when state has a per-dim
            // history map, set `.previouslyFocused(stage:)` here.

            return .neverAssessed
        }

        let socIndicator: StateOfChangeIndicatorModel? = {
            guard let stage = socStage else { return nil }
            return StateOfChangeIndicatorModel(
                activeStage: stage,
                stageLabelKeys: socStageLabelKeys,
                stageMessageKey: "quest_stage_soc_\(stage)_message"
            )
        }()

        return EightDimensionsRenderModel(
            axes: axes,
            stateOfChangeIndicator: socIndicator,
            isCardLocked: isStage1
        )
    }

    private static func clampStage(_ raw: Int) -> Int {
        max(1, min(5, raw))
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/EightDimensionsRenderModelBuilderTests -quiet
```

Expected: all 6 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/EightDimensionsRenderModelBuilder.swift SoulverseTests/Features/Quest/EightDimensionsRenderModelBuilderTests.swift
git commit -m "feat(quest): add EightDimensionsRenderModelBuilder pure function for radar overlay state"
```

---

## Task 5: `PendingSurveyDeckOrderingTests` — exhaustive deck ordering

**Files:**
- Create: `SoulverseTests/Features/Quest/PendingSurveyDeckOrderingTests.swift`

A focused test file covering all rotation rules (front-card, "+N more", same-second tie-break).

- [ ] **Step 1: Write the tests**

Create `SoulverseTests/Features/Quest/PendingSurveyDeckOrderingTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class PendingSurveyDeckOrderingTests: XCTestCase {

    private let now = Date(timeIntervalSince1970: 1_777_000_000)

    private func deck(
        pending: [(SurveyType, Date)],
        recent: [SurveySubmission] = []
    ) -> PendingSurveyDeckModel {
        let map = Dictionary(uniqueKeysWithValues: pending)
        let state = QuestState(
            distinctCheckInDays: 21,
            lastDistinctDayKey: nil, questCompletedAt: nil,
            focusDimension: nil, focusDimensionAssignedAt: nil,
            pendingSurveys: pending.map { $0.0 },
            surveyEligibleSinceMap: map,
            importanceCheckInSubmittedAt: nil,
            lastEightDimSubmittedAt: nil, lastEightDimDimension: nil,
            lastEightDimSummary: nil, lastStateOfChangeSubmittedAt: nil,
            lastStateOfChangeStage: nil,
            satisfactionCheckInSubmittedAt: nil,
            lastSatisfactionTopCategory: nil, lastSatisfactionLowestCategory: nil,
            notificationHour: 1, timezoneOffsetMinutes: 480
        )
        let result = SurveySectionComposer.compose(state: state, recent: recent, now: now)
        guard case .composed(let deck, _) = result else { fatalError() }
        return deck
    }

    func testSinglePending_NoStackBehind_NoMoreBadge() {
        let d = deck(pending: [(.importanceCheckIn, now.addingTimeInterval(-86400))])
        XCTAssertEqual(d.cards.count, 1)
        XCTAssertEqual(d.stackedBehindCount, 0)
        XCTAssertEqual(d.moreBadgeCount, 0)
    }

    func testTwoPending_OneCardBehind_NoMoreBadge() {
        let d = deck(pending: [
            (.importanceCheckIn, now.addingTimeInterval(-2 * 86400)),
            (.eightDim,          now.addingTimeInterval(-1 * 86400))
        ])
        XCTAssertEqual(d.cards.count, 2)
        XCTAssertEqual(d.stackedBehindCount, 1)
        XCTAssertEqual(d.moreBadgeCount, 0)
    }

    func testFourPending_BadgeShows2More() {
        let d = deck(pending: [
            (.importanceCheckIn,   now.addingTimeInterval(-4 * 86400)),
            (.eightDim,            now.addingTimeInterval(-3 * 86400)),
            (.stateOfChange,       now.addingTimeInterval(-2 * 86400)),
            (.satisfactionCheckIn, now.addingTimeInterval(-1 * 86400))
        ])
        XCTAssertEqual(d.cards.count, 4)
        XCTAssertEqual(d.moreBadgeCount, 2)
    }

    func testRotationAfterSubmission_FrontCardShifts() {
        // Simulate Importance just submitted: pending now starts with 8dim (older).
        let d = deck(pending: [
            (.eightDim,          now.addingTimeInterval(-2 * 86400)),
            (.stateOfChange,     now.addingTimeInterval(-1 * 86400))
        ])
        XCTAssertEqual(d.frontCard?.surveyType, .eightDim)
    }
}
```

- [ ] **Step 2: Run the test**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/PendingSurveyDeckOrderingTests -quiet
```

Expected: all 4 tests pass (composer code from Task 3 already implements ordering).

- [ ] **Step 3: Commit**

```bash
git add SoulverseTests/Features/Quest/PendingSurveyDeckOrderingTests.swift
git commit -m "test(quest): add deck ordering tests for PendingSurveyDeckModel"
```

---

## Task 6: `PendingSurveyCardView` (single deck card)

**Files:**
- Create: `Soulverse/Features/Quest/Views/SurveySection/PendingSurveyCardView.swift`

Visual single card. No tap handler yet — wired in Task 7.

- [ ] **Step 1: Implement the view**

Create the file:

```swift
import UIKit
import SnapKit

final class PendingSurveyCardView: UIView {

    private enum Layout {
        static let titleFontSize: CGFloat = 18
        static let bodyFontSize: CGFloat = 14
        static let cornerRadius: CGFloat = 16
        static let horizontalInset: CGFloat = 20
        static let verticalInset: CGFloat = 20
        static let titleToBodySpacing: CGFloat = 8
        static let bodyToCTASpacing: CGFloat = 16
        static let ctaButtonHeight: CGFloat = ViewComponentConstants.actionButtonHeight
    }

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        l.numberOfLines = 0
        return l
    }()

    private let bodyLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.bodyFontSize, weight: .regular)
        l.textColor = .themeTextSecondary
        l.numberOfLines = 0
        return l
    }()

    private lazy var ctaButton: SoulverseButton = {
        let b = SoulverseButton(style: .primary)
        b.setTitle(NSLocalizedString("quest_pending_card_cta", comment: "Take Survey"), for: .normal)
        return b
    }()

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        ViewComponentConstants.applyGlassCardEffect(to: self, cornerRadius: Layout.cornerRadius)
        addSubview(titleLabel)
        addSubview(bodyLabel)
        addSubview(ctaButton)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.verticalInset)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleToBodySpacing)
            make.leading.trailing.equalTo(titleLabel)
        }
        ctaButton.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(Layout.bodyToCTASpacing)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.height.equalTo(Layout.ctaButtonHeight)
            make.bottom.equalToSuperview().inset(Layout.verticalInset)
        }

        ctaButton.addTarget(self, action: #selector(didTapCTA), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCTA))
        addGestureRecognizer(tap)
    }

    func configure(with model: PendingSurveyCardModel) {
        titleLabel.text = NSLocalizedString(model.titleKey, comment: "")
        bodyLabel.text = NSLocalizedString(model.bodyKey, comment: "")
    }

    @objc private func didTapCTA() { onTap?() }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/SurveySection/PendingSurveyCardView.swift
git commit -m "feat(quest): add PendingSurveyCardView for single deck card"
```

---

## Task 7: `PendingSurveyDeckView` (deck-of-cards visual)

**Files:**
- Create: `Soulverse/Features/Quest/Views/SurveySection/PendingSurveyDeckView.swift`

Stacks up to 3 cards with offset/dimming + "+N more" badge. Front card receives taps.

- [ ] **Step 1: Implement the view**

Create the file:

```swift
import UIKit
import SnapKit

final class PendingSurveyDeckView: UIView {

    private enum Layout {
        static let stackOffsetY: CGFloat = 6
        static let stackOffsetX: CGFloat = 4
        static let dimmedAlphaSecond: CGFloat = 0.85
        static let dimmedAlphaThird: CGFloat = 0.7
        static let badgeHeight: CGFloat = 24
        static let badgeCornerRadius: CGFloat = 12
        static let badgeFontSize: CGFloat = 12
        static let badgeHorizontalPadding: CGFloat = 10
    }

    private var cardViews: [PendingSurveyCardView] = []

    private let badgeLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.badgeFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        l.backgroundColor = .themeBackgroundSecondary
        l.textAlignment = .center
        l.layer.cornerRadius = Layout.badgeCornerRadius
        l.layer.masksToBounds = true
        l.isHidden = true
        return l
    }()

    /// Tap handler — receives the surveyType of the front card.
    var onFrontCardTap: ((SurveyType) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.height.equalTo(Layout.badgeHeight)
            make.width.greaterThanOrEqualTo(Layout.badgeHeight * 2)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: PendingSurveyDeckModel) {
        // Tear down old cards.
        cardViews.forEach { $0.removeFromSuperview() }
        cardViews.removeAll()

        guard !model.cards.isEmpty else {
            badgeLabel.isHidden = true
            return
        }

        // Build up to 3 visible card layers (front + up to 2 stacked behind).
        let visibleCount = min(model.cards.count, 3)
        for i in (0..<visibleCount).reversed() {
            let card = PendingSurveyCardView()
            card.configure(with: model.cards[i])
            card.alpha = i == 0
                ? 1.0
                : (i == 1 ? Layout.dimmedAlphaSecond : Layout.dimmedAlphaThird)
            insertSubview(card, belowSubview: badgeLabel)
            card.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(CGFloat(i) * Layout.stackOffsetX)
                make.trailing.equalToSuperview().offset(-CGFloat(i) * Layout.stackOffsetX)
                make.top.equalToSuperview().offset(CGFloat(i) * Layout.stackOffsetY)
                make.bottom.equalToSuperview().offset(-CGFloat(2 - i) * Layout.stackOffsetY)
            }
            cardViews.insert(card, at: 0)
        }

        // Wire front-card tap.
        cardViews.first?.onTap = { [weak self] in
            guard let front = model.frontCard else { return }
            self?.onFrontCardTap?(front.surveyType)
        }

        // "+N more" badge.
        if model.moreBadgeCount > 0 {
            let format = NSLocalizedString("quest_pending_deck_more_badge_format",
                                           comment: "+%d more")
            badgeLabel.text = String(format: format, model.moreBadgeCount)
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/SurveySection/PendingSurveyDeckView.swift
git commit -m "feat(quest): add PendingSurveyDeckView with offset stack and +N badge"
```

---

## Task 8: `RecentResultCardView` and `RecentResultCardListView`

**Files:**
- Create: `Soulverse/Features/Quest/Views/SurveySection/RecentResultCardView.swift`
- Create: `Soulverse/Features/Quest/Views/SurveySection/RecentResultCardListView.swift`

- [ ] **Step 1: Implement the single card**

Create `RecentResultCardView.swift`:

```swift
import UIKit
import SnapKit

final class RecentResultCardView: UIView {

    private enum Layout {
        static let titleFontSize: CGFloat = 16
        static let summaryFontSize: CGFloat = 14
        static let cornerRadius: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 14
        static let titleToSummarySpacing: CGFloat = 4
    }

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        return l
    }()

    private let summaryLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.summaryFontSize, weight: .regular)
        l.textColor = .themeTextSecondary
        l.numberOfLines = 0
        return l
    }()

    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        ViewComponentConstants.applyGlassCardEffect(to: self, cornerRadius: Layout.cornerRadius)
        addSubview(titleLabel)
        addSubview(summaryLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.verticalInset)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleToSummarySpacing)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(Layout.verticalInset)
        }
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: RecentResultCardModel) {
        titleLabel.text = NSLocalizedString(
            "quest_result_card_title_\(model.surveyType.rawValue)", comment: ""
        )
        summaryLabel.text = NSLocalizedString(model.summaryKey, comment: "")
    }

    @objc private func handleTap() { onTap?() }
}
```

- [ ] **Step 2: Implement the list**

Create `RecentResultCardListView.swift`:

```swift
import UIKit
import SnapKit

final class RecentResultCardListView: UIView {

    private enum Layout {
        static let interCardSpacing: CGFloat = 8
    }

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = Layout.interCardSpacing
        s.distribution = .fill
        return s
    }()

    /// Tap handler — receives the model so the presenter can route to SurveyResultViewController.
    var onCardTap: ((RecentResultCardModel) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with models: [RecentResultCardModel]) {
        stack.arrangedSubviews.forEach { stack.removeArrangedSubview($0); $0.removeFromSuperview() }
        models.forEach { model in
            let card = RecentResultCardView()
            card.configure(with: model)
            card.onTap = { [weak self] in self?.onCardTap?(model) }
            stack.addArrangedSubview(card)
        }
    }
}
```

- [ ] **Step 3: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 4: Commit**

```bash
git add Soulverse/Features/Quest/Views/SurveySection/RecentResultCardView.swift Soulverse/Features/Quest/Views/SurveySection/RecentResultCardListView.swift
git commit -m "feat(quest): add RecentResultCardView and RecentResultCardListView for survey results"
```

---

## Task 9: `SurveySectionView` container

**Files:**
- Create: `Soulverse/Features/Quest/Views/SurveySection/SurveySectionView.swift`

Container that owns the deck + list and toggles its own visibility based on `SurveySectionModel.hidden`.

- [ ] **Step 1: Implement the view**

Create the file:

```swift
import UIKit
import SnapKit

final class SurveySectionView: UIView {

    private enum Layout {
        static let deckToListSpacing: CGFloat = 16
        static let deckHeight: CGFloat = 200
    }

    private let deckView = PendingSurveyDeckView()
    private let listView = RecentResultCardListView()

    var onPendingTap: ((SurveyType) -> Void)?
    var onResultTap: ((RecentResultCardModel) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(deckView)
        addSubview(listView)

        deckView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.deckHeight)
        }
        listView.snp.makeConstraints { make in
            make.top.equalTo(deckView.snp.bottom).offset(Layout.deckToListSpacing)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        deckView.onFrontCardTap = { [weak self] type in self?.onPendingTap?(type) }
        listView.onCardTap = { [weak self] model in self?.onResultTap?(model) }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: SurveySectionModel) {
        switch model {
        case .hidden:
            isHidden = true
            // Clear constraints so the section doesn't reserve vertical space.
            snp.remakeConstraints { _ in }
        case .composed(let deck, let results):
            isHidden = false
            // Hide deck if empty (no pending) but still show results.
            deckView.isHidden = deck.cards.isEmpty
            deckView.configure(with: deck)
            listView.configure(with: results)
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/SurveySection/SurveySectionView.swift
git commit -m "feat(quest): add SurveySectionView container with hidden-state handling"
```

---

## Task 10: `QuestRadarOverlayView` — UIImageView-based dots/locks/EmoPet

**Files:**
- Create: `Soulverse/Features/Quest/Views/QuestRadarOverlayView.swift`

UIImageView-based overlay drawn on top of the DGCharts radar. Reads `EightDimensionsRenderModel` and lays out per-axis assets at the correct polar coordinates.

- [ ] **Step 1: Implement the overlay**

Create the file:

```swift
import UIKit
import SnapKit

/// Overlay that sits on top of `QuestRadarChartView`'s DGCharts radar area.
/// Renders state-aware dots, lock icons, and the center EmoPet — replacing
/// the polygon-fill rendering disabled in the parent chart.
final class QuestRadarOverlayView: UIView {

    private enum Layout {
        static let dotSize: CGFloat = 8
        static let solidDotSize: CGFloat = 14
        static let focusGlowRadius: CGFloat = 4
        static let lockIconSize: CGFloat = 20
        static let emoPetSize: CGFloat = 64
        /// Outermost radial position is at this fraction of half-min-side.
        static let stage5Fraction: CGFloat = 0.92
    }

    private let emoPetImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "EMOPet/basic_first_level"))
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    /// Per-axis rendered subviews (cleared on each `configure(with:)`).
    private var axisOverlays: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        addSubview(emoPetImageView)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        emoPetImageView.frame = CGRect(
            x: bounds.midX - Layout.emoPetSize / 2,
            y: bounds.midY - Layout.emoPetSize / 2,
            width: Layout.emoPetSize,
            height: Layout.emoPetSize
        )
        // Re-position axis overlays since polar geometry depends on bounds.
        repositionAxisOverlays()
    }

    private var lastModel: EightDimensionsRenderModel?

    func configure(with model: EightDimensionsRenderModel) {
        lastModel = model
        axisOverlays.forEach { $0.removeFromSuperview() }
        axisOverlays.removeAll()

        // 8 axes evenly spaced. Angle 0 = top (12 o'clock), proceeding clockwise.
        let axisCount = model.axes.count
        for (idx, state) in model.axes.enumerated() {
            let angle = angleForAxis(index: idx, total: axisCount)
            renderAxis(state: state, angle: angle)
        }
        setNeedsLayout()
    }

    // MARK: - Polar geometry

    private func angleForAxis(index: Int, total: Int) -> CGFloat {
        // 12 o'clock origin, clockwise. SwiftUI/UIKit y-down coordinates.
        let twoPi = CGFloat.pi * 2
        return -CGFloat.pi / 2 + (twoPi * CGFloat(index) / CGFloat(total))
    }

    private func radiusForStage(_ stage: Int) -> CGFloat {
        let half = min(bounds.width, bounds.height) / 2
        let outermost = half * Layout.stage5Fraction
        let clamped = max(1, min(5, stage))
        return outermost * CGFloat(clamped) / 5.0
    }

    private func point(angle: CGFloat, radius: CGFloat) -> CGPoint {
        CGPoint(x: bounds.midX + radius * cos(angle),
                y: bounds.midY + radius * sin(angle))
    }

    // MARK: - Per-axis rendering

    private func renderAxis(state: DimensionAxisState, angle: CGFloat) {
        switch state {
        case .stage1Locked, .neverAssessed:
            addLockIcon(angle: angle)

        case .currentFocusNoSoC:
            for stage in 1...5 {
                addOutlineDot(stage: stage, angle: angle, isFocus: true)
            }

        case .currentFocusWithSoC(let stage):
            for s in 1...5 {
                addOutlineDot(stage: s, angle: angle, isFocus: true)
            }
            addSolidFocusDot(stage: stage, angle: angle)

        case .previouslyFocused(let stage):
            // Post-v1.1 rendering branch — code path retained, unreachable in MVP.
            addDimDot(stage: stage, angle: angle)
        }
    }

    private func addLockIcon(angle: CGFloat) {
        let center = point(angle: angle, radius: radiusForStage(5))
        let iv = UIImageView(image: UIImage(named: "lockIconQuest"))
        iv.tintColor = .themeIconMuted
        iv.frame = CGRect(
            x: center.x - Layout.lockIconSize / 2,
            y: center.y - Layout.lockIconSize / 2,
            width: Layout.lockIconSize,
            height: Layout.lockIconSize
        )
        addSubview(iv)
        axisOverlays.append(iv)
    }

    private func addOutlineDot(stage: Int, angle: CGFloat, isFocus: Bool) {
        let center = point(angle: angle, radius: radiusForStage(stage))
        let dot = UIView(frame: CGRect(
            x: center.x - Layout.dotSize / 2,
            y: center.y - Layout.dotSize / 2,
            width: Layout.dotSize,
            height: Layout.dotSize
        ))
        dot.backgroundColor = .clear
        dot.layer.cornerRadius = Layout.dotSize / 2
        dot.layer.borderWidth = 1.0
        dot.layer.borderColor = (isFocus
                                 ? UIColor.themeAccent
                                 : UIColor.themeAccent.withAlphaComponent(0.6)).cgColor
        addSubview(dot)
        axisOverlays.append(dot)
    }

    private func addSolidFocusDot(stage: Int, angle: CGFloat) {
        let center = point(angle: angle, radius: radiusForStage(stage))
        let dot = UIView(frame: CGRect(
            x: center.x - Layout.solidDotSize / 2,
            y: center.y - Layout.solidDotSize / 2,
            width: Layout.solidDotSize,
            height: Layout.solidDotSize
        ))
        dot.backgroundColor = .themeAccent
        dot.layer.cornerRadius = Layout.solidDotSize / 2
        dot.layer.shadowColor = UIColor.themeAccent.cgColor
        dot.layer.shadowOpacity = 0.6
        dot.layer.shadowRadius = Layout.focusGlowRadius
        dot.layer.shadowOffset = .zero
        addSubview(dot)
        axisOverlays.append(dot)
    }

    private func addDimDot(stage: Int, angle: CGFloat) {
        let center = point(angle: angle, radius: radiusForStage(stage))
        let dot = UIView(frame: CGRect(
            x: center.x - Layout.dotSize / 2,
            y: center.y - Layout.dotSize / 2,
            width: Layout.dotSize,
            height: Layout.dotSize
        ))
        dot.backgroundColor = UIColor.themeAccent.withAlphaComponent(0.4)
        dot.layer.cornerRadius = Layout.dotSize / 2
        addSubview(dot)
        axisOverlays.append(dot)
    }

    private func repositionAxisOverlays() {
        guard let model = lastModel else { return }
        configure(with: model)   // Re-run with new bounds; cheap (≤ 41 small subviews).
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds. If `lockIconQuest` asset is missing, add it (or alias an existing lock icon) per Pre-launch 2.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestRadarOverlayView.swift
git commit -m "feat(quest): add QuestRadarOverlayView for state-aware dots, lock icons, and EmoPet"
```

---

## Task 11: Refactor `QuestRadarChartView` — disable polygon fill, host overlay

**Files:**
- Modify: `Soulverse/Features/Quest/Views/QuestRadarChartView.swift`

Reuses the DGCharts axis web/grid + labels. Disables polygon fill. Adds the overlay subview pinned to the radar's bounds and a new `configure(renderModel:)` entry point. Keeps the old `configure(with: QuestRadarData)` entry point as a thin shim that maps to the new render model so callers don't break in the same commit.

- [ ] **Step 1: Modify the file**

Replace the body of `updateChartData` and add new methods. The full updated file:

```swift
import UIKit
import DGCharts
import SnapKit

protocol QuestRadarChartViewDelegate: AnyObject {
    func radarChartDidUpdate(_ chartView: QuestRadarChartView)
}

class QuestRadarChartView: UIView {

    weak var delegate: QuestRadarChartViewDelegate?

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: 18, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    private lazy var radarChartView: RadarChartView = {
        let chartView = RadarChartView()
        chartView.delegate = self

        chartView.webLineWidth = 1.0
        chartView.innerWebLineWidth = 0.5
        chartView.webColor = UIColor.themeChartAxis
        chartView.innerWebColor = UIColor.themeChartAxis.withAlphaComponent(0.5)
        chartView.webAlpha = 1.0

        chartView.chartDescription.enabled = false
        chartView.legend.enabled = false
        chartView.isUserInteractionEnabled = false

        let yAxis = chartView.yAxis
        yAxis.labelCount = 6
        yAxis.axisMinimum = 0.0
        yAxis.axisMaximum = 5.0
        yAxis.drawLabelsEnabled = false           // Hide numeric stage labels — overlay carries semantics
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.gridColor = UIColor.themeChartAxis.withAlphaComponent(0.3)
        yAxis.granularity = 1.0

        let xAxis = chartView.xAxis
        xAxis.labelFont = UIFont.projectFont(ofSize: 12, weight: .medium)
        xAxis.labelTextColor = .themeTextPrimary
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false

        return chartView
    }()

    let overlayView = QuestRadarOverlayView()

    override init(frame: CGRect) {
        super.init(frame: frame); setupView()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder); setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        addSubview(titleLabel)
        addSubview(radarChartView)
        radarChartView.addSubview(overlayView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
        radarChartView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(radarChartView.snp.width)
        }
        overlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// Primary entry point (Plan 5).
    func configure(title: String, renderModel: EightDimensionsRenderModel, axisLabels: [String]) {
        titleLabel.text = title
        installInvisibleAxisData(labels: axisLabels)
        overlayView.configure(with: renderModel)
        delegate?.radarChartDidUpdate(self)
    }

    /// Invisible dataset just to drive xAxis label rendering — polygon fill DISABLED.
    private func installInvisibleAxisData(labels: [String]) {
        let entries = labels.map { _ in RadarChartDataEntry(value: 0.0) }
        let dataSet = RadarChartDataSet(entries: entries, label: "")
        dataSet.colors = [.clear]
        dataSet.fillColor = .clear
        dataSet.drawFilledEnabled = false                   // Phase-5 refactor — no polygon
        dataSet.lineWidth = 0
        dataSet.drawHighlightCircleEnabled = false
        dataSet.highlightEnabled = false
        dataSet.drawValuesEnabled = false
        radarChartView.data = RadarChartData(dataSets: [dataSet])
        radarChartView.xAxis.valueFormatter = RadarAxisValueFormatter(labels: labels)
        radarChartView.notifyDataSetChanged()
    }

    // MARK: - Legacy shim (kept for callers that still pass QuestRadarData)
    func configure(with data: QuestRadarData) {
        // Map legacy metrics to a placeholder render model: every axis "neverAssessed".
        // Real callers migrate to `configure(title:renderModel:axisLabels:)`.
        let labels = data.metrics.map { $0.label }
        let placeholderAxes = Array(repeating: DimensionAxisState.neverAssessed,
                                    count: labels.count)
        let model = EightDimensionsRenderModel(
            axes: placeholderAxes,
            stateOfChangeIndicator: nil,
            isCardLocked: false
        )
        configure(title: data.title, renderModel: model, axisLabels: labels)
    }
}

extension QuestRadarChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {}
    func chartValueNothingSelected(_ chartView: ChartViewBase) {}
}

private class RadarAxisValueFormatter: NSObject, AxisValueFormatter {
    private let labels: [String]
    init(labels: [String]) { self.labels = labels; super.init() }
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        return (index >= 0 && index < labels.count) ? labels[index] : ""
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestRadarChartView.swift
git commit -m "refactor(quest): disable polygon-fill rendering, add overlay-driven config entry"
```

---

## Task 12: `StateOfChangeIndicatorView` — 5 friendly-label dots

**Files:**
- Create: `Soulverse/Features/Quest/Views/StateOfChangeIndicatorView.swift`
- Create: `SoulverseTests/Features/Quest/StateOfChangeIndicatorViewModelTests.swift`

A horizontal row of 5 dots with friendly labels (Considering / Planning / Preparing / Doing / Sustaining) and a one-sentence message below.

- [ ] **Step 1: Write a failing test**

Create `SoulverseTests/Features/Quest/StateOfChangeIndicatorViewModelTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class StateOfChangeIndicatorViewModelTests: XCTestCase {

    func testActiveDotMatchesStage() {
        let model = StateOfChangeIndicatorModel(
            activeStage: 3,
            stageLabelKeys: (1...5).map { "quest_stage_soc_\($0)_label" },
            stageMessageKey: "quest_stage_soc_3_message"
        )
        let isActive = (1...5).map { $0 == model.activeStage }
        XCTAssertEqual(isActive, [false, false, true, false, false])
    }

    func testStageLabelKeysAreSizedFive() {
        let model = StateOfChangeIndicatorModel(
            activeStage: 1,
            stageLabelKeys: (1...5).map { "quest_stage_soc_\($0)_label" },
            stageMessageKey: "quest_stage_soc_1_message"
        )
        XCTAssertEqual(model.stageLabelKeys.count, 5)
    }
}
```

- [ ] **Step 2: Run the test**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/StateOfChangeIndicatorViewModelTests -quiet
```

Expected: PASS (model already exists from Task 1).

- [ ] **Step 3: Implement the view**

Create `Soulverse/Features/Quest/Views/StateOfChangeIndicatorView.swift`:

```swift
import UIKit
import SnapKit

final class StateOfChangeIndicatorView: UIView {

    private enum Layout {
        static let dotSize: CGFloat = 12
        static let dotSpacing: CGFloat = 24
        static let labelFontSize: CGFloat = 11
        static let messageFontSize: CGFloat = 14
        static let labelTopSpacing: CGFloat = 4
        static let messageTopSpacing: CGFloat = 12
    }

    private let dotsStack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.distribution = .equalSpacing
        s.alignment = .top
        return s
    }()

    private let messageLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.messageFontSize, weight: .regular)
        l.textColor = .themeTextSecondary
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dotsStack)
        addSubview(messageLabel)
        dotsStack.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(dotsStack.snp.bottom).offset(Layout.messageTopSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: StateOfChangeIndicatorModel?) {
        guard let model = model else {
            isHidden = true
            return
        }
        isHidden = false
        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (idx, labelKey) in model.stageLabelKeys.enumerated() {
            let stage = idx + 1
            let isActive = stage == model.activeStage
            dotsStack.addArrangedSubview(makeDotColumn(labelKey: labelKey, isActive: isActive))
        }
        messageLabel.text = NSLocalizedString(model.stageMessageKey, comment: "")
    }

    private func makeDotColumn(labelKey: String, isActive: Bool) -> UIView {
        let column = UIView()
        let dot = UIView()
        dot.backgroundColor = isActive ? .themeAccent : .themeIconMuted
        dot.layer.cornerRadius = Layout.dotSize / 2
        let label = UILabel()
        label.text = NSLocalizedString(labelKey, comment: "")
        label.font = UIFont.projectFont(ofSize: Layout.labelFontSize, weight: .medium)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 1

        column.addSubview(dot)
        column.addSubview(label)
        dot.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(Layout.dotSize)
        }
        label.snp.makeConstraints { make in
            make.top.equalTo(dot.snp.bottom).offset(Layout.labelTopSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
        return column
    }
}
```

- [ ] **Step 4: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/StateOfChangeIndicatorView.swift SoulverseTests/Features/Quest/StateOfChangeIndicatorViewModelTests.swift
git commit -m "feat(quest): add StateOfChangeIndicatorView with friendly labels"
```

---

## Task 13: `EightDimensionsCardView` — radar + indicator + lock affordance

**Files:**
- Create: `Soulverse/Features/Quest/Views/EightDimensionsCardView.swift`

Composes the radar, the SoC indicator, and the locked-card affordance overlay (per spec §5.2 stage-1 state).

- [ ] **Step 1: Implement the view**

Create the file:

```swift
import UIKit
import SnapKit

final class EightDimensionsCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let radarToIndicatorSpacing: CGFloat = 16
        static let horizontalInset: CGFloat = 0    // chart owns its own inset
        static let bottomInset: CGFloat = 16
    }

    private let radarChart = QuestRadarChartView()
    private let socIndicator = StateOfChangeIndicatorView()
    private let lockedOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = .themeOverlayDimmed
        v.isHidden = true
        return v
    }()
    private let lockedHintLabel: UILabel = {
        let l = UILabel()
        l.text = NSLocalizedString("quest_8dim_card_locked_hint",
                                   comment: "Unlocks at Day 7")
        l.textColor = .themeTextPrimary
        l.font = UIFont.projectFont(ofSize: 14, weight: .semibold)
        l.textAlignment = .center
        return l
    }()

    var onLockedTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        ViewComponentConstants.applyGlassCardEffect(to: self, cornerRadius: Layout.cornerRadius)
        addSubview(radarChart)
        addSubview(socIndicator)
        addSubview(lockedOverlay)
        lockedOverlay.addSubview(lockedHintLabel)

        radarChart.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
        }
        socIndicator.snp.makeConstraints { make in
            make.top.equalTo(radarChart.snp.bottom).offset(Layout.radarToIndicatorSpacing)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().inset(Layout.bottomInset)
        }
        lockedOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        lockedHintLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleLockedTap))
        lockedOverlay.addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with model: EightDimensionsRenderModel, axisLabels: [String]) {
        let title = NSLocalizedString("quest_8dim_card_title", comment: "Your 8 Dimensions")
        radarChart.configure(title: title, renderModel: model, axisLabels: axisLabels)
        socIndicator.configure(with: model.stateOfChangeIndicator)
        lockedOverlay.isHidden = !model.isCardLocked
    }

    @objc private func handleLockedTap() { onLockedTap?() }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/EightDimensionsCardView.swift
git commit -m "feat(quest): add EightDimensionsCardView wrapping radar + SoC indicator + lock affordance"
```

---

## Task 14: Wire the Firestore listener through `QuestPresenter`

**Files:**
- Modify: `Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift`

The listener already exists in Plan 2's `FirestoreQuestService`. This task adds a parallel recent-submissions observer and runs both composers in the listener callback.

- [ ] **Step 1: Modify the presenter**

In `QuestViewPresenter.swift`, add (or extend the existing `attach`/`viewDidLoad` method):

```swift
import Foundation
import Combine

final class QuestPresenter {
    private let questService: FirestoreQuestService
    private let surveyService: FirestoreSurveyService
    private weak var view: QuestPresenterView?

    private var questCancelable: AnyCancellable?
    private var recentCancelable: AnyCancellable?
    private var lastQuestState: QuestState?
    private var lastRecent: [SurveySubmission] = []

    init(view: QuestPresenterView,
         questService: FirestoreQuestService,
         surveyService: FirestoreSurveyService) {
        self.view = view
        self.questService = questService
        self.surveyService = surveyService
    }

    func start(uid: String) {
        questCancelable = questService
            .observeQuestState(uid: uid)
            .sink { [weak self] state in
                self?.lastQuestState = state
                self?.recompose()
            }
        recentCancelable = surveyService
            .observeRecentSubmissions(uid: uid, windowDays: SurveySectionComposer.recentResultWindowDays)
            .sink { [weak self] submissions in
                self?.lastRecent = submissions
                self?.recompose()
            }
    }

    func stop() {
        questCancelable?.cancel(); recentCancelable?.cancel()
        questCancelable = nil; recentCancelable = nil
    }

    private func recompose() {
        guard let state = lastQuestState else { return }
        let surveySection = SurveySectionComposer.compose(
            state: state, recent: lastRecent, now: Date()
        )
        let eightDim = EightDimensionsRenderModelBuilder.build(state: state)
        let viewModel = QuestViewModel(
            isLoading: false,
            radarChartData: nil,
            lineChartData: nil,
            surveySection: surveySection,
            eightDimensions: eightDim
        )
        view?.render(viewModel: viewModel)
    }
}
```

> Plan 2 may use a delegate-based callback rather than Combine. If so, replace `AnyCancellable` with the listener handle returned by `FirestoreQuestService` and call `stop` on detach.

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift
git commit -m "feat(quest): wire presenter to recompose SurveySection + 8-Dim model on listener events"
```

---

## Task 15: Embed `EightDimensionsCardView` and `SurveySectionView` in `QuestViewController`

**Files:**
- Modify: `Soulverse/Features/Quest/Views/QuestViewController.swift`

Inserts both subviews into the existing scroll content stack between `ProgressSection` (Plan 2) and `HabitCheckerSection` (Plan 3) per the spec §5 layout.

- [ ] **Step 1: Modify the view controller**

Add these properties:

```swift
private let eightDimensionsCard = EightDimensionsCardView()
private let surveySectionView = SurveySectionView()
```

Insert into the existing content stack in the spec-mandated order:

```
ProgressSection
EightDimensionsCardView
HabitCheckerSection
SurveySectionView
```

Wire the tap handlers:

```swift
eightDimensionsCard.onLockedTap = { [weak self] in
    self?.showLockedHint(for: .eightDimensionsStage1)   // existing helper from Plan 2
}

surveySectionView.onPendingTap = { [weak self] surveyType in
    self?.presenter?.openPendingSurvey(surveyType)
}
surveySectionView.onResultTap = { [weak self] resultModel in
    self?.presenter?.openResultCard(resultModel)
}
```

Override `render(viewModel:)` (or extend the existing one) to push state into the new subviews:

```swift
func render(viewModel: QuestViewModel) {
    if let model = viewModel.eightDimensions {
        let labels = EightDimensionsRenderModelBuilder.canonicalDimensionOrder
            .map { NSLocalizedString("quest_dimension_\($0.rawValue)", comment: "") }
        eightDimensionsCard.configure(with: model, axisLabels: labels)
    }
    surveySectionView.configure(with: viewModel.surveySection)
}
```

Add the presenter routing methods:

```swift
extension QuestPresenter {
    func openPendingSurvey(_ type: SurveyType) {
        let definition = SurveyDefinition.definition(for: type)   // from Plan 4
        let vc = SurveyViewController(definition: definition)     // from Plan 4
        view?.present(vc)
    }
    func openResultCard(_ model: RecentResultCardModel) {
        let vc = SurveyResultViewController(submissionId: model.submissionId)  // from Plan 4
        view?.present(vc)
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestViewController.swift Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift
git commit -m "feat(quest): embed EightDimensionsCardView and SurveySectionView in Quest tab"
```

---

## Task 16: Localized strings for Plan 5 surfaces

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

All user-facing strings authored in this plan. Add (do not replace) — alphabetize by key for diff hygiene.

- [ ] **Step 1: Append the keys**

Append to `Soulverse/en.lproj/Localizable.strings`:

```
/* === Plan 5: 8-Dimensions card === */
"quest_8dim_card_title" = "Your 8 Dimensions";
"quest_8dim_card_locked_hint" = "Unlocks at Day 7";

"quest_dimension_physical" = "Physical";
"quest_dimension_emotional" = "Emotional";
"quest_dimension_social" = "Social";
"quest_dimension_intellectual" = "Intellectual";
"quest_dimension_spiritual" = "Spiritual";
"quest_dimension_occupational" = "Occupational";
"quest_dimension_environmental" = "Environmental";
"quest_dimension_financial" = "Financial";

/* State-of-Change friendly stage labels (locked per spec §9.4) */
"quest_stage_soc_1_label" = "Considering";
"quest_stage_soc_2_label" = "Planning";
"quest_stage_soc_3_label" = "Preparing";
"quest_stage_soc_4_label" = "Doing";
"quest_stage_soc_5_label" = "Sustaining";

"quest_stage_soc_1_message" = "You're noticing what's working and what isn't — that's the start.";
"quest_stage_soc_2_message" = "You're imagining what change could look like.";
"quest_stage_soc_3_message" = "You're laying the groundwork for a small, real shift.";
"quest_stage_soc_4_message" = "You're putting it into practice, day by day.";
"quest_stage_soc_5_message" = "You're keeping the new pattern alive.";

/* === Plan 5: Pending survey deck === */
"quest_pending_card_cta" = "Take Survey";
"quest_pending_deck_more_badge_format" = "+%d more";

"quest_pending_card_importance_title" = "Importance Check-In";
"quest_pending_card_importance_body" = "Help us understand what matters to you.";
"quest_pending_card_8dim_title" = "Wellness Check-In";
"quest_pending_card_8dim_body" = "Score where you are in your focus dimension.";
"quest_pending_card_soc_title" = "Readiness Check-In";
"quest_pending_card_soc_body" = "Where are you on your change journey today?";
"quest_pending_card_satisfaction_title" = "Satisfaction Check-In";
"quest_pending_card_satisfaction_body" = "How satisfied are you across each life area?";

/* === Plan 5: Recent result cards === */
"quest_result_card_title_importance_check_in" = "Importance Check-In Result";
"quest_result_card_title_8dim" = "8-Dimensions Result";
"quest_result_card_title_state_of_change" = "Readiness Result";
"quest_result_card_title_satisfaction_check_in" = "Satisfaction Result";
"quest_result_card_generic_summary" = "Tap to view your result.";
```

> Per-result `quest_stage_*` and `quest_importance_result_*` keys are owned by Plan 4 (per spec §9.1); this plan only adds the keys it consumes for cards and the SoC indicator.

- [ ] **Step 2: Verify build still passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add Plan 5 strings for 8-Dim card, deck, and result cards (en)"
```

---

## Task 17: Theme tokens audit

**Files:**
- Modify (only if missing): `Soulverse/Shared/Theme/Theme.swift`

Confirm `.themeAccent`, `.themeIconMuted`, `.themeChartAxis`, `.themeBackgroundSecondary`, `.themeOverlayDimmed` resolve. Add any missing ones; do not fall back to hardcoded colors.

- [ ] **Step 1: Search for missing tokens**

```bash
grep -E "themeAccent|themeIconMuted|themeChartAxis|themeOverlayDimmed|themeBackgroundSecondary" Soulverse/Shared/Theme/*.swift
```

If any token is absent, add it under the existing `UIColor` extension. For example:

```swift
extension UIColor {
    static var themeChartAxis: UIColor {
        UIColor.themeTextSecondary.withAlphaComponent(0.3)
    }
    static var themeOverlayDimmed: UIColor {
        UIColor.black.withAlphaComponent(0.5)
    }
    static var themeIconMuted: UIColor {
        UIColor.themeTextSecondary.withAlphaComponent(0.6)
    }
    static var themeAccent: UIColor {
        UIColor(named: "AccentColor") ?? .systemBlue
    }
}
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Shared/Theme/Theme.swift
git commit -m "feat(theme): add missing theme tokens for radar overlay and survey section"
```

---

## Task 18: Day-7 → Importance → 8-Dim end-to-end UI test (best-effort)

**Files:**
- Create: `SoulverseUITests/QuestDay7ToImportanceFlowUITests.swift`

A best-effort UI test that exercises the on-device flow with a mocked Firestore service backing. If the test target lacks a swappable injection point, document it as a manual QA step and skip the file (do **not** ship a flaky test).

- [ ] **Step 1: Investigate test injection feasibility**

Check whether `QuestPresenter` accepts a mock `FirestoreQuestService` in tests. If yes, proceed. If no, add a `#if DEBUG`-guarded factory hook in Plan 2's service before continuing.

- [ ] **Step 2: Author the UI test**

Create `SoulverseUITests/QuestDay7ToImportanceFlowUITests.swift`:

```swift
import XCTest

final class QuestDay7ToImportanceFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testDay7ImportancePendingThenEightDimUnlocks() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-UITestQuestStateFixture", "day7-importance-pending"
        ]
        app.launch()

        // Tap Quest tab.
        app.tabBars.buttons["tab_quest"].tap()

        // Survey section visible (was hidden at day < 7).
        let pendingTitle = app.staticTexts["Importance Check-In"]
        XCTAssertTrue(pendingTitle.waitForExistence(timeout: 5))

        // Tap pending card → Survey VC presents.
        pendingTitle.tap()
        XCTAssertTrue(app.navigationBars["Importance Check-In"].waitForExistence(timeout: 5))

        // Skip the questionnaire UX details (Plan 4's domain) — pass control back via a debug hook.
        app.buttons["debug_submit_importance_emotional"].tap()

        // Result screen.
        XCTAssertTrue(app.staticTexts["Your top priority is Emotional."].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()

        // 8-Dim now pending.
        XCTAssertTrue(app.staticTexts["Wellness Check-In"].waitForExistence(timeout: 5))

        // 8-Dim card unlocked — focus axis (Emotional) shows 5 outline dots.
        // Smoke check: card has accessibilityIdentifier "8dim_card_unlocked_focus_emotional".
        XCTAssertTrue(app.otherElements["8dim_card_unlocked_focus_emotional"].exists)
    }
}
```

> If Plan 2 hasn't shipped the `-UITestQuestStateFixture` launch argument hook, mark this test as `XCTSkip("UI test fixture hook not yet wired")` and add a TODO comment. Do not delete the file — Plan 7 picks it up.

- [ ] **Step 3: Run the UI test**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseUITests/QuestDay7ToImportanceFlowUITests -quiet
```

Expected: test passes if the fixture hook is wired; otherwise it is skipped with a clear message.

- [ ] **Step 4: Commit**

```bash
git add SoulverseUITests/QuestDay7ToImportanceFlowUITests.swift
git commit -m "test(quest): add best-effort UI test for Day-7 → Importance → 8-Dim unlock flow"
```

---

## Task 19: Real-time refresh smoke test

**Files:**
- Create: `SoulverseTests/Features/Quest/QuestPresenterRealtimeTests.swift`

Verifies that two separate listener callbacks (quest_state then recent submissions, or vice versa) both result in a `view?.render(viewModel:)` call with consistent state.

- [ ] **Step 1: Write the test**

Create `SoulverseTests/Features/Quest/QuestPresenterRealtimeTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class QuestPresenterRealtimeTests: XCTestCase {

    final class StubQuestService: FirestoreQuestService {
        let subject = PassthroughSubjectStub<QuestState>()
        override func observeQuestState(uid: String) -> AnyPublisherStub<QuestState> {
            subject.eraseToPublisher()
        }
    }

    final class StubSurveyService: FirestoreSurveyService {
        let subject = PassthroughSubjectStub<[SurveySubmission]>()
        override func observeRecentSubmissions(uid: String, windowDays: Int)
            -> AnyPublisherStub<[SurveySubmission]>
        {
            subject.eraseToPublisher()
        }
    }

    final class SpyView: QuestPresenterView {
        var rendered: [QuestViewModel] = []
        func render(viewModel: QuestViewModel) { rendered.append(viewModel) }
        func present(_ vc: UIViewController) {}
    }

    func testTwoEventsResultInTwoRenders() {
        let view = SpyView()
        let qs = StubQuestService()
        let ss = StubSurveyService()
        let presenter = QuestPresenter(view: view, questService: qs, surveyService: ss)
        presenter.start(uid: "u")

        // First event: quest_state arrives
        qs.subject.send(stateAt(days: 21, focus: .emotional))
        // Second event: recent submissions arrive
        ss.subject.send([])

        XCTAssertGreaterThanOrEqual(view.rendered.count, 1,
                                    "Presenter should render after listener events")
        let last = view.rendered.last!
        switch last.surveySection {
        case .composed: XCTAssertTrue(true)
        case .hidden: XCTFail("Expected composed at day 21")
        }
    }

    private func stateAt(days: Int, focus: WellnessDimension) -> QuestState {
        QuestState(
            distinctCheckInDays: days, lastDistinctDayKey: nil, questCompletedAt: nil,
            focusDimension: focus, focusDimensionAssignedAt: Date(),
            pendingSurveys: [], surveyEligibleSinceMap: [:],
            importanceCheckInSubmittedAt: Date(),
            lastEightDimSubmittedAt: nil, lastEightDimDimension: nil, lastEightDimSummary: nil,
            lastStateOfChangeSubmittedAt: nil, lastStateOfChangeStage: nil,
            satisfactionCheckInSubmittedAt: nil,
            lastSatisfactionTopCategory: nil, lastSatisfactionLowestCategory: nil,
            notificationHour: 1, timezoneOffsetMinutes: 480
        )
    }
}
```

> If Plan 2's services use a Combine publisher type rather than the `PassthroughSubjectStub`/`AnyPublisherStub` placeholders, swap to the real types. The point of the test is multi-event coverage, not a particular reactive abstraction.

- [ ] **Step 2: Run the test**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestPresenterRealtimeTests -quiet
```

Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add SoulverseTests/Features/Quest/QuestPresenterRealtimeTests.swift
git commit -m "test(quest): verify presenter renders on each listener event"
```

---

## Task 20: Final build + full unit-test run

**Files:** (No new files)

- [ ] **Step 1: Run all Quest-related unit tests**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test \
  -only-testing:SoulverseTests/SurveySectionComposerTests \
  -only-testing:SoulverseTests/EightDimensionsRenderModelBuilderTests \
  -only-testing:SoulverseTests/PendingSurveyDeckOrderingTests \
  -only-testing:SoulverseTests/StateOfChangeIndicatorViewModelTests \
  -only-testing:SoulverseTests/QuestPresenterRealtimeTests \
  -quiet
```

Expected: all tests pass.

- [ ] **Step 2: Build the Debug target**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Smoke test on simulator**

Boot iPhone 16 Pro Max simulator, install the build, and exercise:

1. Quest tab at Day 3 fixture: 8-Dim card all-lock, no SurveySection visible.
2. Quest tab at Day 7 fixture (focus null): SurveySection visible with Importance card front; 8-Dim card all-lock locks (focus not yet assigned).
3. Submit Importance via debug hook → focus assigned → 8-Dim card focus axis shows 5 outline dots; SurveySection swaps Importance result card in and 8-Dim pending card to front of deck.
4. Submit 8-Dim → result card appears under deck; pending deck advances.
5. Submit SoC at stage 3 → SoC indicator below radar shows "Preparing" highlighted; solid focus dot appears at stage-3 position on radar.

- [ ] **Step 4: Commit (deployment marker)**

No code change, but tag:

```bash
git tag -a quest-plan-5-complete -m "Plan 5 complete: SurveySection + radar refactor shipped"
```

---

## Plan summary & next steps

**This plan delivers:**
- `SurveySectionComposer` — pure-function deck + result list composition driven by `quest_state.pendingSurveys` and `surveyEligibleSinceMap`.
- `EightDimensionsRenderModelBuilder` — pure-function per-axis state machine for the radar overlay.
- `QuestRadarChartView` refactored: polygon fill disabled, DGCharts axis web/grid retained.
- `QuestRadarOverlayView` — UIImageView-based per-axis dots, lock icons, center EmoPet.
- `StateOfChangeIndicatorView` — friendly-label 5-dot indicator below the radar.
- `EightDimensionsCardView` — composes radar + indicator + locked-card affordance.
- `SurveySectionView` + `PendingSurveyDeckView` + `RecentResultCardListView` — full Plan 5 UX.
- Real-time presenter integration via Plan 2's Firestore listener.
- Comprehensive unit tests (composition predicates, deck ordering, render-model state machine, presenter listener fan-in).
- Best-effort UI test for the Day-7 → Importance → 8-Dim end-to-end flow.
- Localized strings for all Plan 5 surfaces (en).

**Pending iOS work:**
- Plan 6: FCM token registration + permission UX + push handlers.
- Plan 7: Final theme + localization audit + manual QA checklist (incl. deck animation polish, locked-card hint copy variants per spec §5.3).

The next plan (Plan 6) can begin in parallel — Plan 5's UI is decoupled from notifications and consumes only the `quest_state` already populated by Plan 1.
