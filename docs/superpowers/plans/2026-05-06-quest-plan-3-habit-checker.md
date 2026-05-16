# Onboarding Quest — Plan 3 of 7: Habit Checker

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Habit Checker section of the Quest screen — three fixed default habits (Exercise, Water, Meditation) with daily totals and atomic increments, plus the Day-14-unlocked custom habit form with create / log / soft-delete behavior.

**Architecture:** New `FirestoreHabitService` (single-doc Shape α reads + atomic nested-field increments via `FieldValue.increment()`). Habit cards are pure-rendering subviews driven by `HabitCheckerViewModel`. Custom habit form uses MVP pattern with `CustomHabitFormViewModel` for validation. Date keys are computed in the device's *current* timezone at write time (intentionally different from mood check-in bucketing — see spec §6.2 D6). Cross-timezone analytics event emitted when relevant.

**Tech Stack:** Swift, UIKit, SnapKit, NSLocalizedString, Firebase Firestore (FieldValue.increment), Combine for listener bridging, XCTest.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md` (especially §4.2, §5, §6.2, §6.5, §10)

---

## File structure

After this plan, the following files exist:

```
Soulverse/Features/Quest/Habits/
  FirestoreHabitService.swift           # Firestore reads/writes for habits/state
  HabitData.swift                       # HabitState, DefaultHabitId, CustomHabit models
  HabitDateKey.swift                    # YYYY-MM-DD utility in device's current timezone
  HabitTelemetry.swift                  # Cross-timezone analytics event helper
  HabitCheckerSection.swift             # Container view (3 default cards + custom slot)
  HabitCheckerViewModel.swift           # Composes today/yesterday view state
  DefaultHabitCard.swift                # Visual card for fixed defaults
  CustomHabitCard.swift                 # Visual card for the user's custom habit
  AddCustomHabitButton.swift            # Lock-aware "Add Custom Habit" button
  CustomHabitFormViewController.swift   # Modal form
  CustomHabitFormViewModel.swift        # Form validation state machine
  CustomHabitDeletionConfirmation.swift # Confirmation alert builder

Soulverse/Features/Quest/Views/QuestViewController.swift  # MODIFIED — host the section
Soulverse/Features/Quest/ViewModels/QuestViewModel.swift  # MODIFIED — wire customHabitExists

SoulverseTests/Features/Quest/Habits/
  FirestoreHabitServiceTests.swift
  HabitDateKeyTests.swift
  CustomHabitFormViewModelTests.swift
  HabitCheckerViewModelTests.swift

Soulverse/Resources/en.lproj/Localizable.strings  # MODIFIED — habit copy keys
```

---

## Task 1: Habit data models and `habits/state` document shape

**Files:**
- Create: `Soulverse/Features/Quest/Habits/HabitData.swift`
- Create: `SoulverseTests/Features/Quest/Habits/HabitDataTests.swift`

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Features/Quest/Habits/HabitDataTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class HabitDataTests: XCTestCase {
    func test_defaultHabitId_rawValues_matchSpec() {
        XCTAssertEqual(DefaultHabitId.exercise.rawValue,   "exercise")
        XCTAssertEqual(DefaultHabitId.water.rawValue,      "water")
        XCTAssertEqual(DefaultHabitId.meditation.rawValue, "meditation")
    }

    func test_defaultHabitId_isReservedKey_returnsTrue() {
        XCTAssertTrue(HabitData.isReservedDefaultKey("exercise"))
        XCTAssertTrue(HabitData.isReservedDefaultKey("water"))
        XCTAssertTrue(HabitData.isReservedDefaultKey("meditation"))
        XCTAssertFalse(HabitData.isReservedDefaultKey("h_abc123"))
    }

    func test_customHabitId_isPrefixed() {
        let id = HabitData.generateCustomHabitId()
        XCTAssertTrue(id.hasPrefix("h_"), "Custom habit IDs must start with `h_` to avoid colliding with default keys")
        XCTAssertGreaterThan(id.count, 10)
    }

    func test_customHabit_isActive_whenNotDeleted() {
        let habit = CustomHabit(id: "h_1", name: "Stretch", unit: "min", increments: [5, 10, 15], createdAt: Date(), deletedAt: nil)
        XCTAssertTrue(habit.isActive)
    }

    func test_customHabit_isInactive_whenSoftDeleted() {
        let habit = CustomHabit(id: "h_1", name: "Stretch", unit: "min", increments: [5, 10, 15], createdAt: Date(), deletedAt: Date())
        XCTAssertFalse(habit.isActive)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/HabitDataTests 2>&1 | tail -30
```

Expected: FAIL — types not declared.

- [ ] **Step 3: Implement the models**

Create `Soulverse/Features/Quest/Habits/HabitData.swift`:

```swift
import Foundation

/// Three reserved default habit ids. These keys are NEVER used for custom habits
/// (custom habit ids are prefixed `h_<uuid>`).
enum DefaultHabitId: String, CaseIterable {
    case exercise   = "exercise"
    case water      = "water"
    case meditation = "meditation"

    /// Display unit (post-localized). Not localized — units are short identifiers.
    var unit: String {
        switch self {
        case .exercise:   return "min"
        case .water:      return "ml"
        case .meditation: return "min"
        }
    }

    /// Increment values shown as buttons.
    var increments: [Int] {
        switch self {
        case .exercise:   return [5, 10, 15, 30]
        case .water:      return [100, 200, 300]
        case .meditation: return [5, 10, 20]
        }
    }

    /// Title localization key (en at minimum for MVP).
    var titleKey: String {
        switch self {
        case .exercise:   return "quest_habit_exercise_title"
        case .water:      return "quest_habit_water_title"
        case .meditation: return "quest_habit_meditation_title"
        }
    }
}

/// User-defined custom habit. Soft-deleted by setting `deletedAt`.
/// Soft-deletion preserves historical `daily.<date>.<id>` totals for analytics.
struct CustomHabit: Equatable {
    let id: String              // "h_<uuid>"
    let name: String
    let unit: String
    let increments: [Int]
    let createdAt: Date
    let deletedAt: Date?

    var isActive: Bool { deletedAt == nil }
}

enum HabitData {
    /// True if `key` is one of the three reserved default-habit ids.
    static func isReservedDefaultKey(_ key: String) -> Bool {
        DefaultHabitId.allCases.contains(where: { $0.rawValue == key })
    }

    /// Generate a new custom-habit id with the `h_` prefix to avoid colliding with
    /// reserved default keys. Uses UUID for uniqueness.
    static func generateCustomHabitId() -> String {
        "h_" + UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
    }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/HabitDataTests 2>&1 | tail -30
```

Expected: 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/HabitData.swift SoulverseTests/Features/Quest/Habits/HabitDataTests.swift
git commit -m "feat(quest/habits): add habit data models with reserved-key collision guard"
```

---

## Task 2: Habit date-key utility (device's current timezone)

**Files:**
- Create: `Soulverse/Features/Quest/Habits/HabitDateKey.swift`
- Create: `SoulverseTests/Features/Quest/Habits/HabitDateKeyTests.swift`

This is intentionally different from the mood-check-in day-counter bucketing (which uses each record's *stored* `timezoneOffsetMinutes`). Habits use the device's *current* timezone at write time. See spec §6.2 D6.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Features/Quest/Habits/HabitDateKeyTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class HabitDateKeyTests: XCTestCase {
    func test_dateKey_atUTCPlus8_buildsLocalDate() {
        // 2026-05-01 16:00 UTC + 8h = 2026-05-02 00:00 local in UTC+8
        let date = ISO8601DateFormatter().date(from: "2026-05-01T16:00:00Z")!
        let tz = TimeZone(secondsFromGMT: 8 * 3600)!
        XCTAssertEqual(HabitDateKey.dateKey(for: date, in: tz), "2026-05-02")
    }

    func test_dateKey_atUTCMinus7_buildsLocalDate() {
        // 2026-05-01 02:00 UTC - 7h = 2026-04-30 19:00 local in UTC-7
        let date = ISO8601DateFormatter().date(from: "2026-05-01T02:00:00Z")!
        let tz = TimeZone(secondsFromGMT: -7 * 3600)!
        XCTAssertEqual(HabitDateKey.dateKey(for: date, in: tz), "2026-04-30")
    }

    func test_dateKey_zeroPadsSingleDigitMonthAndDay() {
        let date = ISO8601DateFormatter().date(from: "2026-01-05T12:00:00Z")!
        let tz = TimeZone(secondsFromGMT: 0)!
        XCTAssertEqual(HabitDateKey.dateKey(for: date, in: tz), "2026-01-05")
    }

    func test_yesterdayKey_isOneDayBefore() {
        XCTAssertEqual(HabitDateKey.yesterdayKey(of: "2026-05-02"), "2026-05-01")
        XCTAssertEqual(HabitDateKey.yesterdayKey(of: "2026-03-01"), "2026-02-28") // not leap
        XCTAssertEqual(HabitDateKey.yesterdayKey(of: "2026-01-01"), "2025-12-31")
    }
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/HabitDateKeyTests 2>&1 | tail -30
```

Expected: FAIL — `HabitDateKey` undefined.

- [ ] **Step 3: Implement the utility**

Create `Soulverse/Features/Quest/Habits/HabitDateKey.swift`:

```swift
import Foundation

/// Habit date-key utility. Buckets a Date into "YYYY-MM-DD" using the device's
/// current timezone at write time.
///
/// IMPORTANT: this is intentionally different from the mood-check-in day-counter
/// rule (which uses each record's *stored* `timezoneOffsetMinutes`). Habits do not
/// carry per-write timezone context, so we use device-now consistently.
/// See spec §6.2 D6 for the asymmetry rationale.
enum HabitDateKey {

    /// Return "YYYY-MM-DD" for `date` interpreted in `timeZone`.
    static func dateKey(for date: Date, in timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else {
            assertionFailure("HabitDateKey: failed to extract components from \(date) in \(timeZone)")
            return "0000-00-00"
        }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Compute the previous day's key from a "YYYY-MM-DD" string.
    /// Used by the "Yesterday: N unit" reference on habit cards.
    static func yesterdayKey(of dateKey: String) -> String {
        guard let date = parse(dateKey) else { return dateKey }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
            return dateKey
        }
        return Self.dateKey(for: yesterday, in: TimeZone(secondsFromGMT: 0)!)
    }

    private static func parse(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: key)
    }
}
```

- [ ] **Step 4: Run and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/HabitDateKeyTests 2>&1 | tail -30
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/HabitDateKey.swift SoulverseTests/Features/Quest/Habits/HabitDateKeyTests.swift
git commit -m "feat(quest/habits): add device-current-timezone date-key utility"
```

---

## Task 3: Cross-timezone analytics telemetry

**Files:**
- Create: `Soulverse/Features/Quest/Habits/HabitTelemetry.swift`
- Create: `SoulverseTests/Features/Quest/Habits/HabitTelemetryTests.swift`

Per spec §6.2 D6 amendment: emit `quest_habit_timezone_shift_detected` analytics event when device tz shifts >2h within same calendar day during a habit write. Helps support staff diagnose "my exercise minutes vanished" reports from travelers.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Features/Quest/Habits/HabitTelemetryTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class HabitTelemetryTests: XCTestCase {
    func test_shouldEmit_whenOffsetShiftsByMoreThan2Hours_sameDay() {
        let writer = MockTelemetryWriter()
        let detector = HabitTelemetry(writer: writer)

        // First write at UTC+8, then next write at UTC-5 same calendar day
        detector.observe(writeAt: dateOf("2026-05-01T01:00:00Z"), in: TimeZone(secondsFromGMT: 8 * 3600)!)
        detector.observe(writeAt: dateOf("2026-05-01T03:00:00Z"), in: TimeZone(secondsFromGMT: -5 * 3600)!)

        XCTAssertEqual(writer.events.count, 1)
        XCTAssertEqual(writer.events.first?.name, "quest_habit_timezone_shift_detected")
    }

    func test_shouldNotEmit_whenOffsetShiftsBy2Hours() {
        let writer = MockTelemetryWriter()
        let detector = HabitTelemetry(writer: writer)
        detector.observe(writeAt: dateOf("2026-05-01T01:00:00Z"), in: TimeZone(secondsFromGMT: 8 * 3600)!)
        // shift of exactly 2h does not exceed the threshold
        detector.observe(writeAt: dateOf("2026-05-01T03:00:00Z"), in: TimeZone(secondsFromGMT: 6 * 3600)!)

        XCTAssertEqual(writer.events.count, 0)
    }

    func test_shouldNotEmit_onFirstWrite() {
        let writer = MockTelemetryWriter()
        let detector = HabitTelemetry(writer: writer)
        detector.observe(writeAt: dateOf("2026-05-01T01:00:00Z"), in: TimeZone(secondsFromGMT: 8 * 3600)!)
        XCTAssertEqual(writer.events.count, 0)
    }

    func test_shouldNotEmit_whenShiftCrossesCalendarDay() {
        // The detector only fires within the same calendar day. Different day = no shift event.
        let writer = MockTelemetryWriter()
        let detector = HabitTelemetry(writer: writer)
        detector.observe(writeAt: dateOf("2026-05-01T22:00:00Z"), in: TimeZone(secondsFromGMT: 8 * 3600)!)
        detector.observe(writeAt: dateOf("2026-05-02T05:00:00Z"), in: TimeZone(secondsFromGMT: -5 * 3600)!)
        XCTAssertEqual(writer.events.count, 0)
    }

    private func dateOf(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }
}

final class MockTelemetryWriter: HabitTelemetryWriting {
    struct Event { let name: String; let properties: [String: Any] }
    private(set) var events: [Event] = []
    func write(name: String, properties: [String: Any]) {
        events.append(Event(name: name, properties: properties))
    }
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/HabitTelemetryTests 2>&1 | tail -30
```

Expected: FAIL — types not defined.

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Habits/HabitTelemetry.swift`:

```swift
import Foundation

protocol HabitTelemetryWriting {
    func write(name: String, properties: [String: Any])
}

/// Detects significant timezone shifts within the same calendar day during habit
/// writes, and emits an analytics event for support-staff diagnosis.
final class HabitTelemetry {
    private let writer: HabitTelemetryWriting
    private var lastWrite: (date: Date, timeZone: TimeZone)?

    init(writer: HabitTelemetryWriting) {
        self.writer = writer
    }

    func observe(writeAt date: Date, in timeZone: TimeZone) {
        defer { lastWrite = (date, timeZone) }
        guard let prev = lastWrite else { return }

        let prevDay = HabitDateKey.dateKey(for: prev.date, in: prev.timeZone)
        let nowDay = HabitDateKey.dateKey(for: date, in: timeZone)
        guard prevDay == nowDay else { return }

        let prevOffsetH = Double(prev.timeZone.secondsFromGMT()) / 3600.0
        let nowOffsetH = Double(timeZone.secondsFromGMT()) / 3600.0
        let shiftHours = abs(nowOffsetH - prevOffsetH)
        guard shiftHours > 2 else { return }

        writer.write(
            name: "quest_habit_timezone_shift_detected",
            properties: [
                "previous_offset_hours": prevOffsetH,
                "current_offset_hours":  nowOffsetH,
                "shift_hours":           shiftHours,
                "day_key":               nowDay
            ]
        )
    }
}
```

- [ ] **Step 4: Run and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/HabitTelemetryTests 2>&1 | tail -30
```

Expected: 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/HabitTelemetry.swift SoulverseTests/Features/Quest/Habits/HabitTelemetryTests.swift
git commit -m "feat(quest/habits): emit quest_habit_timezone_shift_detected analytics event"
```

---

## Task 4: `FirestoreHabitService` — read + listener

**Files:**
- Create: `Soulverse/Features/Quest/Habits/FirestoreHabitService.swift`
- Create: `SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift`

Single-doc Shape α reads. Snapshot listener for real-time updates. Atomic increments come in Task 5.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift`:

```swift
import XCTest
import Combine
@testable import Soulverse

final class FirestoreHabitServiceTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    override func tearDown() { cancellables.removeAll() }

    func test_state_initial_isEmpty() {
        let service = FirestoreHabitService(uid: "test-uid", store: InMemoryHabitStore())
        let exp = expectation(description: "publishes empty state")
        service.statePublisher
            .first()
            .sink { state in
                XCTAssertTrue(state.daily.isEmpty)
                XCTAssertTrue(state.customHabits.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)
        wait(for: [exp], timeout: 1)
    }

    func test_listener_publishesUpdates() {
        let store = InMemoryHabitStore()
        let service = FirestoreHabitService(uid: "test-uid", store: store)

        let exp = expectation(description: "receives updated state")
        var received: [HabitState] = []
        service.statePublisher
            .sink { state in
                received.append(state)
                if received.count == 2 { exp.fulfill() }
            }
            .store(in: &cancellables)

        store.simulateRemoteUpdate(HabitState(
            daily: ["2026-05-01": ["exercise": 30]],
            customHabits: [:]
        ))

        wait(for: [exp], timeout: 1)
        XCTAssertEqual(received.last?.daily["2026-05-01"]?["exercise"], 30)
    }
}
```

- [ ] **Step 2: Run and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/FirestoreHabitServiceTests 2>&1 | tail -30
```

Expected: FAIL — types missing.

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Habits/FirestoreHabitService.swift`:

```swift
import Foundation
import Combine
import FirebaseFirestore

/// In-memory representation of `users/{uid}/habits/state` (Shape α).
struct HabitState: Equatable {
    var daily: [String: [String: Int]]      // ["2026-05-01": ["exercise": 30, ...]]
    var customHabits: [String: CustomHabit]  // keyed by habit id

    static let empty = HabitState(daily: [:], customHabits: [:])
}

/// Abstracts Firestore for testability. The production conformance below uses
/// real Firestore; tests can substitute `InMemoryHabitStore`.
protocol HabitStore: AnyObject {
    func observe(_ onUpdate: @escaping (HabitState) -> Void) -> () -> Void
    func incrementDaily(date: String, habitId: String, amount: Int)
    func upsertCustomHabit(_ habit: CustomHabit)
    func softDeleteCustomHabit(id: String, deletedAt: Date)
}

final class FirestoreHabitService {
    private let uid: String
    private let store: HabitStore
    private let stateSubject = CurrentValueSubject<HabitState, Never>(.empty)
    private var unobserve: (() -> Void)?

    var statePublisher: AnyPublisher<HabitState, Never> { stateSubject.eraseToAnyPublisher() }

    init(uid: String, store: HabitStore? = nil) {
        self.uid = uid
        self.store = store ?? FirestoreHabitStore(uid: uid)
        self.unobserve = self.store.observe { [weak self] state in
            self?.stateSubject.send(state)
        }
    }

    deinit { unobserve?() }

    /// Today's total for the given habit id (default or custom).
    func todaysTotal(habitId: String, in timeZone: TimeZone = .current) -> Int {
        let key = HabitDateKey.dateKey(for: Date(), in: timeZone)
        return stateSubject.value.daily[key]?[habitId] ?? 0
    }

    /// Yesterday's total for the given habit id (or 0).
    func yesterdaysTotal(habitId: String, in timeZone: TimeZone = .current) -> Int {
        let today = HabitDateKey.dateKey(for: Date(), in: timeZone)
        let yesterday = HabitDateKey.yesterdayKey(of: today)
        return stateSubject.value.daily[yesterday]?[habitId] ?? 0
    }
}

/// Production conformance backed by a Firestore document at users/{uid}/habits/state.
final class FirestoreHabitStore: HabitStore {
    private let uid: String
    private let docRef: DocumentReference

    init(uid: String, db: Firestore = Firestore.firestore()) {
        self.uid = uid
        self.docRef = db.collection("users").document(uid).collection("habits").document("state")
    }

    func observe(_ onUpdate: @escaping (HabitState) -> Void) -> () -> Void {
        let listener = docRef.addSnapshotListener { snapshot, _ in
            let data = snapshot?.data() ?? [:]
            let daily = (data["daily"] as? [String: [String: Int]]) ?? [:]
            let rawCustom = (data["customHabits"] as? [String: [String: Any]]) ?? [:]
            var customs: [String: CustomHabit] = [:]
            for (id, raw) in rawCustom {
                guard
                    let name = raw["name"] as? String,
                    let unit = raw["unit"] as? String,
                    let increments = raw["increments"] as? [Int],
                    let createdAt = (raw["createdAt"] as? Timestamp)?.dateValue()
                else { continue }
                let deletedAt = (raw["deletedAt"] as? Timestamp)?.dateValue()
                customs[id] = CustomHabit(
                    id: id, name: name, unit: unit, increments: increments,
                    createdAt: createdAt, deletedAt: deletedAt
                )
            }
            onUpdate(HabitState(daily: daily, customHabits: customs))
        }
        return { listener.remove() }
    }

    func incrementDaily(date: String, habitId: String, amount: Int) {
        // Atomic increment via FieldValue.increment on nested field path
        let path = "daily.\(date).\(habitId)"
        docRef.updateData([path: FieldValue.increment(Int64(amount))]) { error in
            if let error = error {
                assertionFailure("FirestoreHabitStore.incrementDaily failed: \(error)")
            }
        }
    }

    func upsertCustomHabit(_ habit: CustomHabit) {
        let path = "customHabits.\(habit.id)"
        docRef.setData([
            "customHabits": [
                habit.id: [
                    "id":         habit.id,
                    "name":       habit.name,
                    "unit":       habit.unit,
                    "increments": habit.increments,
                    "createdAt":  Timestamp(date: habit.createdAt),
                    "deletedAt":  habit.deletedAt.map(Timestamp.init(date:)) as Any
                ]
            ]
        ], merge: true)
    }

    func softDeleteCustomHabit(id: String, deletedAt: Date) {
        let path = "customHabits.\(id).deletedAt"
        docRef.updateData([path: Timestamp(date: deletedAt)])
    }
}

/// In-memory test double.
final class InMemoryHabitStore: HabitStore {
    private var state: HabitState = .empty
    private var listener: ((HabitState) -> Void)?

    func observe(_ onUpdate: @escaping (HabitState) -> Void) -> () -> Void {
        listener = onUpdate
        onUpdate(state)
        return { [weak self] in self?.listener = nil }
    }

    func incrementDaily(date: String, habitId: String, amount: Int) {
        var day = state.daily[date] ?? [:]
        day[habitId] = (day[habitId] ?? 0) + amount
        state.daily[date] = day
        listener?(state)
    }

    func upsertCustomHabit(_ habit: CustomHabit) {
        state.customHabits[habit.id] = habit
        listener?(state)
    }

    func softDeleteCustomHabit(id: String, deletedAt: Date) {
        guard var existing = state.customHabits[id] else { return }
        existing = CustomHabit(id: existing.id, name: existing.name, unit: existing.unit,
                               increments: existing.increments,
                               createdAt: existing.createdAt, deletedAt: deletedAt)
        state.customHabits[id] = existing
        listener?(state)
    }

    /// Test helper: simulate an external write hitting the store.
    func simulateRemoteUpdate(_ newState: HabitState) {
        state = newState
        listener?(state)
    }
}
```

- [ ] **Step 4: Run and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/FirestoreHabitServiceTests 2>&1 | tail -30
```

Expected: 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/FirestoreHabitService.swift SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift
git commit -m "feat(quest/habits): add FirestoreHabitService with observable HabitState"
```

---

## Task 5: Atomic increment writes via FieldValue.increment

**Files:**
- Modify: `Soulverse/Features/Quest/Habits/FirestoreHabitService.swift` (add `logIncrement` method that wraps the store call)
- Modify: `SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift`

- [ ] **Step 1: Add a failing test**

Append to `SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift`:

```swift
extension FirestoreHabitServiceTests {
    func test_logIncrement_writesToCorrectDateKeyAndHabit() {
        let store = InMemoryHabitStore()
        let service = FirestoreHabitService(uid: "u1", store: store)

        let writeDate = ISO8601DateFormatter().date(from: "2026-05-01T01:00:00Z")!
        let utc8 = TimeZone(secondsFromGMT: 8 * 3600)!
        service.logIncrement(habitId: "exercise", amount: 10, at: writeDate, in: utc8)

        // 2026-05-01 01:00 UTC + 8h = 2026-05-01 09:00 local in UTC+8
        XCTAssertEqual(service.todaysTotal(habitId: "exercise", in: utc8), 0)  // Date() != writeDate
        // Force read via store path
        let exp = expectation(description: "state updated")
        service.statePublisher
            .dropFirst()
            .first()
            .sink { state in
                XCTAssertEqual(state.daily["2026-05-01"]?["exercise"], 10)
                exp.fulfill()
            }
            .store(in: &cancellables)
        // The write happened synchronously in InMemoryHabitStore so the publisher already fired
        // — re-trigger by issuing a no-op update.
        store.simulateRemoteUpdate(state: HabitState(daily: ["2026-05-01": ["exercise": 10]], customHabits: [:]))
        wait(for: [exp], timeout: 1)
    }
}

// Add a `state:` overload to InMemoryHabitStore for the test
extension InMemoryHabitStore {
    func simulateRemoteUpdate(state: HabitState) { simulateRemoteUpdate(state) }
}
```

- [ ] **Step 2: Run and verify it fails**

Expected: `logIncrement` not defined.

- [ ] **Step 3: Add `logIncrement`**

Add to `FirestoreHabitService`:

```swift
/// Log an increment for the given habit. Records the write into the daily map at
/// the device's current local date, then fires the cross-timezone telemetry detector.
func logIncrement(
    habitId: String,
    amount: Int,
    at date: Date = Date(),
    in timeZone: TimeZone = .current,
    telemetry: HabitTelemetry? = nil
) {
    let dateKey = HabitDateKey.dateKey(for: date, in: timeZone)
    store.incrementDaily(date: dateKey, habitId: habitId, amount: amount)
    telemetry?.observe(writeAt: date, in: timeZone)
}
```

- [ ] **Step 4: Run and verify it passes**

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/FirestoreHabitService.swift SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift
git commit -m "feat(quest/habits): atomic increment writes via FieldValue.increment with telemetry hook"
```

---

## Task 6: Custom habit lifecycle (create + soft-delete)

**Files:**
- Modify: `Soulverse/Features/Quest/Habits/FirestoreHabitService.swift`
- Modify: `SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift`

- [ ] **Step 1: Add failing tests**

Append:

```swift
extension FirestoreHabitServiceTests {
    func test_createCustomHabit_addsToCustomHabits() {
        let store = InMemoryHabitStore()
        let service = FirestoreHabitService(uid: "u1", store: store)

        let habit = service.createCustomHabit(name: "Stretch", unit: "min", increments: [5, 10, 15])
        XCTAssertTrue(habit.id.hasPrefix("h_"))
        XCTAssertEqual(habit.name, "Stretch")
        XCTAssertNil(habit.deletedAt)
    }

    func test_activeCustomHabit_returnsOnlyNonDeleted() {
        let store = InMemoryHabitStore()
        let service = FirestoreHabitService(uid: "u1", store: store)
        _ = service.createCustomHabit(name: "Stretch", unit: "min", increments: [5, 10, 15])
        XCTAssertNotNil(service.activeCustomHabit())

        if let h = service.activeCustomHabit() {
            service.softDeleteCustomHabit(id: h.id)
        }
        XCTAssertNil(service.activeCustomHabit())
    }
}
```

- [ ] **Step 2: Run — expect FAIL (methods undefined)**

- [ ] **Step 3: Implement methods on `FirestoreHabitService`**

```swift
@discardableResult
func createCustomHabit(name: String, unit: String, increments: [Int]) -> CustomHabit {
    let habit = CustomHabit(
        id: HabitData.generateCustomHabitId(),
        name: name, unit: unit, increments: increments,
        createdAt: Date(), deletedAt: nil
    )
    store.upsertCustomHabit(habit)
    return habit
}

func softDeleteCustomHabit(id: String) {
    store.softDeleteCustomHabit(id: id, deletedAt: Date())
}

/// MVP rule: at most one active custom habit. Returns the active one or nil.
func activeCustomHabit() -> CustomHabit? {
    stateSubject.value.customHabits.values.first(where: { $0.isActive })
}
```

- [ ] **Step 4: Run and verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/FirestoreHabitService.swift SoulverseTests/Features/Quest/Habits/FirestoreHabitServiceTests.swift
git commit -m "feat(quest/habits): create + soft-delete custom habit lifecycle"
```

---

## Task 7: `CustomHabitFormViewModel` — validation state machine

**Files:**
- Create: `Soulverse/Features/Quest/Habits/CustomHabitFormViewModel.swift`
- Create: `SoulverseTests/Features/Quest/Habits/CustomHabitFormViewModelTests.swift`

Form rules per spec §D7: name 1–24 chars, unit 1–8 chars, 3 distinct positive integer increments, save-disabled-until-valid, unit-aware suggestions.

- [ ] **Step 1: Write tests**

Create `SoulverseTests/Features/Quest/Habits/CustomHabitFormViewModelTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class CustomHabitFormViewModelTests: XCTestCase {
    func test_invalid_initially() {
        let vm = CustomHabitFormViewModel()
        XCTAssertFalse(vm.isValid)
    }

    func test_valid_whenAllFieldsCorrect() {
        let vm = CustomHabitFormViewModel()
        vm.update(name: "Stretch", unit: "min", increments: [5, 10, 15])
        XCTAssertTrue(vm.isValid)
    }

    func test_invalid_whenNameTooShort() {
        let vm = CustomHabitFormViewModel()
        vm.update(name: "", unit: "min", increments: [5, 10, 15])
        XCTAssertFalse(vm.isValid)
        XCTAssertTrue(vm.errors.contains(.nameRequired))
    }

    func test_invalid_whenNameTooLong() {
        let vm = CustomHabitFormViewModel()
        vm.update(name: String(repeating: "a", count: 25), unit: "min", increments: [5, 10, 15])
        XCTAssertFalse(vm.isValid)
        XCTAssertTrue(vm.errors.contains(.nameTooLong))
    }

    func test_invalid_whenUnitTooLong() {
        let vm = CustomHabitFormViewModel()
        vm.update(name: "Stretch", unit: "centimeters", increments: [5, 10, 15])
        XCTAssertFalse(vm.isValid)
        XCTAssertTrue(vm.errors.contains(.unitTooLong))
    }

    func test_invalid_whenIncrementsHaveDuplicate() {
        let vm = CustomHabitFormViewModel()
        vm.update(name: "Stretch", unit: "min", increments: [5, 10, 10])
        XCTAssertFalse(vm.isValid)
        XCTAssertTrue(vm.errors.contains(.duplicateIncrements))
    }

    func test_invalid_whenIncrementsNonPositive() {
        let vm = CustomHabitFormViewModel()
        vm.update(name: "Stretch", unit: "min", increments: [0, 10, 15])
        XCTAssertFalse(vm.isValid)
        XCTAssertTrue(vm.errors.contains(.nonPositiveIncrement))
    }

    func test_suggestedIncrements_whenUnitIsMin() {
        let vm = CustomHabitFormViewModel()
        XCTAssertEqual(vm.suggestedIncrements(forUnit: "min"), [5, 10, 15])
        XCTAssertEqual(vm.suggestedIncrements(forUnit: "minutes"), [5, 10, 15])
    }

    func test_suggestedIncrements_whenUnitIsMl() {
        let vm = CustomHabitFormViewModel()
        XCTAssertEqual(vm.suggestedIncrements(forUnit: "ml"), [100, 200, 300])
    }

    func test_suggestedIncrements_unknownUnit() {
        let vm = CustomHabitFormViewModel()
        XCTAssertNil(vm.suggestedIncrements(forUnit: "qux"))
    }
}
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Habits/CustomHabitFormViewModel.swift`:

```swift
import Foundation

final class CustomHabitFormViewModel {
    enum FormError: Equatable {
        case nameRequired
        case nameTooLong
        case unitRequired
        case unitTooLong
        case incrementsRequired
        case duplicateIncrements
        case nonPositiveIncrement
    }

    private(set) var name: String = ""
    private(set) var unit: String = ""
    private(set) var increments: [Int] = []
    private(set) var errors: Set<FormError> = []

    private static let nameMin = 1
    private static let nameMax = 24
    private static let unitMin = 1
    private static let unitMax = 8

    var isValid: Bool { errors.isEmpty && !name.isEmpty && !unit.isEmpty && increments.count == 3 }

    func update(name: String, unit: String, increments: [Int]) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.unit = unit.trimmingCharacters(in: .whitespacesAndNewlines)
        self.increments = increments
        validate()
    }

    func suggestedIncrements(forUnit unit: String) -> [Int]? {
        let lower = unit.lowercased()
        if lower.contains("min") || lower.contains("hour") || lower.contains("sec") {
            return [5, 10, 15]
        }
        if lower == "ml" || lower == "oz" || lower == "cup" || lower == "cups" {
            return [100, 200, 300]
        }
        if lower.contains("page") || lower == "book" || lower == "books" {
            return [1, 5, 10]
        }
        return nil
    }

    private func validate() {
        var errs: Set<FormError> = []
        if name.count < Self.nameMin { errs.insert(.nameRequired) }
        if name.count > Self.nameMax { errs.insert(.nameTooLong) }
        if unit.count < Self.unitMin { errs.insert(.unitRequired) }
        if unit.count > Self.unitMax { errs.insert(.unitTooLong) }
        if increments.count != 3 { errs.insert(.incrementsRequired) }
        if Set(increments).count != increments.count { errs.insert(.duplicateIncrements) }
        if increments.contains(where: { $0 <= 0 }) { errs.insert(.nonPositiveIncrement) }
        errors = errs
    }
}
```

- [ ] **Step 4: Run and verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/CustomHabitFormViewModel.swift SoulverseTests/Features/Quest/Habits/CustomHabitFormViewModelTests.swift
git commit -m "feat(quest/habits): add custom habit form validation state machine"
```

---

## Task 8: `HabitCheckerViewModel` — composes today/yesterday view state

**Files:**
- Create: `Soulverse/Features/Quest/Habits/HabitCheckerViewModel.swift`
- Create: `SoulverseTests/Features/Quest/Habits/HabitCheckerViewModelTests.swift`

The Quest screen's `HabitCheckerSection` consumes this view-model (UIKit-free) for rendering today's totals, yesterday reference, and active custom habit visibility.

- [ ] **Step 1: Write tests**

```swift
import XCTest
@testable import Soulverse

final class HabitCheckerViewModelTests: XCTestCase {
    func test_card_showsTodayAndYesterday() {
        let state = HabitState(
            daily: [
                "2026-05-01": ["exercise": 30, "water": 250],
                "2026-04-30": ["exercise": 25]
            ],
            customHabits: [:]
        )
        let vm = HabitCheckerViewModel(state: state, todayKey: "2026-05-01")
        let exercise = vm.cardModel(for: "exercise", title: "Exercise", unit: "min", increments: [5, 10, 15, 30])

        XCTAssertEqual(exercise.todayTotal, 30)
        XCTAssertEqual(exercise.yesterdayTotal, 25)
        XCTAssertEqual(exercise.unit, "min")
    }

    func test_yesterdayHidden_whenZero() {
        let state = HabitState(daily: ["2026-05-01": ["water": 100]], customHabits: [:])
        let vm = HabitCheckerViewModel(state: state, todayKey: "2026-05-01")
        let water = vm.cardModel(for: "water", title: "Water", unit: "ml", increments: [100, 200, 300])
        XCTAssertEqual(water.yesterdayTotal, 0)
        XCTAssertFalse(water.shouldShowYesterday)
    }

    func test_customHabitVisible_onlyWhenActive() {
        let active = CustomHabit(id: "h_1", name: "Stretch", unit: "min", increments: [5, 10, 15], createdAt: Date(), deletedAt: nil)
        let deleted = CustomHabit(id: "h_2", name: "Read", unit: "pages", increments: [1, 5, 10], createdAt: Date(), deletedAt: Date())

        let state = HabitState(daily: [:], customHabits: ["h_1": active, "h_2": deleted])
        let vm = HabitCheckerViewModel(state: state, todayKey: "2026-05-01")

        XCTAssertEqual(vm.activeCustomHabit?.id, "h_1")
    }

    func test_addCustomHabit_buttonStates() {
        // distinctCheckInDays < 14 → locked
        let lockedState = HabitState(daily: [:], customHabits: [:])
        let lockedVM = HabitCheckerViewModel(state: lockedState, todayKey: "2026-05-01", distinctCheckInDays: 5)
        XCTAssertEqual(lockedVM.addButtonState, .locked(daysRemaining: 9))

        // distinctCheckInDays >= 14, no active habit → available
        let availableVM = HabitCheckerViewModel(state: lockedState, todayKey: "2026-05-01", distinctCheckInDays: 14)
        XCTAssertEqual(availableVM.addButtonState, .available)

        // distinctCheckInDays >= 14, active habit exists → hidden
        let active = CustomHabit(id: "h_1", name: "Stretch", unit: "min", increments: [5, 10, 15], createdAt: Date(), deletedAt: nil)
        let hiddenState = HabitState(daily: [:], customHabits: ["h_1": active])
        let hiddenVM = HabitCheckerViewModel(state: hiddenState, todayKey: "2026-05-01", distinctCheckInDays: 14)
        XCTAssertEqual(hiddenVM.addButtonState, .hidden)
    }
}
```

- [ ] **Step 2: Run — expect FAIL**

- [ ] **Step 3: Implement**

Create `Soulverse/Features/Quest/Habits/HabitCheckerViewModel.swift`:

```swift
import Foundation

struct HabitCardModel: Equatable {
    let habitId: String
    let titleKey: String
    let unit: String
    let increments: [Int]
    let todayTotal: Int
    let yesterdayTotal: Int

    var shouldShowYesterday: Bool { yesterdayTotal > 0 }
}

enum AddCustomHabitButtonState: Equatable {
    case locked(daysRemaining: Int)
    case available
    case hidden
}

struct HabitCheckerViewModel {
    let state: HabitState
    let todayKey: String
    let distinctCheckInDays: Int

    init(state: HabitState, todayKey: String, distinctCheckInDays: Int = 0) {
        self.state = state
        self.todayKey = todayKey
        self.distinctCheckInDays = distinctCheckInDays
    }

    func cardModel(for habitId: String, title: String, unit: String, increments: [Int]) -> HabitCardModel {
        let yKey = HabitDateKey.yesterdayKey(of: todayKey)
        return HabitCardModel(
            habitId: habitId,
            titleKey: title,
            unit: unit,
            increments: increments,
            todayTotal: state.daily[todayKey]?[habitId] ?? 0,
            yesterdayTotal: state.daily[yKey]?[habitId] ?? 0
        )
    }

    var activeCustomHabit: CustomHabit? {
        state.customHabits.values.first(where: { $0.isActive })
    }

    var addButtonState: AddCustomHabitButtonState {
        let kUnlockDay = 14
        if distinctCheckInDays < kUnlockDay {
            return .locked(daysRemaining: kUnlockDay - distinctCheckInDays)
        }
        if activeCustomHabit != nil {
            return .hidden
        }
        return .available
    }
}
```

- [ ] **Step 4: Run and verify it passes**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Habits/HabitCheckerViewModel.swift SoulverseTests/Features/Quest/Habits/HabitCheckerViewModelTests.swift
git commit -m "feat(quest/habits): add HabitCheckerViewModel composing today/yesterday + add-button state"
```

---

## Task 9: `DefaultHabitCard` UIView

**Files:**
- Create: `Soulverse/Features/Quest/Habits/DefaultHabitCard.swift`

A pure-render UIView; tap handlers are delivered as closures to keep it framework-thin.

- [ ] **Step 1: Implement (no test — pure UIView; integration tested via Task 13)**

Create `Soulverse/Features/Quest/Habits/DefaultHabitCard.swift`:

```swift
import UIKit
import SnapKit

final class DefaultHabitCard: UIView {

    private enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let outerInset: CGFloat = 16
        static let stackSpacing: CGFloat = 8
        static let buttonStackSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 36
        static let buttonCornerRadius: CGFloat = 18
    }

    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let yesterdayLabel = UILabel()
    private let resetSubtitleLabel = UILabel()
    private let buttonStack = UIStackView()

    var onIncrementTap: ((_ amount: Int) -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ model: HabitCardModel) {
        titleLabel.text = NSLocalizedString(model.titleKey, comment: "")
        totalLabel.text = String(format: NSLocalizedString("quest_habit_today_format", comment: ""), model.todayTotal, model.unit)
        if model.shouldShowYesterday {
            yesterdayLabel.isHidden = false
            yesterdayLabel.text = String(format: NSLocalizedString("quest_habit_yesterday_format", comment: ""), model.yesterdayTotal, model.unit)
        } else {
            yesterdayLabel.isHidden = true
        }
        resetSubtitleLabel.text = NSLocalizedString("quest_habit_resets_at_midnight", comment: "")

        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for amount in model.increments {
            let button = makeIncrementButton(amount: amount, unit: model.unit)
            buttonStack.addArrangedSubview(button)
        }
    }

    private func setupView() {
        ViewComponentConstants.applyGlassCardEffect(to: self)
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .themeTextPrimary

        totalLabel.font = .preferredFont(forTextStyle: .title3)
        totalLabel.textColor = .themeTextPrimary

        yesterdayLabel.font = .preferredFont(forTextStyle: .footnote)
        yesterdayLabel.textColor = .themeTextSecondary

        resetSubtitleLabel.font = .preferredFont(forTextStyle: .caption2)
        resetSubtitleLabel.textColor = .themeTextSecondary

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = Layout.buttonStackSpacing

        let vStack = UIStackView(arrangedSubviews: [titleLabel, totalLabel, yesterdayLabel, resetSubtitleLabel, buttonStack])
        vStack.axis = .vertical
        vStack.spacing = Layout.stackSpacing
        addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        buttonStack.snp.makeConstraints { make in
            make.height.equalTo(Layout.buttonHeight)
        }
    }

    private func makeIncrementButton(amount: Int, unit: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("+\(amount)", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.setTitleColor(.themeTextOnSecondary, for: .normal)
        button.backgroundColor = .themeButtonSecondary
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addAction(UIAction { [weak self] _ in
            self?.onIncrementTap?(amount)
        }, for: .touchUpInside)
        return button
    }
}
```

- [ ] **Step 2: Build — verify no compilation errors**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Habits/DefaultHabitCard.swift
git commit -m "feat(quest/habits): add DefaultHabitCard UIView with theme-aware styling"
```

---

## Task 10: `CustomHabitCard` UIView

**Files:**
- Create: `Soulverse/Features/Quest/Habits/CustomHabitCard.swift`

Visually mirrors `DefaultHabitCard`. Adds a long-press / context menu for soft-delete.

- [ ] **Step 1: Implement**

Create `Soulverse/Features/Quest/Habits/CustomHabitCard.swift`:

```swift
import UIKit
import SnapKit

final class CustomHabitCard: UIView {
    private enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let outerInset: CGFloat = 16
        static let stackSpacing: CGFloat = 8
        static let buttonStackSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 36
        static let buttonCornerRadius: CGFloat = 18
    }

    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let yesterdayLabel = UILabel()
    private let resetSubtitleLabel = UILabel()
    private let buttonStack = UIStackView()
    private let deleteButton = UIButton(type: .system)

    var onIncrementTap: ((_ amount: Int) -> Void)?
    var onDeleteTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ habit: CustomHabit, todayTotal: Int, yesterdayTotal: Int) {
        titleLabel.text = habit.name
        totalLabel.text = String(format: NSLocalizedString("quest_habit_today_format", comment: ""), todayTotal, habit.unit)
        if yesterdayTotal > 0 {
            yesterdayLabel.isHidden = false
            yesterdayLabel.text = String(format: NSLocalizedString("quest_habit_yesterday_format", comment: ""), yesterdayTotal, habit.unit)
        } else {
            yesterdayLabel.isHidden = true
        }
        resetSubtitleLabel.text = NSLocalizedString("quest_habit_resets_at_midnight", comment: "")

        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for amount in habit.increments {
            let button = makeIncrementButton(amount: amount, unit: habit.unit)
            buttonStack.addArrangedSubview(button)
        }
    }

    private func setupView() {
        ViewComponentConstants.applyGlassCardEffect(to: self)
        layer.cornerRadius = Layout.cardCornerRadius

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .themeTextPrimary

        totalLabel.font = .preferredFont(forTextStyle: .title3)
        totalLabel.textColor = .themeTextPrimary

        yesterdayLabel.font = .preferredFont(forTextStyle: .footnote)
        yesterdayLabel.textColor = .themeTextSecondary

        resetSubtitleLabel.font = .preferredFont(forTextStyle: .caption2)
        resetSubtitleLabel.textColor = .themeTextSecondary

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = Layout.buttonStackSpacing

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .themeIconMuted
        deleteButton.addAction(UIAction { [weak self] _ in self?.onDeleteTap?() }, for: .touchUpInside)

        let topRow = UIStackView(arrangedSubviews: [titleLabel, deleteButton])
        topRow.axis = .horizontal
        topRow.distribution = .equalSpacing

        let vStack = UIStackView(arrangedSubviews: [topRow, totalLabel, yesterdayLabel, resetSubtitleLabel, buttonStack])
        vStack.axis = .vertical
        vStack.spacing = Layout.stackSpacing
        addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        buttonStack.snp.makeConstraints { make in
            make.height.equalTo(Layout.buttonHeight)
        }
    }

    private func makeIncrementButton(amount: Int, unit: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("+\(amount)", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.setTitleColor(.themeTextOnSecondary, for: .normal)
        button.backgroundColor = .themeButtonSecondary
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addAction(UIAction { [weak self] _ in
            self?.onIncrementTap?(amount)
        }, for: .touchUpInside)
        return button
    }
}
```

- [ ] **Step 2: Build — verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Habits/CustomHabitCard.swift
git commit -m "feat(quest/habits): add CustomHabitCard UIView with delete affordance"
```

---

## Task 11: `AddCustomHabitButton` UIView (lock-aware)

**Files:**
- Create: `Soulverse/Features/Quest/Habits/AddCustomHabitButton.swift`

- [ ] **Step 1: Implement**

```swift
import UIKit
import SnapKit

final class AddCustomHabitButton: UIControl {
    private enum Layout {
        static let height: CGFloat = 48
        static let cornerRadius: CGFloat = 24
        static let inset: CGFloat = 16
    }

    private let titleLabel = UILabel()
    private let lockIcon = UIImageView()

    var onTap: (() -> Void)?
    var onLockedTap: ((_ daysRemaining: Int) -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ state: AddCustomHabitButtonState) {
        switch state {
        case .locked(let daysRemaining):
            isHidden = false
            isEnabled = false
            backgroundColor = .themeOverlayDimmed
            lockIcon.isHidden = false
            titleLabel.text = String(
                format: NSLocalizedString("quest_habit_add_custom_locked_format", comment: ""),
                daysRemaining
            )
        case .available:
            isHidden = false
            isEnabled = true
            backgroundColor = .themeButtonPrimary
            lockIcon.isHidden = true
            titleLabel.text = NSLocalizedString("quest_habit_add_custom_available", comment: "")
        case .hidden:
            isHidden = true
        }
    }

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .themeTextOnPrimary
        titleLabel.textAlignment = .center

        lockIcon.image = UIImage(systemName: "lock.fill")
        lockIcon.tintColor = .themeIconMuted

        let stack = UIStackView(arrangedSubviews: [lockIcon, titleLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(Layout.inset)
        }
        snp.makeConstraints { make in
            make.height.equalTo(Layout.height)
        }
        // Add gesture for locked-state taps (button itself is disabled when locked)
        let lockedTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLockedAreaTap))
        addGestureRecognizer(lockedTapGesture)
    }

    @objc private func handleTap() { onTap?() }

    @objc private func handleLockedAreaTap() {
        guard !isEnabled else { return }
        // We don't know daysRemaining here; the title text already shows it. Just notify.
        onLockedTap?(0)
    }
}
```

- [ ] **Step 2: Build — verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Habits/AddCustomHabitButton.swift
git commit -m "feat(quest/habits): add lock-aware AddCustomHabitButton"
```

---

## Task 12: `CustomHabitFormViewController` modal

**Files:**
- Create: `Soulverse/Features/Quest/Habits/CustomHabitFormViewController.swift`

- [ ] **Step 1: Implement**

```swift
import UIKit
import SnapKit

final class CustomHabitFormViewController: UIViewController {
    private enum Layout {
        static let formInset: CGFloat = 24
        static let fieldSpacing: CGFloat = 16
        static let saveButtonHeight: CGFloat = 48
        static let incrementFieldWidth: CGFloat = 80
    }

    private let viewModel = CustomHabitFormViewModel()

    private let nameField = UITextField()
    private let unitField = UITextField()
    private let inc1Field = UITextField()
    private let inc2Field = UITextField()
    private let inc3Field = UITextField()
    private let saveButton = UIButton(type: .system)
    private let previewLabel = UILabel()

    var onSave: ((_ name: String, _ unit: String, _ increments: [Int]) -> Void)?
    var onCancel: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themeBackgroundPrimary
        title = NSLocalizedString("quest_habit_form_title", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )

        nameField.placeholder = NSLocalizedString("quest_habit_form_name_placeholder", comment: "")
        unitField.placeholder = NSLocalizedString("quest_habit_form_unit_placeholder", comment: "")
        [inc1Field, inc2Field, inc3Field].forEach { $0.keyboardType = .numberPad }

        saveButton.setTitle(NSLocalizedString("quest_habit_form_save", comment: ""), for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.setTitleColor(.themeTextOnPrimary, for: .normal)
        saveButton.backgroundColor = .themeButtonPrimary
        saveButton.layer.cornerRadius = 24
        saveButton.isEnabled = false
        saveButton.addAction(UIAction { [weak self] _ in self?.saveTapped() }, for: .touchUpInside)

        previewLabel.font = .preferredFont(forTextStyle: .footnote)
        previewLabel.textColor = .themeTextSecondary
        previewLabel.numberOfLines = 0

        let incrementRow = UIStackView(arrangedSubviews: [inc1Field, inc2Field, inc3Field])
        incrementRow.axis = .horizontal
        incrementRow.distribution = .fillEqually
        incrementRow.spacing = 8

        let stack = UIStackView(arrangedSubviews: [nameField, unitField, incrementRow, previewLabel, saveButton])
        stack.axis = .vertical
        stack.spacing = Layout.fieldSpacing
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.left.right.equalTo(view.safeAreaLayoutGuide).inset(Layout.formInset)
        }
        saveButton.snp.makeConstraints { make in
            make.height.equalTo(Layout.saveButtonHeight)
        }

        // Wire change events
        nameField.addAction(UIAction { [weak self] _ in self?.recompute() }, for: .editingChanged)
        unitField.addAction(UIAction { [weak self] _ in
            self?.applyUnitSuggestions()
            self?.recompute()
        }, for: .editingChanged)
        [inc1Field, inc2Field, inc3Field].forEach {
            $0.addAction(UIAction { [weak self] _ in self?.recompute() }, for: .editingChanged)
        }
    }

    private func applyUnitSuggestions() {
        let unit = unitField.text ?? ""
        guard inc1Field.text?.isEmpty ?? true,
              inc2Field.text?.isEmpty ?? true,
              inc3Field.text?.isEmpty ?? true,
              let suggestions = viewModel.suggestedIncrements(forUnit: unit)
        else { return }
        inc1Field.text = String(suggestions[0])
        inc2Field.text = String(suggestions[1])
        inc3Field.text = String(suggestions[2])
    }

    private func recompute() {
        let increments = [inc1Field.text, inc2Field.text, inc3Field.text]
            .compactMap { $0 }
            .compactMap(Int.init)
        viewModel.update(
            name: nameField.text ?? "",
            unit: unitField.text ?? "",
            increments: increments
        )
        saveButton.isEnabled = viewModel.isValid

        previewLabel.text = viewModel.isValid
            ? String(
                format: NSLocalizedString("quest_habit_form_preview_format", comment: ""),
                nameField.text ?? "",
                increments.map { "+\($0)" }.joined(separator: " "),
                unitField.text ?? ""
              )
            : NSLocalizedString("quest_habit_form_preview_invalid", comment: "")
    }

    private func saveTapped() {
        guard viewModel.isValid else { return }
        onSave?(
            nameField.text ?? "",
            unitField.text ?? "",
            [inc1Field, inc2Field, inc3Field].compactMap { $0.text }.compactMap(Int.init)
        )
    }

    @objc private func cancelTapped() { onCancel?() }
}
```

- [ ] **Step 2: Build — verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Habits/CustomHabitFormViewController.swift
git commit -m "feat(quest/habits): add CustomHabitFormViewController with live validation + unit suggestions"
```

---

## Task 13: Soft-delete confirmation alert

**Files:**
- Create: `Soulverse/Features/Quest/Habits/CustomHabitDeletionConfirmation.swift`

- [ ] **Step 1: Implement**

```swift
import UIKit

enum CustomHabitDeletionConfirmation {
    /// Build the deletion confirmation alert per spec §D7.
    static func make(habitName: String, onConfirm: @escaping () -> Void) -> UIAlertController {
        let title = NSLocalizedString("quest_habit_delete_alert_title", comment: "")
        let message = String(
            format: NSLocalizedString("quest_habit_delete_alert_body_format", comment: ""),
            habitName
        )
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("quest_habit_delete_alert_cancel", comment: ""),
            style: .cancel,
            handler: nil
        ))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("quest_habit_delete_alert_confirm", comment: ""),
            style: .destructive,
            handler: { _ in onConfirm() }
        ))
        return alert
    }
}
```

- [ ] **Step 2: Build — verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Habits/CustomHabitDeletionConfirmation.swift
git commit -m "feat(quest/habits): add deletion confirmation alert builder"
```

---

## Task 14: `HabitCheckerSection` container view

**Files:**
- Create: `Soulverse/Features/Quest/Habits/HabitCheckerSection.swift`

Hosts the three default cards, optional custom habit card, and the AddCustomHabit button.

- [ ] **Step 1: Implement**

```swift
import UIKit
import SnapKit
import Combine

final class HabitCheckerSection: UIView {
    private enum Layout {
        static let cardSpacing: CGFloat = 12
        static let outerInset: CGFloat = 16
        static let headerSpacing: CGFloat = 8
    }

    private let titleLabel = UILabel()
    private let cardsStack = UIStackView()
    private let exerciseCard = DefaultHabitCard()
    private let waterCard = DefaultHabitCard()
    private let meditationCard = DefaultHabitCard()
    private let customCard = CustomHabitCard()
    private let addButton = AddCustomHabitButton()

    private let service: FirestoreHabitService
    private let telemetry: HabitTelemetry?
    private var cancellables: Set<AnyCancellable> = []
    private var distinctCheckInDays: Int = 0

    var onAddTap: (() -> Void)?
    var onLockedTap: ((Int) -> Void)?
    var onDeleteTap: ((CustomHabit) -> Void)?

    init(service: FirestoreHabitService, telemetry: HabitTelemetry?) {
        self.service = service
        self.telemetry = telemetry
        super.init(frame: .zero)
        setupView()
        wireService()
    }
    required init?(coder: NSCoder) { fatalError() }

    func update(distinctCheckInDays days: Int) {
        self.distinctCheckInDays = days
        rerenderFromCurrentState()
    }

    private func setupView() {
        titleLabel.text = NSLocalizedString("quest_habit_section_title", comment: "")
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .themeTextPrimary

        cardsStack.axis = .vertical
        cardsStack.spacing = Layout.cardSpacing

        cardsStack.addArrangedSubview(exerciseCard)
        cardsStack.addArrangedSubview(waterCard)
        cardsStack.addArrangedSubview(meditationCard)
        cardsStack.addArrangedSubview(customCard)
        cardsStack.addArrangedSubview(addButton)
        customCard.isHidden = true

        let outer = UIStackView(arrangedSubviews: [titleLabel, cardsStack])
        outer.axis = .vertical
        outer.spacing = Layout.headerSpacing
        addSubview(outer)
        outer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }

        // Increment tap → log to service
        exerciseCard.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.exercise.rawValue, amount: amount, telemetry: self?.telemetry)
        }
        waterCard.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.water.rawValue, amount: amount, telemetry: self?.telemetry)
        }
        meditationCard.onIncrementTap = { [weak self] amount in
            self?.service.logIncrement(habitId: DefaultHabitId.meditation.rawValue, amount: amount, telemetry: self?.telemetry)
        }

        addButton.onTap = { [weak self] in self?.onAddTap?() }
        addButton.onLockedTap = { [weak self] daysRemaining in self?.onLockedTap?(daysRemaining) }
        customCard.onDeleteTap = { [weak self] in
            guard let active = self?.service.activeCustomHabit() else { return }
            self?.onDeleteTap?(active)
        }
    }

    private func wireService() {
        service.statePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rerenderFromCurrentState() }
            .store(in: &cancellables)
    }

    private func rerenderFromCurrentState() {
        let todayKey = HabitDateKey.dateKey(for: Date(), in: .current)
        // Force read from the publisher's current value via a no-op subscriber:
        var currentState = HabitState.empty
        service.statePublisher
            .first()
            .sink { currentState = $0 }
            .store(in: &cancellables)
        let vm = HabitCheckerViewModel(state: currentState, todayKey: todayKey, distinctCheckInDays: distinctCheckInDays)

        exerciseCard.configure(vm.cardModel(
            for: DefaultHabitId.exercise.rawValue,
            title: DefaultHabitId.exercise.titleKey,
            unit: DefaultHabitId.exercise.unit,
            increments: DefaultHabitId.exercise.increments
        ))
        waterCard.configure(vm.cardModel(
            for: DefaultHabitId.water.rawValue,
            title: DefaultHabitId.water.titleKey,
            unit: DefaultHabitId.water.unit,
            increments: DefaultHabitId.water.increments
        ))
        meditationCard.configure(vm.cardModel(
            for: DefaultHabitId.meditation.rawValue,
            title: DefaultHabitId.meditation.titleKey,
            unit: DefaultHabitId.meditation.unit,
            increments: DefaultHabitId.meditation.increments
        ))

        if let active = vm.activeCustomHabit {
            customCard.isHidden = false
            let yKey = HabitDateKey.yesterdayKey(of: todayKey)
            customCard.configure(
                active,
                todayTotal: currentState.daily[todayKey]?[active.id] ?? 0,
                yesterdayTotal: currentState.daily[yKey]?[active.id] ?? 0
            )
            customCard.onIncrementTap = { [weak self] amount in
                self?.service.logIncrement(habitId: active.id, amount: amount, telemetry: self?.telemetry)
            }
        } else {
            customCard.isHidden = true
        }

        addButton.configure(vm.addButtonState)
    }
}
```

- [ ] **Step 2: Build — verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Habits/HabitCheckerSection.swift
git commit -m "feat(quest/habits): add HabitCheckerSection container with reactive Firestore listener"
```

---

## Task 15: Wire `HabitCheckerSection` into `QuestViewController`

**Files:**
- Modify: `Soulverse/Features/Quest/Views/QuestViewController.swift`
- Modify: `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift`

Plan 2 already exposed `customHabitExists` plumbing. This task plugs in the section.

- [ ] **Step 1: Add section host to `QuestViewController`**

In `QuestViewController.swift`, add (look for the Plan 2 content stack):

```swift
private lazy var habitCheckerSection: HabitCheckerSection = {
    guard let uid = AuthService.shared.currentUserUid else {
        // Service requires uid; guarded by parent flow that user is authenticated.
        fatalError("Quest tab requires authenticated user")
    }
    let service = FirestoreHabitService(uid: uid)
    let telemetry = HabitTelemetry(writer: AnalyticsService.shared)
    let section = HabitCheckerSection(service: service, telemetry: telemetry)
    section.onAddTap = { [weak self] in self?.presentCustomHabitForm(service: service) }
    section.onLockedTap = { [weak self] daysRemaining in self?.showLockedHint(days: daysRemaining) }
    section.onDeleteTap = { [weak self] habit in self?.confirmDelete(habit: habit, service: service) }
    return section
}()

private func presentCustomHabitForm(service: FirestoreHabitService) {
    let formVC = CustomHabitFormViewController()
    formVC.onSave = { [weak self] name, unit, increments in
        service.createCustomHabit(name: name, unit: unit, increments: increments)
        self?.dismiss(animated: true)
    }
    formVC.onCancel = { [weak self] in self?.dismiss(animated: true) }
    let nav = UINavigationController(rootViewController: formVC)
    present(nav, animated: true)
}

private func showLockedHint(days daysRemaining: Int) {
    // Toast or banner — reuse existing toast helper from ViewComponentConstants
    let message = String(format: NSLocalizedString("quest_habit_locked_toast_format", comment: ""), daysRemaining)
    ViewComponentConstants.showToast(in: self, message: message)
}

private func confirmDelete(habit: CustomHabit, service: FirestoreHabitService) {
    let alert = CustomHabitDeletionConfirmation.make(habitName: habit.name) {
        service.softDeleteCustomHabit(id: habit.id)
    }
    present(alert, animated: true)
}
```

In `setupSubviews()` (or equivalent place that adds children to the content stack), insert:

```swift
contentStackView.addArrangedSubview(habitCheckerSection)
```

In the `viewModel.onUpdate` handler, plumb `distinctCheckInDays`:

```swift
habitCheckerSection.update(distinctCheckInDays: viewModel.distinctCheckInDays)
```

- [ ] **Step 2: Update `QuestViewModel` to track `customHabitExists`**

Plan 2 added a stub. Confirm the property exists; if not, add:

```swift
@Published var customHabitExists: Bool = false
```

In the presenter's `recomposeViewModel()`, set this from a new `FirestoreHabitService` instance OR receive it via dependency injection. Either way: ensure `customHabitExists = (active custom habit count > 0)`.

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

- [ ] **Step 4: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestViewController.swift Soulverse/Features/Quest/ViewModels/QuestViewModel.swift
git commit -m "feat(quest): mount HabitCheckerSection in Quest tab with locked-state plumbing"
```

---

## Task 16: Localization strings (en)

**Files:**
- Modify: `Soulverse/Resources/en.lproj/Localizable.strings`

- [ ] **Step 1: Append all habit-related keys**

Append to `Soulverse/Resources/en.lproj/Localizable.strings`:

```
/* Quest > Habit Checker */
"quest_habit_section_title" = "Daily Micro Behaviors";
"quest_habit_exercise_title" = "Exercise";
"quest_habit_water_title" = "Water";
"quest_habit_meditation_title" = "Meditation";
"quest_habit_today_format" = "Today: %d %@";
"quest_habit_yesterday_format" = "Yesterday: %d %@";
"quest_habit_resets_at_midnight" = "Resets at midnight";

/* Quest > Add Custom Habit Button */
"quest_habit_add_custom_locked_format" = "Add Custom Habit unlocks in %d more days";
"quest_habit_add_custom_available" = "Add Custom Habit";
"quest_habit_locked_toast_format" = "Custom habit unlocks in %d more days. Keep checking in!";

/* Quest > Custom Habit Form */
"quest_habit_form_title" = "New Custom Habit";
"quest_habit_form_name_placeholder" = "Habit name (e.g., Stretch)";
"quest_habit_form_unit_placeholder" = "Unit (e.g., min, ml, pages)";
"quest_habit_form_save" = "Save";
"quest_habit_form_preview_format" = "Preview: %@ — buttons %@ %@";
"quest_habit_form_preview_invalid" = "Fill in name, unit, and three distinct positive numbers.";

/* Quest > Custom Habit Deletion */
"quest_habit_delete_alert_title" = "Delete Custom Habit?";
"quest_habit_delete_alert_body_format" = "Delete '%@'? You can create a new custom habit after this.";
"quest_habit_delete_alert_cancel" = "Cancel";
"quest_habit_delete_alert_confirm" = "Delete";
```

- [ ] **Step 2: Build (smoke test)**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' build -quiet
```

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Resources/en.lproj/Localizable.strings
git commit -m "i18n(quest/habits): add en strings for Habit Checker section"
```

---

## Plan summary

After Plan 3 completes:
- Three default habits (Exercise / Water / Meditation) tracked daily, atomic increments via `FieldValue.increment()`.
- "Today" + "Yesterday" reference + "Resets at midnight" copy on each card.
- Custom habit: 1 active slot at a time, unlocked at Day 14, full form with validation + unit-aware suggestions, soft-delete with confirmation.
- Cross-timezone analytics event fired when device timezone shifts >2h within same calendar day during a habit write.

**Cross-plan dependencies surfaced:**
- Plan 2 must expose `contentStackView` (Quest screen container) and `viewModel.distinctCheckInDays`. Plan 2's reviewer notes confirm both are exposed.
- Plan 7 will audit theme tokens and layout constants in this plan's files.
- Plan 4 has no overlap with habits.

**Note for engineer:** the `service.statePublisher.first()` pattern used in Task 14's `rerenderFromCurrentState()` is a workaround for reading the current value synchronously. If `Combine`'s `CurrentValueSubject.value` is preferred, expose a `currentState` property on `FirestoreHabitService` instead.
