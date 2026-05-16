# Onboarding Quest — Plan 2 of 7: Quest Tab UI Shell + Day-Counter Display

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the iOS Quest tab to the server-maintained `users/{uid}/quest_state` aggregate doc so the screen renders the Day-N counter, segmented progress dots, the Day-1 "Do today's Mood Check-In" CTA, and the locked-card affordances for the 8-Dimensions card and Custom Habit slot. After this plan, opening the Quest tab will display real-time counter state from Firestore, hide all unlocked content correctly per stage, and route the user to Mood Check-In when they tap the daily CTA. The Survey section is hidden entirely until Day 7 (per spec §5 / Phase 5 revision); habit/survey content arrives in Plans 3–4.

**Architecture:** New `FirestoreQuestService` (under `Soulverse/Shared/Service/QuestService/`) opens a real-time listener on `users/{uid}/quest_state/state` and writes `timezoneOffsetMinutes` + `notificationHour` at app launch (the only client-writable fields per Plan 1's Security Rules). `QuestViewPresenter` subscribes to the service and rebuilds a framework-agnostic `QuestViewModel` on every snapshot. `QuestViewController` rebuilds its scrolling content from the view model: a new `ProgressSection` subview at the top, plus locked-state placeholders for the 8-Dimensions card and Custom Habit slot. All UI strings live in `en.lproj/Localizable.strings`. Habit, survey, and radar-chart content land in Plans 3–5; this plan only ensures their host views render the proximity-aware locked-card hints.

**Tech Stack:** Swift, UIKit, SnapKit, FirebaseFirestore, NSLocalizedString, theme-aware colors, XCTest.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md`

---

## File structure

After this plan, the iOS app will have:

```
Soulverse/
  Shared/Service/QuestService/
    QuestStateModel.swift                   # Codable QuestState (aggregate doc)
    QuestServiceProtocol.swift              # listen / write contract
    FirestoreQuestService.swift             # live listener + timezone/hour writes
  Features/Quest/
    Presenter/
      QuestViewPresenter.swift              # MODIFIED — listener-driven, no mock
    ViewModels/
      QuestViewModel.swift                  # MODIFIED — listener-driven shape
      QuestStage.swift                      # NEW — pure stage derivation
      LockedCardHint.swift                  # NEW — proximity-aware hint copy
    Views/
      QuestViewController.swift             # MODIFIED — section layout
      ProgressSection/
        QuestProgressSectionView.swift      # NEW — pill, dots, CTA
        QuestProgressDotsView.swift         # NEW — 21 dots × 3 stages
      LockedCard/
        QuestLockedCardView.swift           # NEW — dimmed + tap hint
SoulverseTests/
  Tests/Quest/
    QuestStageTests.swift                   # NEW
    LockedCardHintTests.swift               # NEW
    QuestViewModelTests.swift               # NEW
    QuestViewPresenterTests.swift           # NEW
  Mocks/Shared/Service/
    QuestServiceMock.swift                  # NEW
Soulverse/en.lproj/Localizable.strings      # MODIFIED — Quest progress + lock keys
```

The remaining Quest scope (Habit Checker section, full Survey section composition, radar chart refactor, FCM, polish) is delivered by Plans 3–7.

---

## Cross-plan dependencies

- **Plan 1 (Cloud Functions)** must be deployed before this plan reaches production: this plan reads `users/{uid}/quest_state` and assumes the doc is auto-created by `onUserCreated` and maintained by the other triggers. Local development and unit tests do not require Plan 1 — `QuestServiceMock` substitutes the listener.
- **Plan 1 Security Rules** allow the client to write only `timezoneOffsetMinutes` and `notificationHour` on `quest_state`. This plan implements that single-purpose write at app launch; any other field write will be rejected.
- **Plan 3 (Habit Checker)** will consume the `lockedCardState` for the Custom Habit slot exposed in this plan's `QuestViewModel`. The hint-copy logic and locked-card view are shared — Plan 3 reuses `QuestLockedCardView` for the Add-Custom-Habit affordance.
- **Plan 4 (Survey infrastructure)** consumes `state.distinctCheckInDays >= 7` from `QuestViewModel.surveySectionVisible` to know when to render its content. This plan emits the flag and a hidden host view; Plan 4 fills it in.
- **Plan 5 (Radar chart refactor)** consumes `QuestViewModel.eightDimensionsLockedHint` for the locked-card overlay until Day 7. This plan supplies that hint and the `QuestLockedCardView` host; Plan 5 replaces the locked content with the rendered radar chart once `focusDimension` is non-nil.

---

## Task 1: Define `QuestStateModel` matching Plan 1's aggregate doc

**Files:**
- Create: `Soulverse/Shared/Service/QuestService/QuestStateModel.swift`

This Codable struct mirrors the Plan-1 server schema at `users/{uid}/quest_state/state`. Field names match the TypeScript `QuestState` interface exactly so Firestore decoding is direct.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestStateModelTests.swift`:

```swift
//
//  QuestStateModelTests.swift
//  SoulverseTests
//

import XCTest
import FirebaseFirestore
@testable import Soulverse

final class QuestStateModelTests: XCTestCase {

    func test_QuestStateModel_initialState_hasZeroDays() {
        let state = QuestStateModel.initial()
        XCTAssertEqual(state.distinctCheckInDays, 0)
        XCTAssertNil(state.focusDimension)
        XCTAssertTrue(state.pendingSurveys.isEmpty)
        XCTAssertNil(state.lastDistinctDayKey)
        XCTAssertNil(state.questCompletedAt)
    }

    func test_QuestStateModel_decodesFromFirestoreDictionary() throws {
        let data: [String: Any] = [
            "distinctCheckInDays": 5,
            "lastDistinctDayKey": "2026-04-29",
            "focusDimension": NSNull(),
            "pendingSurveys": [],
            "surveyEligibleSinceMap": [:],
            "notificationHour": 1,
            "timezoneOffsetMinutes": 480
        ]
        let state = QuestStateModel.fromDictionary(data)
        XCTAssertEqual(state.distinctCheckInDays, 5)
        XCTAssertEqual(state.lastDistinctDayKey, "2026-04-29")
        XCTAssertNil(state.focusDimension)
        XCTAssertEqual(state.notificationHour, 1)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestStateModelTests -quiet
```

Expected: build fails — `QuestStateModel` does not exist.

- [ ] **Step 3: Implement the model**

Create `Soulverse/Shared/Service/QuestService/QuestStateModel.swift`:

```swift
//
//  QuestStateModel.swift
//  Soulverse
//
//  Mirrors the server-maintained aggregate doc at
//  users/{uid}/quest_state/state. Plan 1 owns writes for all fields except
//  `timezoneOffsetMinutes` and `notificationHour` (client-writable per
//  Security Rules; see Plan 1 §7.2).
//

import Foundation
import FirebaseFirestore

/// Eight wellness dimensions. Mirrors mood_checkins.topic enum + Plan 1 WellnessDimension.
enum WellnessDimension: String, Codable, CaseIterable {
    case physical
    case emotional
    case social
    case intellectual
    case spiritual
    case occupational
    case environmental
    case financial
}

enum SurveyType: String, Codable, CaseIterable {
    case importanceCheckIn = "importance_check_in"
    case eightDim = "8dim"
    case stateOfChange = "state_of_change"
    case satisfactionCheckIn = "satisfaction_check_in"
}

struct QuestStateModel {

    // Day counter & quest progression
    var distinctCheckInDays: Int
    var lastDistinctDayKey: String?
    var questCompletedAt: Date?

    // Focus dimension & UX state
    var focusDimension: WellnessDimension?
    var focusDimensionAssignedAt: Date?

    // Server-derived pending surveys
    var pendingSurveys: [SurveyType]
    var surveyEligibleSinceMap: [String: Date]

    // Survey submission timestamps (denormalized, read-only on client)
    var importanceCheckInSubmittedAt: Date?
    var lastEightDimSubmittedAt: Date?
    var lastEightDimDimension: WellnessDimension?
    var lastStateOfChangeSubmittedAt: Date?
    var lastStateOfChangeStage: Int?
    var satisfactionCheckInSubmittedAt: Date?

    // Cron query optimization (client-writable)
    var notificationHour: Int
    var timezoneOffsetMinutes: Int

    static func initial() -> QuestStateModel {
        return QuestStateModel(
            distinctCheckInDays: 0,
            lastDistinctDayKey: nil,
            questCompletedAt: nil,
            focusDimension: nil,
            focusDimensionAssignedAt: nil,
            pendingSurveys: [],
            surveyEligibleSinceMap: [:],
            importanceCheckInSubmittedAt: nil,
            lastEightDimSubmittedAt: nil,
            lastEightDimDimension: nil,
            lastStateOfChangeSubmittedAt: nil,
            lastStateOfChangeStage: nil,
            satisfactionCheckInSubmittedAt: nil,
            notificationHour: 0,
            timezoneOffsetMinutes: 0
        )
    }

    static func fromDictionary(_ data: [String: Any]) -> QuestStateModel {
        let pending: [SurveyType] = (data["pendingSurveys"] as? [String] ?? [])
            .compactMap { SurveyType(rawValue: $0) }

        var eligibleMap: [String: Date] = [:]
        if let raw = data["surveyEligibleSinceMap"] as? [String: Timestamp] {
            for (key, value) in raw { eligibleMap[key] = value.dateValue() }
        }

        return QuestStateModel(
            distinctCheckInDays: data["distinctCheckInDays"] as? Int ?? 0,
            lastDistinctDayKey: data["lastDistinctDayKey"] as? String,
            questCompletedAt: (data["questCompletedAt"] as? Timestamp)?.dateValue(),
            focusDimension: (data["focusDimension"] as? String).flatMap(WellnessDimension.init(rawValue:)),
            focusDimensionAssignedAt: (data["focusDimensionAssignedAt"] as? Timestamp)?.dateValue(),
            pendingSurveys: pending,
            surveyEligibleSinceMap: eligibleMap,
            importanceCheckInSubmittedAt: (data["importanceCheckInSubmittedAt"] as? Timestamp)?.dateValue(),
            lastEightDimSubmittedAt: (data["lastEightDimSubmittedAt"] as? Timestamp)?.dateValue(),
            lastEightDimDimension: (data["lastEightDimDimension"] as? String).flatMap(WellnessDimension.init(rawValue:)),
            lastStateOfChangeSubmittedAt: (data["lastStateOfChangeSubmittedAt"] as? Timestamp)?.dateValue(),
            lastStateOfChangeStage: data["lastStateOfChangeStage"] as? Int,
            satisfactionCheckInSubmittedAt: (data["satisfactionCheckInSubmittedAt"] as? Timestamp)?.dateValue(),
            notificationHour: data["notificationHour"] as? Int ?? 0,
            timezoneOffsetMinutes: data["timezoneOffsetMinutes"] as? Int ?? 0
        )
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestStateModelTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Shared/Service/QuestService/QuestStateModel.swift \
        SoulverseTests/Tests/Quest/QuestStateModelTests.swift
git commit -m "feat(quest): add QuestStateModel mirroring Plan-1 aggregate doc"
```

---

## Task 2: Pure `QuestStage` derivation

**Files:**
- Create: `Soulverse/Features/Quest/ViewModels/QuestStage.swift`
- Create: `SoulverseTests/Tests/Quest/QuestStageTests.swift`

`QuestStage` derives the current stage (1, 2, 3, or `.completed`) and stage-bounded dot ranges purely from `distinctCheckInDays`. No UIKit imports.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestStageTests.swift`:

```swift
//
//  QuestStageTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestStageTests: XCTestCase {

    func test_QuestStage_zeroDays_isStage1() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 0), .stage1)
    }

    func test_QuestStage_day1to7_isStage1() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 1), .stage1)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 6), .stage1)
    }

    func test_QuestStage_day7to13_isStage2() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 7), .stage2)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 13), .stage2)
    }

    func test_QuestStage_day14to20_isStage3() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 14), .stage3)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 20), .stage3)
    }

    func test_QuestStage_day21orMore_isCompleted() {
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 21), .completed)
        XCTAssertEqual(QuestStage.from(distinctCheckInDays: 50), .completed)
    }

    func test_QuestStage_dotRange_stage1_isOneToSeven() {
        XCTAssertEqual(QuestStage.stage1.dotRange, 1...7)
    }

    func test_QuestStage_dotRange_stage2_isEightToFourteen() {
        XCTAssertEqual(QuestStage.stage2.dotRange, 8...14)
    }

    func test_QuestStage_dotRange_stage3_isFifteenToTwentyOne() {
        XCTAssertEqual(QuestStage.stage3.dotRange, 15...21)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestStageTests -quiet
```

Expected: build fails — `QuestStage` does not exist.

- [ ] **Step 3: Implement the type**

Create `Soulverse/Features/Quest/ViewModels/QuestStage.swift`:

```swift
//
//  QuestStage.swift
//  Soulverse
//
//  Pure stage derivation from distinctCheckInDays. No UIKit; safe to use
//  inside framework-agnostic ViewModel code.
//

import Foundation

enum QuestStage: Equatable {
    case stage1     // distinctCheckInDays 0..6
    case stage2     // distinctCheckInDays 7..13
    case stage3     // distinctCheckInDays 14..20
    case completed  // distinctCheckInDays >= 21

    static func from(distinctCheckInDays days: Int) -> QuestStage {
        switch days {
        case ..<7:    return .stage1
        case 7...13:  return .stage2
        case 14...20: return .stage3
        default:      return .completed
        }
    }

    /// Inclusive 1-indexed dot range belonging to this stage on the 21-dot rail.
    var dotRange: ClosedRange<Int> {
        switch self {
        case .stage1:    return 1...7
        case .stage2:    return 8...14
        case .stage3:    return 15...21
        case .completed: return 1...21
        }
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestStageTests -quiet
```

Expected: PASS — all 8 cases.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/QuestStage.swift \
        SoulverseTests/Tests/Quest/QuestStageTests.swift
git commit -m "feat(quest): derive stage and dot range from distinctCheckInDays"
```

---

## Task 3: Locked-card hint copy with proximity logic

**Files:**
- Create: `Soulverse/Features/Quest/ViewModels/LockedCardHint.swift`
- Create: `SoulverseTests/Tests/Quest/LockedCardHintTests.swift`

Per spec §5.3:

| Distance from unlock | Hint copy |
|---|---|
| > 3 days from threshold | "On Day {X}, you'll {feature}." |
| ≤ 2 days | "Just {N} more check-ins!" |
| 1 day | "Just 1 more check-in!" |

The boundary at "3 days" is the unlock proximity gate: when remaining is **2 or fewer**, switch to "Just N more"; when remaining is **3 or more**, use "On Day X". The 1-day case uses singular grammar.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/LockedCardHintTests.swift`:

```swift
//
//  LockedCardHintTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class LockedCardHintTests: XCTestCase {

    private let featureName = "see your 8 Dimensions"
    private let unlockDay = 7

    // MARK: - Far-away (> 3 days remaining)

    func test_LockedCardHint_farAway_useFutureDayCopy() {
        let hint = LockedCardHint.copy(
            currentDay: 1,
            unlockDay: unlockDay,
            featureName: featureName
        )
        XCTAssertEqual(hint, "On Day 7, you'll see your 8 Dimensions.")
    }

    func test_LockedCardHint_threeRemaining_stillUseFutureDayCopy() {
        // remaining = 7 - 4 = 3 → still "On Day X"
        let hint = LockedCardHint.copy(
            currentDay: 4,
            unlockDay: unlockDay,
            featureName: featureName
        )
        XCTAssertEqual(hint, "On Day 7, you'll see your 8 Dimensions.")
    }

    // MARK: - Close range (2 days)

    func test_LockedCardHint_twoRemaining_useJustNCopy() {
        // remaining = 7 - 5 = 2 → "Just 2 more check-ins!"
        let hint = LockedCardHint.copy(
            currentDay: 5,
            unlockDay: unlockDay,
            featureName: featureName
        )
        XCTAssertEqual(hint, "Just 2 more check-ins!")
    }

    // MARK: - One day

    func test_LockedCardHint_oneRemaining_useSingularCopy() {
        let hint = LockedCardHint.copy(
            currentDay: 6,
            unlockDay: unlockDay,
            featureName: featureName
        )
        XCTAssertEqual(hint, "Just 1 more check-in!")
    }

    // MARK: - At or past unlock — caller should not show locked state

    func test_LockedCardHint_atUnlock_returnsEmpty() {
        let hint = LockedCardHint.copy(
            currentDay: 7,
            unlockDay: unlockDay,
            featureName: featureName
        )
        XCTAssertEqual(hint, "")
    }

    func test_LockedCardHint_pastUnlock_returnsEmpty() {
        let hint = LockedCardHint.copy(
            currentDay: 12,
            unlockDay: unlockDay,
            featureName: featureName
        )
        XCTAssertEqual(hint, "")
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/LockedCardHintTests -quiet
```

Expected: build fails — `LockedCardHint` does not exist.

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/ViewModels/LockedCardHint.swift`:

```swift
//
//  LockedCardHint.swift
//  Soulverse
//
//  Proximity-aware hint copy for locked Quest cards (8-Dim, Custom Habit
//  slot, etc.). Pure function of (currentDay, unlockDay, featureName);
//  framework-agnostic.
//

import Foundation

enum LockedCardHint {

    /// Returns the hint text per spec §5.3:
    /// - remaining ≥ 3:  "On Day {unlockDay}, you'll {featureName}."
    /// - remaining == 2: "Just 2 more check-ins!"
    /// - remaining == 1: "Just 1 more check-in!"
    /// - remaining ≤ 0:  "" (caller should not show locked state)
    static func copy(currentDay: Int, unlockDay: Int, featureName: String) -> String {
        let remaining = unlockDay - currentDay
        guard remaining > 0 else { return "" }

        if remaining >= 3 {
            let format = NSLocalizedString(
                "quest_locked_hint_future_day",
                comment: "Locked-card hint when unlock is more than 2 days away"
            )
            return String(format: format, unlockDay, featureName)
        }

        if remaining == 1 {
            return NSLocalizedString(
                "quest_locked_hint_one_more",
                comment: "Locked-card hint when only 1 day remains"
            )
        }

        let format = NSLocalizedString(
            "quest_locked_hint_n_more",
            comment: "Locked-card hint when 2 days remain"
        )
        return String(format: format, remaining)
    }
}
```

- [ ] **Step 4: Add localization keys and re-run the test**

Append to `Soulverse/en.lproj/Localizable.strings`:

```
// Quest — locked card hints (proximity-based)
"quest_locked_hint_future_day" = "On Day %d, you'll %@.";
"quest_locked_hint_n_more" = "Just %d more check-ins!";
"quest_locked_hint_one_more" = "Just 1 more check-in!";
```

Run:

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/LockedCardHintTests -quiet
```

Expected: PASS — all 6 cases.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/LockedCardHint.swift \
        SoulverseTests/Tests/Quest/LockedCardHintTests.swift \
        Soulverse/en.lproj/Localizable.strings
git commit -m "feat(quest): proximity-based locked-card hint copy with localized strings"
```

---

## Task 4: Define `QuestServiceProtocol` and `QuestServiceMock`

**Files:**
- Create: `Soulverse/Shared/Service/QuestService/QuestServiceProtocol.swift`
- Create: `SoulverseTests/Mocks/Shared/Service/QuestServiceMock.swift`

The protocol decouples Firestore from the presenter. The mock is shared by all Quest tests.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestServiceMockTests.swift`:

```swift
//
//  QuestServiceMockTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestServiceMockTests: XCTestCase {

    func test_QuestServiceMock_emitsInitialState_thenUpdates() {
        let mock = QuestServiceMock()
        var received: [QuestStateModel] = []

        let token = mock.listen(uid: "u1") { state in
            received.append(state)
        }

        // Initial pulse is the seeded value.
        mock.emit(QuestStateModel.initial())
        var updated = QuestStateModel.initial()
        updated.distinctCheckInDays = 5
        mock.emit(updated)

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0].distinctCheckInDays, 0)
        XCTAssertEqual(received[1].distinctCheckInDays, 5)

        token.cancel()
    }

    func test_QuestServiceMock_recordsTimezoneWrite() {
        let mock = QuestServiceMock()
        mock.writeTimezone(uid: "u1", offsetMinutes: 480, notificationHour: 1) { _ in }
        XCTAssertEqual(mock.lastWrittenOffsetMinutes, 480)
        XCTAssertEqual(mock.lastWrittenNotificationHour, 1)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestServiceMockTests -quiet
```

Expected: build fails — `QuestServiceProtocol` and `QuestServiceMock` do not exist.

- [ ] **Step 3: Implement protocol and mock**

Create `Soulverse/Shared/Service/QuestService/QuestServiceProtocol.swift`:

```swift
//
//  QuestServiceProtocol.swift
//  Soulverse
//

import Foundation

/// Cancels an active quest_state listener. Stored by callers and invoked on deinit.
final class QuestListenerToken {
    private let cancelHandler: () -> Void
    private var cancelled: Bool = false

    init(cancelHandler: @escaping () -> Void) {
        self.cancelHandler = cancelHandler
    }

    func cancel() {
        guard !cancelled else { return }
        cancelled = true
        cancelHandler()
    }

    deinit { cancel() }
}

protocol QuestServiceProtocol: AnyObject {
    /// Subscribes to real-time updates of users/{uid}/quest_state/state.
    /// The handler fires on the main queue. Pass the returned token to keep
    /// the listener alive; release it to unsubscribe.
    func listen(uid: String, onUpdate: @escaping (QuestStateModel) -> Void) -> QuestListenerToken

    /// Writes the two client-allowed quest_state fields. Per Plan 1 Security
    /// Rules, all other fields would reject.
    func writeTimezone(
        uid: String,
        offsetMinutes: Int,
        notificationHour: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}
```

Create `SoulverseTests/Mocks/Shared/Service/QuestServiceMock.swift`:

```swift
//
//  QuestServiceMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class QuestServiceMock: QuestServiceProtocol {

    private(set) var lastWrittenOffsetMinutes: Int?
    private(set) var lastWrittenNotificationHour: Int?
    private(set) var listenedUid: String?

    private var handler: ((QuestStateModel) -> Void)?

    func listen(uid: String, onUpdate: @escaping (QuestStateModel) -> Void) -> QuestListenerToken {
        listenedUid = uid
        handler = onUpdate
        return QuestListenerToken { [weak self] in
            self?.handler = nil
        }
    }

    func emit(_ state: QuestStateModel) {
        handler?(state)
    }

    func writeTimezone(
        uid: String,
        offsetMinutes: Int,
        notificationHour: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        lastWrittenOffsetMinutes = offsetMinutes
        lastWrittenNotificationHour = notificationHour
        completion(.success(()))
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestServiceMockTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Shared/Service/QuestService/QuestServiceProtocol.swift \
        SoulverseTests/Mocks/Shared/Service/QuestServiceMock.swift \
        SoulverseTests/Tests/Quest/QuestServiceMockTests.swift
git commit -m "feat(quest): add QuestServiceProtocol with QuestServiceMock for tests"
```

---

## Task 5: `FirestoreQuestService` — listener + timezone write

**Files:**
- Create: `Soulverse/Shared/Service/QuestService/FirestoreQuestService.swift`
- Modify: `Soulverse/Shared/Service/FirestoreSchema.swift`

Concrete implementation that opens a snapshot listener on `users/{uid}/quest_state/state` and writes the two client-allowed fields. Quest writes are gated by Plan 1 Security Rules to `timezoneOffsetMinutes` and `notificationHour` only.

- [ ] **Step 1: Add quest_state collection to schema**

Modify `Soulverse/Shared/Service/FirestoreSchema.swift` — add inside `enum FirestoreCollection`:

```swift
    /// Subcollection for the Quest aggregate doc under a user.
    /// Path: `users/{uid}/quest_state/state`
    static let questState = "quest_state"

    /// Stable single-doc id under quest_state. Plan 1 writes this same id.
    static let questStateDocId = "state"
```

- [ ] **Step 2: Write the failing service test (manual smoke test)**

`FirestoreQuestService` is exercised manually against the Firestore Emulator (matches the existing `FirestoreUserService` pattern in this repo, which has no automated emulator tests). For the unit-test layer, the `QuestServiceMock` from Task 4 covers presenter behavior.

Create `SoulverseTests/Tests/Quest/FirestoreQuestServiceTests.swift` — a compile-time smoke that the service conforms to the protocol:

```swift
//
//  FirestoreQuestServiceTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class FirestoreQuestServiceTests: XCTestCase {

    func test_FirestoreQuestService_conformsToProtocol() {
        let service: QuestServiceProtocol = FirestoreQuestService.shared
        XCTAssertNotNil(service)
    }
}
```

- [ ] **Step 3: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/FirestoreQuestServiceTests -quiet
```

Expected: build fails — `FirestoreQuestService` does not exist.

- [ ] **Step 4: Implement the service**

Create `Soulverse/Shared/Service/QuestService/FirestoreQuestService.swift`:

```swift
//
//  FirestoreQuestService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreQuestService: QuestServiceProtocol {

    static let shared = FirestoreQuestService()

    private let db = Firestore.firestore()

    private init() {}

    private func stateDocument(uid: String) -> DocumentReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.questState)
            .document(FirestoreCollection.questStateDocId)
    }

    // MARK: - Listen

    func listen(uid: String, onUpdate: @escaping (QuestStateModel) -> Void) -> QuestListenerToken {
        let registration = stateDocument(uid: uid).addSnapshotListener { snapshot, error in
            if let error = error {
                print("[FirestoreQuestService] listener error: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot else { return }
            // Doc may briefly not exist for a fresh user before onUserCreated runs.
            let data = snapshot.data() ?? [:]
            let state = QuestStateModel.fromDictionary(data)
            DispatchQueue.main.async { onUpdate(state) }
        }
        return QuestListenerToken { registration.remove() }
    }

    // MARK: - Write timezone (only client-writable fields)

    func writeTimezone(
        uid: String,
        offsetMinutes: Int,
        notificationHour: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let payload: [String: Any] = [
            "timezoneOffsetMinutes": offsetMinutes,
            "notificationHour": notificationHour
        ]
        // Use setData(merge:) so the call works even before the doc has been
        // created by Plan 1's onUserCreated trigger (race on first sign-in).
        stateDocument(uid: uid).setData(payload, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
```

- [ ] **Step 5: Run the test and commit**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/FirestoreQuestServiceTests -quiet
```

Expected: PASS.

```bash
git add Soulverse/Shared/Service/QuestService/FirestoreQuestService.swift \
        Soulverse/Shared/Service/FirestoreSchema.swift \
        SoulverseTests/Tests/Quest/FirestoreQuestServiceTests.swift
git commit -m "feat(quest): FirestoreQuestService with snapshot listener + timezone write"
```

---

## Task 6: Write `timezoneOffsetMinutes` + `notificationHour` at app launch

**Files:**
- Modify: `Soulverse/AppDelegate.swift` (or the existing post-login hook used for FCM token writes)

Per spec §4.1: `notificationHour` is "user-local 9am → UTC hour". We compute it once at app launch (and every cold start) and write both fields via `FirestoreQuestService`. Plan 1's Security Rules accept exactly this two-field update; any other quest_state mutation fails.

- [ ] **Step 1: Locate the existing post-login hook**

```bash
grep -n "User.shared.userId\|isLoggedin\|didFinishLaunching\|sceneDidBecomeActive" Soulverse/AppDelegate.swift Soulverse/SceneDelegate.swift | head -30
```

The Quest timezone push goes wherever `User.shared.userId` is known to be set on app foreground (matches the pattern used by FCM token registration in `User.swift`). Choose the same site.

- [ ] **Step 2: Write a presenter-style test for the timezone-hour formula**

Create `SoulverseTests/Tests/Quest/QuestNotificationHourTests.swift`:

```swift
//
//  QuestNotificationHourTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestNotificationHourTests: XCTestCase {

    func test_notificationHour_utcPlusEight_9amLocal_isOneAmUTC() {
        // 9am local in UTC+8 → 1am UTC.
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 9,
            timezoneOffsetMinutes: 8 * 60
        )
        XCTAssertEqual(hour, 1)
    }

    func test_notificationHour_utcMinusFive_9amLocal_isFourteenUTC() {
        // 9am local in UTC-5 → 14:00 UTC.
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 9,
            timezoneOffsetMinutes: -5 * 60
        )
        XCTAssertEqual(hour, 14)
    }

    func test_notificationHour_wrapsAroundMidnight() {
        // 1am local in UTC+8 → 17:00 UTC the prior day. Hour is 17.
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 1,
            timezoneOffsetMinutes: 8 * 60
        )
        XCTAssertEqual(hour, 17)
    }

    func test_notificationHour_utc_returnsLocalHour() {
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 9,
            timezoneOffsetMinutes: 0
        )
        XCTAssertEqual(hour, 9)
    }
}
```

- [ ] **Step 3: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestNotificationHourTests -quiet
```

Expected: build fails — `QuestTimezoneCalculator` does not exist.

- [ ] **Step 4: Implement and wire into the app launch path**

Create `Soulverse/Shared/Service/QuestService/QuestTimezoneCalculator.swift`:

```swift
//
//  QuestTimezoneCalculator.swift
//  Soulverse
//

import Foundation

enum QuestTimezoneCalculator {

    /// Default user-local notification hour. Spec §4.1 quotes 9am.
    static let defaultLocalHour: Int = 9

    /// Returns the UTC hour (0..23) corresponding to `localHour` in a timezone
    /// whose offset (in minutes east of UTC) is `timezoneOffsetMinutes`.
    static func notificationHour(forLocalHour localHour: Int, timezoneOffsetMinutes offset: Int) -> Int {
        let offsetHours = offset / 60
        let utcHour = (localHour - offsetHours) % 24
        return (utcHour + 24) % 24
    }

    /// Pulls offset directly from the device.
    static func currentOffsetMinutes() -> Int {
        return TimeZone.current.secondsFromGMT() / 60
    }
}

extension FirestoreQuestService {

    /// Convenience: pushes the device's current tz + 9am-local-as-UTC-hour.
    func writeCurrentTimezone(uid: String) {
        let offsetMinutes = QuestTimezoneCalculator.currentOffsetMinutes()
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: QuestTimezoneCalculator.defaultLocalHour,
            timezoneOffsetMinutes: offsetMinutes
        )
        writeTimezone(uid: uid, offsetMinutes: offsetMinutes, notificationHour: hour) { result in
            if case let .failure(error) = result {
                print("[Quest] writeCurrentTimezone failed: \(error.localizedDescription)")
            }
        }
    }
}
```

Then wire into `AppDelegate.swift`'s `application(_:didFinishLaunchingWithOptions:)` (or `SceneDelegate.swift` `sceneDidBecomeActive`, whichever matches the FCM-token write site found in Step 1) — append at the end of the launch hook:

```swift
if let uid = User.shared.userId {
    FirestoreQuestService.shared.writeCurrentTimezone(uid: uid)
}
```

- [ ] **Step 5: Run tests and commit**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestNotificationHourTests -quiet
```

Expected: PASS — all 4 cases.

```bash
git add Soulverse/Shared/Service/QuestService/QuestTimezoneCalculator.swift \
        Soulverse/AppDelegate.swift \
        SoulverseTests/Tests/Quest/QuestNotificationHourTests.swift
git commit -m "feat(quest): write timezoneOffsetMinutes + notificationHour at app launch"
```

---

## Task 7: Replace `QuestViewModel` with listener-driven shape

**Files:**
- Modify: `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift`
- Create: `SoulverseTests/Tests/Quest/QuestViewModelTests.swift`

The new `QuestViewModel` exposes everything `QuestViewController` needs to render in this plan: counter pill text, dot states for the 21-dot rail, daily CTA visibility, locked-card hints for the 8-Dim card and Custom Habit slot, and Survey-section visibility flag (consumed by Plan 4). The radar-chart and line-chart fields are removed; Plan 5 reintroduces a focused-axis radar field.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestViewModelTests.swift`:

```swift
//
//  QuestViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func model(distinctCheckInDays: Int,
                       didCheckInToday: Bool = false,
                       focusDimension: WellnessDimension? = nil,
                       customHabitExists: Bool = false) -> QuestViewModel {
        var state = QuestStateModel.initial()
        state.distinctCheckInDays = distinctCheckInDays
        state.focusDimension = focusDimension
        return QuestViewModel.from(
            state: state,
            didCheckInToday: didCheckInToday,
            customHabitExists: customHabitExists
        )
    }

    // MARK: - Day-N pill

    func test_QuestViewModel_dayZero_pillReadsDayZeroOfTwentyOne() {
        let vm = model(distinctCheckInDays: 0)
        XCTAssertEqual(vm.dayPillText, "Day 0 of 21")
    }

    func test_QuestViewModel_daySeventeen_pillReadsDaySeventeenOfTwentyOne() {
        let vm = model(distinctCheckInDays: 17)
        XCTAssertEqual(vm.dayPillText, "Day 17 of 21")
    }

    // MARK: - ProgressSection visibility

    func test_QuestViewModel_belowDay21_progressSectionVisible() {
        let vm = model(distinctCheckInDays: 5)
        XCTAssertTrue(vm.progressSectionVisible)
    }

    func test_QuestViewModel_atDay21_progressSectionHidden() {
        let vm = model(distinctCheckInDays: 21)
        XCTAssertFalse(vm.progressSectionVisible)
    }

    func test_QuestViewModel_aboveDay21_progressSectionHidden() {
        let vm = model(distinctCheckInDays: 30)
        XCTAssertFalse(vm.progressSectionVisible)
    }

    // MARK: - Daily CTA

    func test_QuestViewModel_didNotCheckInToday_ctaVisible() {
        let vm = model(distinctCheckInDays: 5, didCheckInToday: false)
        XCTAssertTrue(vm.dailyCheckInCTAVisible)
    }

    func test_QuestViewModel_alreadyCheckedInToday_ctaHidden() {
        let vm = model(distinctCheckInDays: 5, didCheckInToday: true)
        XCTAssertFalse(vm.dailyCheckInCTAVisible)
    }

    func test_QuestViewModel_atDay21_ctaHidden() {
        let vm = model(distinctCheckInDays: 21, didCheckInToday: false)
        XCTAssertFalse(vm.dailyCheckInCTAVisible)
    }

    // MARK: - Survey section visibility (Plan 4 will consume this)

    func test_QuestViewModel_belowDay7_surveySectionHidden() {
        let vm = model(distinctCheckInDays: 6)
        XCTAssertFalse(vm.surveySectionVisible)
    }

    func test_QuestViewModel_atDay7_surveySectionVisible() {
        let vm = model(distinctCheckInDays: 7)
        XCTAssertTrue(vm.surveySectionVisible)
    }

    // MARK: - 8-Dim locked-card hint

    func test_QuestViewModel_day1_eightDimHint_usesFutureDayCopy() {
        let vm = model(distinctCheckInDays: 1)
        XCTAssertEqual(vm.eightDimensionsLockedHint, "On Day 7, you'll see your 8 Dimensions.")
        XCTAssertTrue(vm.eightDimensionsLocked)
    }

    func test_QuestViewModel_day6_eightDimHint_usesSingularCopy() {
        let vm = model(distinctCheckInDays: 6)
        XCTAssertEqual(vm.eightDimensionsLockedHint, "Just 1 more check-in!")
    }

    func test_QuestViewModel_day7_eightDimUnlocked_emptyHint() {
        let vm = model(distinctCheckInDays: 7)
        XCTAssertFalse(vm.eightDimensionsLocked)
        XCTAssertEqual(vm.eightDimensionsLockedHint, "")
    }

    // MARK: - Custom habit slot

    func test_QuestViewModel_day1_customHabitLocked_withFutureDayHint() {
        let vm = model(distinctCheckInDays: 1)
        XCTAssertTrue(vm.customHabitLocked)
        XCTAssertEqual(vm.customHabitLockedHint, "On Day 14, you'll add your own habit.")
    }

    func test_QuestViewModel_day13_customHabitLocked_withSingularHint() {
        let vm = model(distinctCheckInDays: 13)
        XCTAssertTrue(vm.customHabitLocked)
        XCTAssertEqual(vm.customHabitLockedHint, "Just 1 more check-in!")
    }

    func test_QuestViewModel_day14_customHabitUnlocked() {
        let vm = model(distinctCheckInDays: 14)
        XCTAssertFalse(vm.customHabitLocked)
    }

    func test_QuestViewModel_day20_customHabitExists_slotHidden() {
        // §5: button hidden when 1 custom habit exists (slot full).
        let vm = model(distinctCheckInDays: 20, customHabitExists: true)
        XCTAssertFalse(vm.customHabitSlotVisible)
    }

    func test_QuestViewModel_day20_noCustomHabit_slotVisible() {
        let vm = model(distinctCheckInDays: 20, customHabitExists: false)
        XCTAssertTrue(vm.customHabitSlotVisible)
    }

    // MARK: - Stage / dot rail

    func test_QuestViewModel_day3_stageIsStage1_currentDotIs3() {
        let vm = model(distinctCheckInDays: 3)
        XCTAssertEqual(vm.stage, .stage1)
        XCTAssertEqual(vm.currentDot, 3)
    }

    func test_QuestViewModel_day10_stageIsStage2() {
        let vm = model(distinctCheckInDays: 10)
        XCTAssertEqual(vm.stage, .stage2)
        XCTAssertEqual(vm.currentDot, 10)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewModelTests -quiet
```

Expected: build fails — new fields don't exist.

- [ ] **Step 3: Replace the file's contents**

Replace `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift` with:

```swift
//
//  QuestViewModel.swift
//  Soulverse
//
//  Framework-agnostic view model derived from QuestStateModel +
//  client-only signals (didCheckInToday, customHabitExists). All fields are
//  pure functions of inputs; no side effects.
//

import Foundation

struct QuestViewModel {

    // Loading
    var isLoading: Bool

    // Source state (kept around so the controller can reference it without
    // re-passing).
    var state: QuestStateModel

    // Derived: ProgressSection
    var progressSectionVisible: Bool
    var dayPillText: String
    var stage: QuestStage
    var currentDot: Int                // 0..21
    var dailyCheckInCTAVisible: Bool

    // Derived: 8-Dim card lock state
    var eightDimensionsLocked: Bool
    var eightDimensionsLockedHint: String

    // Derived: Custom habit slot
    var customHabitLocked: Bool
    var customHabitLockedHint: String
    var customHabitSlotVisible: Bool

    // Derived: Survey section visibility (consumed by Plan 4)
    var surveySectionVisible: Bool

    // MARK: - Stable unlock thresholds

    static let eightDimensionsUnlockDay = 7
    static let customHabitUnlockDay = 14
    static let questCompleteDay = 21
    static let surveySectionUnlockDay = 7

    // MARK: - Initial / loading

    static func loading() -> QuestViewModel {
        return QuestViewModel.from(
            state: .initial(),
            didCheckInToday: false,
            customHabitExists: false,
            isLoading: true
        )
    }

    // MARK: - Pure factory

    static func from(
        state: QuestStateModel,
        didCheckInToday: Bool,
        customHabitExists: Bool,
        isLoading: Bool = false
    ) -> QuestViewModel {

        let days = state.distinctCheckInDays
        let stage = QuestStage.from(distinctCheckInDays: days)
        let progressVisible = days < questCompleteDay

        let pillFormat = NSLocalizedString(
            "quest_progress_day_pill",
            comment: "Day-N pill text on Quest progress section, e.g. 'Day 5 of 21'"
        )
        let pillText = String(format: pillFormat, days, questCompleteDay)

        let eightDimLocked = days < eightDimensionsUnlockDay
        let eightDimHint = LockedCardHint.copy(
            currentDay: days,
            unlockDay: eightDimensionsUnlockDay,
            featureName: NSLocalizedString(
                "quest_locked_feature_8dim",
                comment: "Verb-phrase: '… see your 8 Dimensions.'"
            )
        )

        let customHabitLocked = days < customHabitUnlockDay
        let customHabitHint = LockedCardHint.copy(
            currentDay: days,
            unlockDay: customHabitUnlockDay,
            featureName: NSLocalizedString(
                "quest_locked_feature_custom_habit",
                comment: "Verb-phrase: '… add your own habit.'"
            )
        )

        // Slot is hidden once a custom habit already exists (spec §5).
        let customHabitSlotVisible = !customHabitExists

        return QuestViewModel(
            isLoading: isLoading,
            state: state,
            progressSectionVisible: progressVisible,
            dayPillText: pillText,
            stage: stage,
            currentDot: min(days, questCompleteDay),
            dailyCheckInCTAVisible: progressVisible && !didCheckInToday,
            eightDimensionsLocked: eightDimLocked,
            eightDimensionsLockedHint: eightDimHint,
            customHabitLocked: customHabitLocked,
            customHabitLockedHint: customHabitHint,
            customHabitSlotVisible: customHabitSlotVisible,
            surveySectionVisible: days >= surveySectionUnlockDay
        )
    }
}
```

- [ ] **Step 4: Add the new localization keys**

Append to `Soulverse/en.lproj/Localizable.strings`:

```
// Quest — progress section
"quest_progress_day_pill" = "Day %d of %d";
"quest_progress_daily_cta" = "Do today's Mood Check-In →";

// Quest — locked-feature labels
"quest_locked_feature_8dim" = "see your 8 Dimensions";
"quest_locked_feature_custom_habit" = "add your own habit";
```

Run:

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewModelTests -quiet
```

Expected: PASS — all 17 cases.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/QuestViewModel.swift \
        Soulverse/en.lproj/Localizable.strings \
        SoulverseTests/Tests/Quest/QuestViewModelTests.swift
git commit -m "feat(quest): listener-driven QuestViewModel with derived locked-card hints"
```

---

## Task 8: Listener-driven `QuestViewPresenter`

**Files:**
- Modify: `Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift`
- Create: `SoulverseTests/Tests/Quest/QuestViewPresenterTests.swift`

The mock-data `loadMockData()` is removed. The presenter accepts a `QuestServiceProtocol` (defaults to `FirestoreQuestService.shared`) and a `MoodCheckInServiceProtocol` (default `FirestoreMoodCheckInService.shared`) so tests can drive both. On `viewWillAppear`-equivalent, the presenter opens the listener; on every emission, it composes a fresh `QuestViewModel` and forwards it to the delegate.

"Did the user check in today?" is computed by querying the most recent mood check-in and bucketing its `createdAt` against the device's current `dayKey` (matching the design spec's §6.2 rule for client UX — we need a yes/no, not a server-authoritative day count).

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestViewPresenterTests.swift`:

```swift
//
//  QuestViewPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestViewPresenterTests: XCTestCase {

    private var capturedViewModels: [QuestViewModel] = []

    override func setUp() {
        super.setUp()
        capturedViewModels = []
    }

    private func makePresenter(
        questService: QuestServiceMock = QuestServiceMock(),
        moodCheckInService: MoodCheckInServiceMock = MoodCheckInServiceMock(),
        userId: String? = "uid-1"
    ) -> (QuestViewPresenter, QuestServiceMock, MoodCheckInServiceMock) {
        let presenter = QuestViewPresenter(
            questService: questService,
            moodCheckInService: moodCheckInService,
            userIdProvider: { userId }
        )
        presenter.delegate = self
        return (presenter, questService, moodCheckInService)
    }

    // MARK: -

    func test_QuestViewPresenter_emitsLoadingStateImmediately() {
        let (presenter, _, _) = makePresenter()
        presenter.start()
        XCTAssertEqual(capturedViewModels.first?.isLoading, true)
    }

    func test_QuestViewPresenter_onSnapshot_emitsDerivedViewModel() {
        let (presenter, questService, _) = makePresenter()
        presenter.start()

        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 5
        questService.emit(state)

        let last = capturedViewModels.last
        XCTAssertEqual(last?.dayPillText, "Day 5 of 21")
        XCTAssertEqual(last?.stage, .stage1)
        XCTAssertTrue(last?.dailyCheckInCTAVisible == true)
        XCTAssertFalse(last?.surveySectionVisible == true)
        XCTAssertTrue(last?.eightDimensionsLocked == true)
    }

    func test_QuestViewPresenter_atDay21_progressSectionHidden() {
        let (presenter, questService, _) = makePresenter()
        presenter.start()

        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 21
        questService.emit(state)

        XCTAssertEqual(capturedViewModels.last?.progressSectionVisible, false)
    }

    func test_QuestViewPresenter_recentCheckInToday_hidesCTA() {
        let mood = MoodCheckInServiceMock()
        mood.stubLatestCheckIn = makeMoodCheckIn(createdAt: Date())
        let (presenter, questService, _) = makePresenter(moodCheckInService: mood)
        presenter.start()

        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 3
        questService.emit(state)

        XCTAssertEqual(capturedViewModels.last?.dailyCheckInCTAVisible, false)
    }

    func test_QuestViewPresenter_recentCheckInYesterday_showsCTA() {
        let mood = MoodCheckInServiceMock()
        let yesterday = Date().addingTimeInterval(-26 * 60 * 60)
        mood.stubLatestCheckIn = makeMoodCheckIn(createdAt: yesterday)
        let (presenter, questService, _) = makePresenter(moodCheckInService: mood)
        presenter.start()

        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 3
        questService.emit(state)

        XCTAssertEqual(capturedViewModels.last?.dailyCheckInCTAVisible, true)
    }

    func test_QuestViewPresenter_noUser_doesNotCrash() {
        let (presenter, _, _) = makePresenter(userId: nil)
        presenter.start()
        // Loading-only emission; no crash.
        XCTAssertEqual(capturedViewModels.count, 1)
    }

    // MARK: -

    private func makeMoodCheckIn(createdAt: Date) -> MoodCheckInModel {
        return MoodCheckInModel(
            colorHex: "#000000",
            colorIntensity: 0.5,
            emotion: "calm",
            topic: "physical",
            evaluation: "neutral",
            journalId: nil,
            drawingId: nil,
            timezoneOffsetMinutes: TimeZone.current.secondsFromGMT() / 60,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }
}

extension QuestViewPresenterTests: QuestViewPresenterDelegate {
    func didUpdate(viewModel: QuestViewModel) { capturedViewModels.append(viewModel) }
    func didUpdateSection(at index: IndexSet) {}
    func didRequestPresentMoodCheckIn() {}
}
```

(`MoodCheckInServiceMock` already exists at `SoulverseTests/Mocks/Shared/Service/MoodCheckInServiceMock.swift`. If it lacks `stubLatestCheckIn`, add a property and have its `fetchLatestCheckIns(uid:limit:completion:)` deliver `[stubLatestCheckIn].compactMap { $0 }`.)

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewPresenterTests -quiet
```

Expected: build fails.

- [ ] **Step 3: Replace the presenter file's contents**

Replace `Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift` with:

```swift
//
//  QuestViewPresenter.swift
//  Soulverse
//

import Foundation

protocol QuestViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: QuestViewModel)
    func didUpdateSection(at index: IndexSet)
    func didRequestPresentMoodCheckIn()
}

protocol QuestViewPresenterType: AnyObject {
    var delegate: QuestViewPresenterDelegate? { get set }
    var loadedModel: QuestViewModel { get }
    func start()
    func stop()
    func didTapDailyCheckInCTA()
    func numberOfSectionsOnTableView() -> Int
}

final class QuestViewPresenter: QuestViewPresenterType {

    weak var delegate: QuestViewPresenterDelegate?
    private(set) var loadedModel: QuestViewModel = QuestViewModel.loading() {
        didSet { delegate?.didUpdate(viewModel: loadedModel) }
    }

    private let questService: QuestServiceProtocol
    private let moodCheckInService: MoodCheckInServiceProtocol
    private let userIdProvider: () -> String?

    private var listenerToken: QuestListenerToken?
    private var lastState: QuestStateModel?
    private var didCheckInToday: Bool = false

    init(
        questService: QuestServiceProtocol = FirestoreQuestService.shared,
        moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
        userIdProvider: @escaping () -> String? = { User.shared.userId }
    ) {
        self.questService = questService
        self.moodCheckInService = moodCheckInService
        self.userIdProvider = userIdProvider
    }

    deinit { stop() }

    // MARK: -

    func start() {
        // Force a loading emission so the controller can clear stale state.
        loadedModel = QuestViewModel.loading()

        guard let uid = userIdProvider() else { return }

        listenerToken = questService.listen(uid: uid) { [weak self] state in
            self?.handle(state: state)
        }

        refreshTodayCheckInFlag(uid: uid)
    }

    func stop() {
        listenerToken?.cancel()
        listenerToken = nil
    }

    // MARK: -

    private func handle(state: QuestStateModel) {
        lastState = state
        recomposeViewModel()
    }

    private func refreshTodayCheckInFlag(uid: String) {
        moodCheckInService.fetchLatestCheckIns(uid: uid, limit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case let .success(items) = result, let latest = items.first?.createdAt {
                    self.didCheckInToday = Self.isSameLocalDay(latest, Date())
                } else {
                    self.didCheckInToday = false
                }
                self.recomposeViewModel()
            }
        }
    }

    private func recomposeViewModel() {
        let state = lastState ?? .initial()
        let isLoading = (lastState == nil)
        loadedModel = QuestViewModel.from(
            state: state,
            didCheckInToday: didCheckInToday,
            customHabitExists: false,    // Plan 3 fills this in
            isLoading: isLoading
        )
    }

    private static func isSameLocalDay(_ a: Date, _ b: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(a, inSameDayAs: b)
    }

    // MARK: - User actions

    func didTapDailyCheckInCTA() {
        delegate?.didRequestPresentMoodCheckIn()
    }

    func numberOfSectionsOnTableView() -> Int {
        // Sections in this plan:
        //   0 — ProgressSection         (hidden when distinctCheckInDays >= 21)
        //   1 — EightDimensionsCard     (host only, locked-state in this plan)
        //   2 — HabitCheckerSection     (host placeholder; Plan 3 fills)
        //   3 — SurveySection           (hidden when distinctCheckInDays < 7)
        return 4
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewPresenterTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift \
        SoulverseTests/Mocks/Shared/Service/MoodCheckInServiceMock.swift \
        SoulverseTests/Tests/Quest/QuestViewPresenterTests.swift
git commit -m "feat(quest): wire QuestViewPresenter to FirestoreQuestService listener"
```

---

## Task 9: `QuestProgressDotsView` — 21-dot rail segmented by stage

**Files:**
- Create: `Soulverse/Features/Quest/Views/ProgressSection/QuestProgressDotsView.swift`

A horizontal stack of 21 dots, with the dots in the *current* stage's `dotRange` enlarged and tinted `.themeProgressBarActive`; dots before that stage are filled-but-small (`.themeProgressBarActive` at 0.6 alpha); dots after are `.themeProgressBarInactive`. The currently-active dot (the one matching `currentDot`) gets a glow ring.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestProgressDotsViewTests.swift`:

```swift
//
//  QuestProgressDotsViewTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestProgressDotsViewTests: XCTestCase {

    func test_QuestProgressDotsView_renders21Dots() {
        let view = QuestProgressDotsView()
        view.configure(currentDot: 5, stage: .stage1)
        XCTAssertEqual(view.dotCount, 21)
    }

    func test_QuestProgressDotsView_currentDotIsHighlighted() {
        let view = QuestProgressDotsView()
        view.configure(currentDot: 5, stage: .stage1)
        XCTAssertEqual(view.highlightedDotIndex, 5)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestProgressDotsViewTests -quiet
```

Expected: build fails.

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Views/ProgressSection/QuestProgressDotsView.swift`:

```swift
//
//  QuestProgressDotsView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class QuestProgressDotsView: UIView {

    private enum Layout {
        static let totalDots: Int = QuestViewModel.questCompleteDay
        static let dotSize: CGFloat = 6
        static let activeDotSize: CGFloat = 10
        static let dotSpacing: CGFloat = 4
        static let stageGap: CGFloat = 8
    }

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.spacing = Layout.dotSpacing
        return s
    }()

    private var dotViews: [UIView] = []

    private(set) var dotCount: Int = 0
    private(set) var highlightedDotIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for i in 1...Layout.totalDots {
            let dot = UIView()
            dot.backgroundColor = .themeProgressBarInactive
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.snp.makeConstraints { make in
                make.size.equalTo(Layout.dotSize)
            }
            stack.addArrangedSubview(dot)
            dotViews.append(dot)

            // Insert a wider gap after each stage boundary (dots 7 and 14).
            if i == 7 || i == 14 {
                let gap = UIView()
                gap.snp.makeConstraints { make in
                    make.width.equalTo(Layout.stageGap)
                }
                stack.addArrangedSubview(gap)
            }
        }
        dotCount = dotViews.count
    }

    func configure(currentDot: Int, stage: QuestStage) {
        highlightedDotIndex = max(0, min(currentDot, Layout.totalDots))
        let stageRange = stage.dotRange

        for (idx, dot) in dotViews.enumerated() {
            let dotNumber = idx + 1
            let inCurrentStage = stageRange.contains(dotNumber)
            let completed = dotNumber <= currentDot

            dot.snp.updateConstraints { make in
                make.size.equalTo(dotNumber == currentDot ? Layout.activeDotSize : Layout.dotSize)
            }
            dot.layer.cornerRadius = (dotNumber == currentDot ? Layout.activeDotSize : Layout.dotSize) / 2

            if dotNumber == currentDot {
                dot.backgroundColor = .themeProgressBarActive
                dot.layer.borderWidth = 2
                dot.layer.borderColor = UIColor.themeProgressBarActive.withAlphaComponent(0.4).cgColor
            } else if completed {
                dot.backgroundColor = .themeProgressBarActive.withAlphaComponent(0.6)
                dot.layer.borderWidth = 0
            } else if inCurrentStage {
                dot.backgroundColor = .themeProgressBarInactive
                dot.layer.borderWidth = 0
            } else {
                dot.backgroundColor = .themeProgressBarInactive.withAlphaComponent(0.5)
                dot.layer.borderWidth = 0
            }
        }
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestProgressDotsViewTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/ProgressSection/QuestProgressDotsView.swift \
        SoulverseTests/Tests/Quest/QuestProgressDotsViewTests.swift
git commit -m "feat(quest): 21-dot progress rail segmented by stage with active highlight"
```

---

## Task 10: `QuestProgressSectionView` — pill + dots + daily CTA

**Files:**
- Create: `Soulverse/Features/Quest/Views/ProgressSection/QuestProgressSectionView.swift`

Composes the day-N pill (a small rounded label), the 21-dot rail, and a Day-1 "Do today's Mood Check-In →" CTA button. Hides the CTA when `dailyCheckInCTAVisible == false`. The whole section hides when `progressSectionVisible == false`.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestProgressSectionViewTests.swift`:

```swift
//
//  QuestProgressSectionViewTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestProgressSectionViewTests: XCTestCase {

    func test_QuestProgressSectionView_setsPillText() {
        let view = QuestProgressSectionView()
        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 5
        let vm = QuestViewModel.from(state: state, didCheckInToday: false, customHabitExists: false)

        view.configure(viewModel: vm)
        XCTAssertEqual(view.pillText, "Day 5 of 21")
    }

    func test_QuestProgressSectionView_hidesCTAWhenAlreadyCheckedIn() {
        let view = QuestProgressSectionView()
        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 5
        let vm = QuestViewModel.from(state: state, didCheckInToday: true, customHabitExists: false)

        view.configure(viewModel: vm)
        XCTAssertTrue(view.isCTAHidden)
    }

    func test_QuestProgressSectionView_invokesCTAHandlerOnTap() {
        let view = QuestProgressSectionView()
        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 1
        let vm = QuestViewModel.from(state: state, didCheckInToday: false, customHabitExists: false)
        view.configure(viewModel: vm)

        var tapped = false
        view.onCTAtap = { tapped = true }
        view.simulateCTATap()
        XCTAssertTrue(tapped)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestProgressSectionViewTests -quiet
```

Expected: build fails.

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Views/ProgressSection/QuestProgressSectionView.swift`:

```swift
//
//  QuestProgressSectionView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class QuestProgressSectionView: UIView {

    private enum Layout {
        static let containerInset: CGFloat = ViewComponentConstants.horizontalPadding
        static let pillHorizontalPadding: CGFloat = 12
        static let pillVerticalPadding: CGFloat = 4
        static let pillToDotsSpacing: CGFloat = 14
        static let dotsToCTASpacing: CGFloat = 16
        static let pillFontSize: CGFloat = 13
        static let ctaFontSize: CGFloat = 15
        static let ctaHeight: CGFloat = ViewComponentConstants.actionButtonHeight
    }

    var onCTAtap: (() -> Void)?

    var pillText: String { return pillLabel.text ?? "" }
    var isCTAHidden: Bool { return ctaButton.isHidden }

    private let pillLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.pillFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        l.backgroundColor = .themeProgressBarInactive
        l.layer.cornerRadius = 12
        l.layer.masksToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let dotsView = QuestProgressDotsView()

    private lazy var ctaButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = UIFont.projectFont(ofSize: Layout.ctaFontSize, weight: .semibold)
        b.setTitleColor(.themeButtonPrimaryText, for: .normal)
        b.backgroundColor = .themeButtonPrimaryBackground
        b.layer.cornerRadius = Layout.ctaHeight / 2
        b.addTarget(self, action: #selector(handleCTATap), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        addSubview(pillLabel)
        addSubview(dotsView)
        addSubview(ctaButton)

        // Build it as a vertical stack so hidden views collapse cleanly.
        let stack = UIStackView(arrangedSubviews: [pillLabel, dotsView, ctaButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.pillToDotsSpacing
        stack.setCustomSpacing(Layout.dotsToCTASpacing, after: dotsView)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.containerInset)
        }

        pillLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(24)
            make.width.greaterThanOrEqualTo(96)
        }

        ctaButton.snp.makeConstraints { make in
            make.height.equalTo(Layout.ctaHeight)
            make.left.right.equalTo(stack)
        }
    }

    func configure(viewModel: QuestViewModel) {
        isHidden = !viewModel.progressSectionVisible

        pillLabel.text = "  \(viewModel.dayPillText)  "
        dotsView.configure(currentDot: viewModel.currentDot, stage: viewModel.stage)

        ctaButton.setTitle(
            NSLocalizedString("quest_progress_daily_cta", comment: "Day-1 CTA"),
            for: .normal
        )
        ctaButton.isHidden = !viewModel.dailyCheckInCTAVisible
    }

    @objc private func handleCTATap() {
        onCTAtap?()
    }

    func simulateCTATap() {
        handleCTATap()
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestProgressSectionViewTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/ProgressSection/QuestProgressSectionView.swift \
        SoulverseTests/Tests/Quest/QuestProgressSectionViewTests.swift
git commit -m "feat(quest): ProgressSection view with day pill, dot rail, and daily CTA"
```

---

## Task 11: `QuestLockedCardView` — dimmed glass card with proximity hint

**Files:**
- Create: `Soulverse/Features/Quest/Views/LockedCard/QuestLockedCardView.swift`

A reusable locked-state placeholder used by both the 8-Dimensions card host (this plan) and the Add-Custom-Habit slot (Plan 3). Renders an SF Symbol lock icon, a title, and the proximity hint text. The whole view uses `applyGlassCardEffect` per spec §10.1.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestLockedCardViewTests.swift`:

```swift
//
//  QuestLockedCardViewTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestLockedCardViewTests: XCTestCase {

    func test_QuestLockedCardView_configure_setsTitleAndHint() {
        let view = QuestLockedCardView()
        view.configure(title: "Your 8 Dimensions", hint: "On Day 7, you'll see your 8 Dimensions.")
        XCTAssertEqual(view.titleText, "Your 8 Dimensions")
        XCTAssertEqual(view.hintText, "On Day 7, you'll see your 8 Dimensions.")
    }

    func test_QuestLockedCardView_emptyHint_collapsesHintLabel() {
        let view = QuestLockedCardView()
        view.configure(title: "Your 8 Dimensions", hint: "")
        XCTAssertTrue(view.isHintHidden)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestLockedCardViewTests -quiet
```

Expected: build fails.

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Views/LockedCard/QuestLockedCardView.swift`:

```swift
//
//  QuestLockedCardView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class QuestLockedCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 18
        static let contentInset: CGFloat = 24
        static let lockIconSize: CGFloat = 28
        static let titleTopSpacing: CGFloat = 12
        static let hintTopSpacing: CGFloat = 4
        static let titleFontSize: CGFloat = 16
        static let hintFontSize: CGFloat = 13
    }

    var titleText: String { return titleLabel.text ?? "" }
    var hintText: String { return hintLabel.text ?? "" }
    var isHintHidden: Bool { return hintLabel.isHidden }

    private let visualEffectView: UIVisualEffectView = {
        let v = UIVisualEffectView(effect: nil)
        return v
    }()

    private let cardContent = UIView()

    private let lockIconView: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "lock.fill"))
        v.tintColor = .themeTextSecondary
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        l.numberOfLines = 1
        l.textAlignment = .center
        return l
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.hintFontSize, weight: .regular)
        l.textColor = .themeTextSecondary
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        cardContent.addSubview(lockIconView)
        cardContent.addSubview(titleLabel)
        cardContent.addSubview(hintLabel)

        ViewComponentConstants.applyGlassCardEffect(
            to: self,
            visualEffectView: visualEffectView,
            contentView: cardContent,
            cornerRadius: Layout.cornerRadius
        )

        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lockIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.contentInset)
            make.centerX.equalToSuperview()
            make.size.equalTo(Layout.lockIconSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(lockIconView.snp.bottom).offset(Layout.titleTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.contentInset)
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.hintTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.contentInset)
            make.bottom.equalToSuperview().inset(Layout.contentInset)
        }
    }

    func configure(title: String, hint: String) {
        titleLabel.text = title
        if hint.isEmpty {
            hintLabel.text = nil
            hintLabel.isHidden = true
        } else {
            hintLabel.text = hint
            hintLabel.isHidden = false
        }
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestLockedCardViewTests -quiet
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/LockedCard/QuestLockedCardView.swift \
        SoulverseTests/Tests/Quest/QuestLockedCardViewTests.swift
git commit -m "feat(quest): reusable QuestLockedCardView with glass card + proximity hint"
```

---

## Task 12: Rebuild `QuestViewController` to render the new sections

**Files:**
- Modify: `Soulverse/Features/Quest/Views/QuestViewController.swift`
- Add localization keys: `Soulverse/en.lproj/Localizable.strings`

The controller now hosts four sections: ProgressSection (top), 8-Dim card host (locked placeholder in this plan), Habit-Checker host (empty placeholder; Plan 3 fills), and Survey-section host (empty placeholder; Plan 4 fills, hidden when `surveySectionVisible == false`). Section visibility flags toggle row heights to 0 when hidden so existing UITableView geometry is unchanged.

- [ ] **Step 1: Write a smoke test**

Append to `SoulverseTests/Tests/Quest/QuestViewControllerSmokeTests.swift`:

```swift
//
//  QuestViewControllerSmokeTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestViewControllerSmokeTests: XCTestCase {

    func test_QuestViewController_loadsView_withoutCrashing() {
        let vc = QuestViewController()
        vc.loadViewIfNeeded()
        XCTAssertNotNil(vc.view)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails or passes by chance**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewControllerSmokeTests -quiet
```

Expected: PASS (the existing skeleton already loads). The change in Step 3 must not break this.

- [ ] **Step 3: Replace the controller's contents**

Replace `Soulverse/Features/Quest/Views/QuestViewController.swift` with:

```swift
//
//  QuestViewController.swift
//

import UIKit
import SnapKit

class QuestViewController: ViewController {

    private enum Section: Int, CaseIterable {
        case progress = 0
        case eightDimensions
        case habitChecker
        case surveys
    }

    private enum Layout {
        static let progressSectionVerticalPadding: CGFloat = 16
        static let cardSidePadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let cardVerticalPadding: CGFloat = 12
        static let lockedCardHeight: CGFloat = 220
        static let zeroHeight: CGFloat = 0.01
    }

    private lazy var navigationView: SoulverseNavigationView = {
        let bellIcon = UIImage(systemName: "bell")
        let personIcon = UIImage(systemName: "person")

        let notificationItem = SoulverseNavigationItem.button(
            image: bellIcon,
            identifier: "notification"
        ) { [weak self] in self?.notificationTapped() }

        let profileItem = SoulverseNavigationItem.button(
            image: personIcon,
            identifier: "profile"
        ) { [weak self] in self?.profileTapped() }

        let config = SoulverseNavigationConfig(
            title: NSLocalizedString("quest", comment: ""),
            showBackButton: false,
            rightItems: [notificationItem, profileItem]
        )
        return SoulverseNavigationView(config: config)
    }()

    private lazy var tableView: UITableView = { [weak self] in
        let table = UITableView(frame: .zero, style: .grouped)
        table.backgroundColor = .clear
        table.backgroundView = nil
        table.separatorStyle = .none
        table.delegate = self
        table.dataSource = self
        table.refreshControl = UIRefreshControl()
        table.refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return table
    }()

    private let presenter = QuestViewPresenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        presenter.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        presenter.start()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.stop()
    }

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.addSubview(navigationView)
        view.addSubview(tableView)
        navigationView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom).offset(Layout.progressSectionVerticalPadding)
            make.left.right.bottom.equalToSuperview()
        }
        self.extendedLayoutIncludesOpaqueBars = true
    }

    @objc private func pullToRefresh() {
        presenter.start()
    }
}

// MARK: - Section rendering

extension QuestViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Layout.zeroHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return Layout.zeroHeight }
        let model = presenter.loadedModel
        switch section {
        case .progress:
            return model.progressSectionVisible ? UITableView.automaticDimension : Layout.zeroHeight
        case .eightDimensions:
            return UITableView.automaticDimension
        case .habitChecker:
            // Plan 3 fills this section.
            return Layout.zeroHeight
        case .surveys:
            // Plan 4 fills this section. Until then, hidden when distinctCheckInDays < 7.
            return model.surveySectionVisible ? UITableView.automaticDimension : Layout.zeroHeight
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.selectionStyle = .none
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        guard let section = Section(rawValue: indexPath.section) else { return cell }
        let model = presenter.loadedModel

        switch section {
        case .progress:
            renderProgressSection(into: cell, model: model)
        case .eightDimensions:
            renderEightDimensionsSection(into: cell, model: model)
        case .habitChecker:
            break  // Plan 3
        case .surveys:
            break  // Plan 4
        }
        return cell
    }

    private func renderProgressSection(into cell: UITableViewCell, model: QuestViewModel) {
        guard model.progressSectionVisible else { return }
        let progressView = QuestProgressSectionView()
        progressView.configure(viewModel: model)
        progressView.onCTAtap = { [weak self] in
            self?.presenter.didTapDailyCheckInCTA()
        }
        cell.contentView.addSubview(progressView)
        progressView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func renderEightDimensionsSection(into cell: UITableViewCell, model: QuestViewModel) {
        let host = UIView()
        cell.contentView.addSubview(host)
        host.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: Layout.cardVerticalPadding,
                             left: Layout.cardSidePadding,
                             bottom: Layout.cardVerticalPadding,
                             right: Layout.cardSidePadding)
            )
            make.height.equalTo(Layout.lockedCardHeight)
        }

        if model.eightDimensionsLocked {
            let locked = QuestLockedCardView()
            locked.configure(
                title: NSLocalizedString("quest_eight_dim_card_title", comment: "8-Dim card title"),
                hint: model.eightDimensionsLockedHint
            )
            host.addSubview(locked)
            locked.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        // When unlocked, Plan 5 will render the radar chart here.
    }
}

// MARK: - Presenter delegate

extension QuestViewController: QuestViewPresenterDelegate {

    func didUpdate(viewModel: QuestViewModel) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if viewModel.isLoading {
                self.showLoadingView(below: self.navigationView)
            } else {
                self.hideLoadingView()
            }
            if self.tableView.refreshControl?.isRefreshing == true {
                self.tableView.refreshControl?.endRefreshing()
            }
            self.tableView.reloadData()
        }
    }

    func didUpdateSection(at index: IndexSet) {
        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadSections(index, with: .automatic)
        }
    }

    func didRequestPresentMoodCheckIn() {
        AppCoordinator.presentMoodCheckIn(from: self)
    }
}

// MARK: - Navigation actions

extension QuestViewController {
    private func notificationTapped() {
        print("[Quest] Notification button tapped")
    }
    private func profileTapped() {
        print("[Quest] Profile button tapped")
    }
}
```

Append to `Soulverse/en.lproj/Localizable.strings`:

```
// Quest — 8-Dim card
"quest_eight_dim_card_title" = "Your 8 Dimensions";
```

- [ ] **Step 4: Run all Quest tests**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewControllerSmokeTests -only-testing:SoulverseTests/QuestViewModelTests -only-testing:SoulverseTests/QuestViewPresenterTests -quiet
```

Expected: all PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestViewController.swift \
        Soulverse/en.lproj/Localizable.strings \
        SoulverseTests/Tests/Quest/QuestViewControllerSmokeTests.swift
git commit -m "feat(quest): rebuild Quest tab with ProgressSection + locked 8-Dim card"
```

---

## Task 13: Refresh today's check-in flag on `MoodCheckInCreated` notification

**Files:**
- Modify: `Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift`

When the user submits a Mood Check-In via the existing flow, an `NSNotification.Name(rawValue: Notification.MoodCheckInCreated)` posts. The Quest screen needs to clear the daily-CTA right away (without waiting for Firestore latency on `distinctCheckInDays`). Listen, re-pull "did the user check in today", and re-compose the view model.

- [ ] **Step 1: Add a test**

Append to `SoulverseTests/Tests/Quest/QuestViewPresenterTests.swift`:

```swift
extension QuestViewPresenterTests {

    func test_QuestViewPresenter_onMoodCheckInCreated_refreshesTodayFlag() {
        let mood = MoodCheckInServiceMock()
        mood.stubLatestCheckIn = nil
        let (presenter, questService, _) = makePresenter(moodCheckInService: mood)
        presenter.start()

        var state = QuestStateModel.initial()
        state.distinctCheckInDays = 3
        questService.emit(state)

        XCTAssertEqual(capturedViewModels.last?.dailyCheckInCTAVisible, true)

        // Simulate a fresh check-in landing.
        mood.stubLatestCheckIn = MoodCheckInModel(
            colorHex: "#000000", colorIntensity: 0.5,
            emotion: "calm", topic: "physical", evaluation: "neutral",
            journalId: nil, drawingId: nil,
            timezoneOffsetMinutes: TimeZone.current.secondsFromGMT() / 60,
            createdAt: Date(), updatedAt: Date()
        )
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: Notification.MoodCheckInCreated),
            object: nil
        )

        let exp = expectation(description: "re-composed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(capturedViewModels.last?.dailyCheckInCTAVisible, false)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewPresenterTests/test_QuestViewPresenter_onMoodCheckInCreated_refreshesTodayFlag -quiet
```

Expected: FAIL — the presenter doesn't observe the notification.

- [ ] **Step 3: Implement**

In `Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift`, modify `start()` and `stop()`:

```swift
    func start() {
        loadedModel = QuestViewModel.loading()
        guard let uid = userIdProvider() else { return }

        listenerToken = questService.listen(uid: uid) { [weak self] state in
            self?.handle(state: state)
        }
        refreshTodayCheckInFlag(uid: uid)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMoodCheckInCreated),
            name: NSNotification.Name(rawValue: Notification.MoodCheckInCreated),
            object: nil
        )
    }

    func stop() {
        listenerToken?.cancel()
        listenerToken = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleMoodCheckInCreated() {
        guard let uid = userIdProvider() else { return }
        refreshTodayCheckInFlag(uid: uid)
    }
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestViewPresenterTests -quiet
```

Expected: PASS — all cases including the new one.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Presenter/QuestViewPresenter.swift \
        SoulverseTests/Tests/Quest/QuestViewPresenterTests.swift
git commit -m "feat(quest): refresh daily-CTA flag on MoodCheckInCreated notification"
```

---

## Task 14: Final integration build verification

**Files:**
- (No new files)

- [ ] **Step 1: Run the full Quest test suite**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' test -only-testing:SoulverseTests/QuestStateModelTests -only-testing:SoulverseTests/QuestStageTests -only-testing:SoulverseTests/LockedCardHintTests -only-testing:SoulverseTests/QuestServiceMockTests -only-testing:SoulverseTests/QuestNotificationHourTests -only-testing:SoulverseTests/QuestViewModelTests -only-testing:SoulverseTests/QuestViewPresenterTests -only-testing:SoulverseTests/QuestProgressDotsViewTests -only-testing:SoulverseTests/QuestProgressSectionViewTests -only-testing:SoulverseTests/QuestLockedCardViewTests -only-testing:SoulverseTests/QuestViewControllerSmokeTests -quiet
```

Expected: every test passes.

- [ ] **Step 2: Build the full app**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

Expected: build succeeds with no warnings introduced by this plan.

- [ ] **Step 3: Manual smoke test (Quest tab)**

1. Run the app in a simulator authenticated as a test user with Plan 1 deployed.
2. Open the Quest tab (index 4).
3. Confirm: Day-N pill shows "Day 0 of 21" for a brand-new user; CTA "Do today's Mood Check-In →" is visible.
4. Tap the CTA — `MoodCheckInCoordinator` presents.
5. Submit a Mood Check-In. Return to Quest tab. CTA hides; Plan 1 increments `distinctCheckInDays`; pill updates within ~1 s.
6. Confirm: 8-Dimensions card host shows the locked placeholder with the correct proximity hint (e.g., "On Day 7, you'll see your 8 Dimensions.").
7. Confirm: Survey section is invisible (`distinctCheckInDays < 7`).
8. Open the app on Day-7-equivalent (server-stamp 7 mood check-ins via emulator); confirm pill reads "Day 7 of 21", 8-Dim card host clears its locked overlay, Survey section becomes visible (Plan 4 fills its body).
9. Background the app; switch device timezone in Settings; foreground the app. Confirm `users/{uid}/quest_state/state.timezoneOffsetMinutes` and `notificationHour` update in Firestore console.

- [ ] **Step 4: Final commit (smoke verification marker)**

```bash
git commit --allow-empty -m "chore(quest): mark Plan 2 complete — Quest tab shell verified end-to-end"
```

---

## Plan summary & next steps

**This plan delivers:**
- `FirestoreQuestService` listening on `users/{uid}/quest_state/state` with timezone-write at app launch.
- `QuestViewModel` deriving Day-N pill, dot rail, daily CTA visibility, locked-card hints, and Survey-section visibility purely from server state.
- `QuestProgressSectionView` (pill + 21 dots + CTA) rendered at the top of the Quest tab; hidden after Day 21 per spec §10.
- `QuestLockedCardView` placeholder for the 8-Dimensions card host with proximity-aware hint copy.
- Survey-section host hidden entirely below Day 7 per spec §5 / Phase 5 revision.
- Unit-test coverage for `QuestStage`, `LockedCardHint`, `QuestNotificationHour`, `QuestViewModel`, and `QuestViewPresenter`.

**Pending iOS work** (covered in Plans 3–7):
- Plan 3: Habit Checker section (3 default habits + custom slot, reuses `QuestLockedCardView` for the locked Add-Custom-Habit slot).
- Plan 4: Survey infrastructure (PendingSurveyDeck + RecentResultCardList; consumes `QuestViewModel.surveySectionVisible`).
- Plan 5: Radar-chart refactor (replaces the locked 8-Dim placeholder once `focusDimension` is non-nil).
- Plan 6: FCM token registration + notification permission UX.
- Plan 7: Polish + final QA.
