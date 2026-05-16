# Onboarding Quest — Plan 4 of 7: Survey Infrastructure (Generic SurveyViewController + Question Banks)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Stand up the iOS-side survey infrastructure for the Onboarding Quest feature: the four `SurveyDefinition`s (Importance Check-In, 8-Dim, State-of-Change, Satisfaction Check-In), pure-Swift scoring functions for each, the generic `SurveyViewController` that renders any survey one question at a time, the generic `SurveyResultViewController` that renders the result of any submission, and `FirestoreSurveyService` for write-once submissions and recent-submission reads. After this plan, surveys can be presented and submitted end-to-end in isolation; integration with the Quest tab's `SurveySection` is Plan 5.

**Architecture:** Pure-Swift question banks and scoring functions live in `Soulverse/Features/Quest/Surveys/`. Each survey type has its own `*SurveyDefinition.swift` file containing question keys, response scale, and a deterministic scoring closure. A single generic `SurveyViewController` is parameterized by `SurveyDefinition` and renders any survey. Submissions flow through `FirestoreSurveyService` to `users/{uid}/survey_submissions/{id}` (write-once, server-stamped `submittedAt`); the Cloud Function trigger from Plan 1 handles the server-side derived-state update.

**Tech Stack:** Swift, UIKit, SnapKit, FirebaseFirestore, NSLocalizedString, XCTest. No new third-party dependencies.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md` (especially §4.3, §5.1, §6.5, §9)

---

## File structure

After this plan, the iOS app will have:

```
Soulverse/Features/Quest/Surveys/
  SurveyType.swift                         # SurveyType enum (4 cases) + helpers
  WellnessDimension.swift                  # 8-dimension enum, shared with mood check-in topic
  ResponseScale.swift                      # 4 response scales (importance / satisfaction / agreement / frequency)
  SurveyResponse.swift                     # { questionKey, questionText, value }
  SurveyDefinition.swift                   # Generic SurveyDefinition struct
  SurveyComputed.swift                     # Discriminated enum of computed-payload variants
  SurveySubmissionPayload.swift            # Top-level submission DTO (Codable)
  Definitions/
    ImportanceSurveyDefinition.swift       # 32 questions + 8-category scoring + tie-breaker
    EightDimSurveyDefinition.swift         # 10 × 8 = 80 questions per dimension; stage 1-3 scoring
    StateOfChangeSurveyDefinition.swift    # 15 questions; substage means + Readiness Index
    SatisfactionSurveyDefinition.swift     # 32 questions + 8-category + top + lowest
  Views/
    SurveyViewController.swift             # Generic, parameterized by SurveyDefinition
    SurveyResultViewController.swift       # Generic, renders SurveySubmissionPayload
    SurveyQuestionCardView.swift           # One-question-per-screen UI
    SurveyResponseScaleView.swift          # 5-button vertical scale
    SurveyProgressBar.swift                # Top-of-screen N/M progress

Soulverse/Shared/Service/QuestService/
  FirestoreSurveyService.swift             # Write-once writer + recent-query reader
  SurveyServiceProtocol.swift              # Service protocol for DI

SoulverseTests/Tests/Features/Quest/Surveys/
  SurveyTypeTests.swift
  ImportanceScoringTests.swift
  EightDimScoringTests.swift
  StateOfChangeScoringTests.swift
  SatisfactionScoringTests.swift
  SurveyResponseSnapshotTests.swift
  SurveyDefinitionExhaustivenessTests.swift

SoulverseTests/Mocks/Features/Quest/
  MockSurveyService.swift

Soulverse/en.lproj/Localizable.strings    # MODIFIED — add ~250 quest_survey_* keys
```

The Quest tab UI (`QuestViewController`, `QuestPresenter`, etc.) is **not** modified in this plan. Plan 5 wires the survey deck into the Quest tab.

---

## Cross-plan dependencies

- **Plan 1 (Cloud Functions) must be deployed** before survey submissions will trigger server-side derived-state updates. This plan can be implemented and unit-tested independently, but end-to-end smoke testing on a real Firestore project requires Plan 1 in place.
- **Plan 5 (Quest tab integration)** consumes the public surface defined in this plan: `SurveyType`, `SurveyDefinition.lookup(_:)`, `SurveyViewController(definition:)`, `SurveyResultViewController(payload:)`, and `FirestoreSurveyService`. Keep these stable.
- **Plan 6 (FCM)** does not depend on this plan directly, but the notification body keys defined in Plan 1's schedule must match keys we reserve in Localizable.strings here. They are already enumerated in §9.

---

## Pre-flight: working branch

- [ ] **Pre-flight:** Create a feature branch from `main`:

```bash
git checkout main
git pull
git checkout -b feat/quest-survey-infrastructure
```

All tasks below commit on this branch. PR opens after Task 22.

---

## Task 1: Define `WellnessDimension` enum

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/WellnessDimension.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/SurveyTypeTests.swift` (placeholder; populated in Task 2)

The 8 wellness dimensions are shared between mood check-in topics (existing) and surveys. Define a single enum source of truth.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/SurveyTypeTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class SurveyTypeTests: XCTestCase {

    func test_wellnessDimension_allCasesCount_is_8() {
        XCTAssertEqual(WellnessDimension.allCases.count, 8)
    }

    func test_wellnessDimension_priorityOrder_matches_spec() {
        // Spec §6.4 tie-breaker level 3 fallback order
        let expected: [WellnessDimension] = [
            .physical, .emotional, .social, .intellectual,
            .spiritual, .occupational, .environmental, .financial
        ]
        XCTAssertEqual(WellnessDimension.priorityOrder, expected)
    }

    func test_wellnessDimension_rawValue_isStable_lowercase_string() {
        XCTAssertEqual(WellnessDimension.physical.rawValue, "physical")
        XCTAssertEqual(WellnessDimension.environmental.rawValue, "environmental")
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/SurveyTypeTests
```

Expected: build fails with "Cannot find type 'WellnessDimension' in scope".

- [ ] **Step 3: Implement `WellnessDimension`**

Create `Soulverse/Features/Quest/Surveys/WellnessDimension.swift`:

```swift
//
//  WellnessDimension.swift
//  Soulverse
//
//  The 8 wellness dimensions used by surveys, focus dimension, and mood
//  check-in topics. Single source of truth.
//

import Foundation

enum WellnessDimension: String, CaseIterable, Codable {
    case physical
    case emotional
    case social
    case intellectual
    case spiritual
    case occupational
    case environmental
    case financial

    /// Tie-breaker fallback order, per spec §6.4 level 3.
    /// Used by Importance Check-In scoring when two dimensions tie at level 1+2.
    static let priorityOrder: [WellnessDimension] = [
        .physical, .emotional, .social, .intellectual,
        .spiritual, .occupational, .environmental, .financial
    ]

    /// Localization key for the user-facing dimension label.
    var labelKey: String { "quest_dimension_\(rawValue)_label" }
}
```

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/SurveyTypeTests
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/WellnessDimension.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/SurveyTypeTests.swift
git commit -m "feat(quest): add WellnessDimension enum with tie-breaker priority order"
```

---

## Task 2: Define `SurveyType` enum + exhaustiveness test

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/SurveyType.swift`
- Modify: `SoulverseTests/Tests/Features/Quest/Surveys/SurveyTypeTests.swift`

`SurveyType` mirrors the TypeScript enum from Plan 1. The raw values must match what `Cloud Function`'s rule engine writes to `quest_state.pendingSurveys`.

- [ ] **Step 1: Extend the failing test**

Add to `SurveyTypeTests.swift`:

```swift
func test_surveyType_allCasesCount_is_4() {
    XCTAssertEqual(SurveyType.allCases.count, 4)
}

func test_surveyType_rawValue_matches_cloudFunctionContract() {
    // Must match SurveyType in functions/src/types.ts (Plan 1).
    XCTAssertEqual(SurveyType.importanceCheckIn.rawValue,    "importance_check_in")
    XCTAssertEqual(SurveyType.eightDim.rawValue,             "8dim")
    XCTAssertEqual(SurveyType.stateOfChange.rawValue,        "state_of_change")
    XCTAssertEqual(SurveyType.satisfactionCheckIn.rawValue,  "satisfaction_check_in")
}

func test_surveyType_decodeFromCloudFunctionString() {
    XCTAssertEqual(SurveyType(rawValue: "importance_check_in"), .importanceCheckIn)
    XCTAssertEqual(SurveyType(rawValue: "8dim"),                .eightDim)
    XCTAssertNil(SurveyType(rawValue: "unknown_survey"))
}
```

- [ ] **Step 2: Run and verify failure**

Test fails: "Cannot find type 'SurveyType'".

- [ ] **Step 3: Implement `SurveyType`**

Create `Soulverse/Features/Quest/Surveys/SurveyType.swift`:

```swift
//
//  SurveyType.swift
//  Soulverse
//
//  Mirrors functions/src/types.ts SurveyType. Raw values must match.
//

import Foundation

enum SurveyType: String, CaseIterable, Codable {
    case importanceCheckIn   = "importance_check_in"
    case eightDim            = "8dim"
    case stateOfChange       = "state_of_change"
    case satisfactionCheckIn = "satisfaction_check_in"
}
```

- [ ] **Step 4: Run and verify passes**

All 6 tests in `SurveyTypeTests` pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/SurveyType.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/SurveyTypeTests.swift
git commit -m "feat(quest): add SurveyType enum mirroring Cloud Function contract"
```

---

## Task 3: Define `ResponseScale` (4 scales)

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/ResponseScale.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/ResponseScaleTests.swift`

Each survey uses one of four 5-point Likert scales. The scale describes the response option labels (localization keys) and the displayed order (top-to-bottom = 5-to-1 or 1-to-5).

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/ResponseScaleTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class ResponseScaleTests: XCTestCase {

    func test_importance_scale_keys() {
        let s = ResponseScale.importance
        XCTAssertEqual(s.optionKeys, [
            "quest_importance_response_1",
            "quest_importance_response_2",
            "quest_importance_response_3",
            "quest_importance_response_4",
            "quest_importance_response_5"
        ])
        XCTAssertEqual(s.range, 1...5)
    }

    func test_satisfaction_scale_keys() {
        XCTAssertEqual(ResponseScale.satisfaction.optionKeys.first, "quest_satisfaction_response_1")
        XCTAssertEqual(ResponseScale.satisfaction.optionKeys.last,  "quest_satisfaction_response_5")
    }

    func test_agreement_scale_shared_keys() {
        // 8-Dim and SoC share the agreement scale per spec §9.1
        XCTAssertEqual(ResponseScale.agreement.optionKeys, [
            "quest_survey_response_1",
            "quest_survey_response_2",
            "quest_survey_response_3",
            "quest_survey_response_4",
            "quest_survey_response_5"
        ])
    }

    func test_frequency_scale_uses_shared_keys() {
        // SoC uses frequency wording but shares the same key namespace
        XCTAssertEqual(ResponseScale.frequency.optionKeys, ResponseScale.agreement.optionKeys)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement `ResponseScale`**

Create `Soulverse/Features/Quest/Surveys/ResponseScale.swift`:

```swift
//
//  ResponseScale.swift
//  Soulverse
//

import Foundation

/// One of four 5-point response scales. Each survey selects a scale.
/// Keys here are localization keys (NSLocalizedString); the scale view
/// resolves them at render time.
enum ResponseScale {
    /// Importance Check-In: Not important → Extremely important.
    case importance
    /// Satisfaction Check-In: Very dissatisfied → Very satisfied.
    case satisfaction
    /// 8-Dim agreement: Not true for me → Very true for me.
    case agreement
    /// State-of-Change frequency: Never → Always. Shares keys with agreement
    /// per spec §9.1 (same 5-point namespace, different question wording).
    case frequency

    var optionKeys: [String] {
        switch self {
        case .importance:
            return (1...5).map { "quest_importance_response_\($0)" }
        case .satisfaction:
            return (1...5).map { "quest_satisfaction_response_\($0)" }
        case .agreement, .frequency:
            return (1...5).map { "quest_survey_response_\($0)" }
        }
    }

    var range: ClosedRange<Int> { 1...5 }
}
```

- [ ] **Step 4: Run, all pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/ResponseScale.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/ResponseScaleTests.swift
git commit -m "feat(quest): add ResponseScale with 4 scales for survey rendering"
```

---

## Task 4: Define `SurveyResponse`, `SurveyComputed`, `SurveySubmissionPayload`

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/SurveyResponse.swift`
- Create: `Soulverse/Features/Quest/Surveys/SurveyComputed.swift`
- Create: `Soulverse/Features/Quest/Surveys/SurveySubmissionPayload.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/SurveyResponseSnapshotTests.swift`

These are the wire-format DTOs persisted to Firestore. `SurveyResponse` carries the self-describing snapshot per spec §4.3 (questionKey + questionText + value). `SurveyComputed` is a discriminated enum keyed by `SurveyType` so each variant can carry the per-type computed payload.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/SurveyResponseSnapshotTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class SurveyResponseSnapshotTests: XCTestCase {

    func test_response_carries_key_text_and_value() {
        let r = SurveyResponse(
            questionKey: "quest_survey_importance_q01_text",
            questionText: "How important to you is your overall quality of life?",
            value: 4
        )
        XCTAssertEqual(r.questionKey, "quest_survey_importance_q01_text")
        XCTAssertEqual(r.questionText, "How important to you is your overall quality of life?")
        XCTAssertEqual(r.value, 4)
    }

    func test_response_dictRepresentation_matches_firestore_schema() {
        let r = SurveyResponse(
            questionKey: "quest_survey_importance_q01_text",
            questionText: "How important to you is your overall quality of life?",
            value: 4
        )
        let dict = r.firestoreDict
        XCTAssertEqual(dict["questionKey"] as? String, "quest_survey_importance_q01_text")
        XCTAssertEqual(dict["questionText"] as? String,
                       "How important to you is your overall quality of life?")
        XCTAssertEqual(dict["value"] as? Int, 4)
    }

    func test_importance_computed_dictRepresentation_includes_categoryMeans_top_and_tieBreaker() {
        let computed = SurveyComputed.importance(
            categoryMeans: [.physical: 3.5, .emotional: 4.2, .social: 3.8,
                            .intellectual: 3.6, .spiritual: 3.3, .occupational: 4.0,
                            .environmental: 3.5, .financial: 3.5],
            topCategory: .emotional,
            tieBreakerLevel: 1
        )
        let dict = computed.firestoreDict
        let means = dict["categoryMeans"] as? [String: Double]
        XCTAssertEqual(means?["emotional"], 4.2)
        XCTAssertEqual(dict["topCategory"] as? String, "emotional")
        XCTAssertEqual(dict["tieBreakerLevel"] as? Int, 1)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement DTOs**

Create `Soulverse/Features/Quest/Surveys/SurveyResponse.swift`:

```swift
//
//  SurveyResponse.swift
//  Soulverse
//
//  Self-describing response per spec §4.3.
//

import Foundation

struct SurveyResponse: Equatable {
    let questionKey: String
    let questionText: String
    let value: Int

    var firestoreDict: [String: Any] {
        return [
            "questionKey":  questionKey,
            "questionText": questionText,
            "value":        value
        ]
    }
}
```

Create `Soulverse/Features/Quest/Surveys/SurveyComputed.swift`:

```swift
//
//  SurveyComputed.swift
//  Soulverse
//
//  Discriminated enum of per-survey computed payloads. Each case maps 1:1
//  to a SurveyType. Cloud Function reads `topCategory` from the importance
//  case to set `quest_state.focusDimension`.
//

import Foundation

enum SurveyComputed {

    case importance(
        categoryMeans: [WellnessDimension: Double],
        topCategory: WellnessDimension,
        tieBreakerLevel: Int           // 1, 2, or 3
    )

    case eightDim(
        dimension: WellnessDimension,
        totalScore: Int,
        meanScore: Double,
        stage: Int,                    // 1-3
        stageKey: String,              // "quest_stage_8dim_<dim>_<stage>_label"
        messageKey: String             // "quest_stage_8dim_<dim>_<stage>_message"
    )

    case stateOfChange(
        dimension: WellnessDimension,
        substageMeans: SubstageMeans,
        readinessIndex: Double,
        stage: Int,                    // 1-5
        stageKey: String,              // "quest_stage_soc_<stage>_label"
        stageMessageKey: String        // "quest_stage_soc_<stage>_message"
    )

    case satisfaction(
        categoryMeans: [WellnessDimension: Double],
        topCategory: WellnessDimension,
        lowestCategory: WellnessDimension
    )

    struct SubstageMeans: Equatable {
        let precontemplation: Double
        let contemplation:    Double
        let preparation:      Double
        let action:           Double
        let maintenance:      Double
    }

    var firestoreDict: [String: Any] {
        switch self {
        case let .importance(means, top, tbl):
            return [
                "categoryMeans":   Self.dimensionMeansDict(means),
                "topCategory":     top.rawValue,
                "tieBreakerLevel": tbl
            ]
        case let .eightDim(_, total, mean, stage, stageKey, messageKey):
            return [
                "totalScore": total,
                "meanScore":  mean,
                "stage":      stage,
                "stageKey":   stageKey,
                "messageKey": messageKey
            ]
        case let .stateOfChange(_, means, readiness, stage, stageKey, stageMessageKey):
            return [
                "substageMeans": [
                    "precontemplation": means.precontemplation,
                    "contemplation":    means.contemplation,
                    "preparation":      means.preparation,
                    "action":           means.action,
                    "maintenance":      means.maintenance
                ],
                "readinessIndex":  readiness,
                "stage":           stage,
                "stageKey":        stageKey,
                "stageMessageKey": stageMessageKey
            ]
        case let .satisfaction(means, top, lowest):
            return [
                "categoryMeans":  Self.dimensionMeansDict(means),
                "topCategory":    top.rawValue,
                "lowestCategory": lowest.rawValue
            ]
        }
    }

    private static func dimensionMeansDict(
        _ means: [WellnessDimension: Double]
    ) -> [String: Double] {
        var dict: [String: Double] = [:]
        for (k, v) in means { dict[k.rawValue] = v }
        return dict
    }
}
```

Create `Soulverse/Features/Quest/Surveys/SurveySubmissionPayload.swift`:

```swift
//
//  SurveySubmissionPayload.swift
//  Soulverse
//

import Foundation

/// The full document written to users/{uid}/survey_submissions/{id}.
/// `submittedAt` is server-stamped via FieldValue.serverTimestamp() at write time
/// (not stored in this struct).
struct SurveySubmissionPayload {
    let submissionId: String
    let surveyType: SurveyType
    let appVersion: String
    let submittedFromQuestDay: Int
    let dimension: WellnessDimension?     // nil for importance & satisfaction
    let responses: [SurveyResponse]
    let computed: SurveyComputed
}
```

- [ ] **Step 4: Run, all pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/SurveyResponse.swift \
        Soulverse/Features/Quest/Surveys/SurveyComputed.swift \
        Soulverse/Features/Quest/Surveys/SurveySubmissionPayload.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/SurveyResponseSnapshotTests.swift
git commit -m "feat(quest): add survey DTOs (response/computed/payload) for Firestore wire format"
```

---

## Task 5: Define `SurveyDefinition` struct + lookup registry

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/SurveyDefinition.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/SurveyDefinitionExhaustivenessTests.swift`

A `SurveyDefinition` carries everything needed to render and score a survey: question list (key + scoring index), response scale, and a scoring closure that takes raw responses and returns a `SurveyComputed`. Each per-type definition (Importance, 8-Dim, SoC, Satisfaction) provides a static factory in subsequent tasks. `SurveyDefinition.lookup(_:)` resolves a `SurveyType` to its definition.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/SurveyDefinitionExhaustivenessTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class SurveyDefinitionExhaustivenessTests: XCTestCase {

    /// Every SurveyType must have a corresponding SurveyDefinition.
    /// Future SurveyType cases will fail this test until they're registered.
    func test_lookup_resolves_for_every_surveyType() {
        for type in SurveyType.allCases {
            // For 8-Dim and SoC, the definition is dimension-scoped; we look up with .emotional
            switch type {
            case .eightDim, .stateOfChange:
                let def = SurveyDefinition.lookup(type, dimension: .emotional)
                XCTAssertNotNil(def, "SurveyDefinition.lookup is missing case for \(type)")
                XCTAssertEqual(def?.surveyType, type)
            case .importanceCheckIn, .satisfactionCheckIn:
                let def = SurveyDefinition.lookup(type, dimension: nil)
                XCTAssertNotNil(def, "SurveyDefinition.lookup is missing case for \(type)")
                XCTAssertEqual(def?.surveyType, type)
            }
        }
    }

    func test_importance_definition_has_32_questions() {
        let def = SurveyDefinition.lookup(.importanceCheckIn, dimension: nil)
        XCTAssertEqual(def?.questions.count, 32)
    }

    func test_eightDim_definition_has_10_questions() {
        let def = SurveyDefinition.lookup(.eightDim, dimension: .emotional)
        XCTAssertEqual(def?.questions.count, 10)
    }

    func test_stateOfChange_definition_has_15_questions() {
        let def = SurveyDefinition.lookup(.stateOfChange, dimension: .emotional)
        XCTAssertEqual(def?.questions.count, 15)
    }

    func test_satisfaction_definition_has_32_questions() {
        let def = SurveyDefinition.lookup(.satisfactionCheckIn, dimension: nil)
        XCTAssertEqual(def?.questions.count, 32)
    }
}
```

- [ ] **Step 2: Run, verify failure**

(All assertions fail because the lookup returns nil — no per-type definitions exist yet. They land in Tasks 6–9.)

- [ ] **Step 3: Implement `SurveyDefinition`**

Create `Soulverse/Features/Quest/Surveys/SurveyDefinition.swift`:

```swift
//
//  SurveyDefinition.swift
//  Soulverse
//
//  A SurveyDefinition is the static description of one survey: questions,
//  response scale, and a pure scoring function. Generic SurveyViewController
//  consumes these to render and submit any survey.
//

import Foundation

struct SurveyDefinition {

    /// One question = a localization key (used to resolve text via
    /// NSLocalizedString) plus its 1-based question number for scoring index.
    struct Question {
        let key: String           // e.g. "quest_survey_importance_q01_text"
        let number: Int           // 1-based, matches the q<NN> in the key
    }

    let surveyType: SurveyType

    /// Set for 8-Dim and State-of-Change; nil for Importance and Satisfaction.
    /// 8-Dim and SoC are dimension-scoped surveys (the user takes them
    /// against their currently-assigned focus dimension).
    let dimension: WellnessDimension?

    let questions: [Question]
    let responseScale: ResponseScale
    let titleKey: String

    /// Pure function: given the user's raw responses (in the same order as
    /// `questions`), produce the typed `SurveyComputed` payload.
    /// Implementation lives in the per-type *SurveyDefinition.swift.
    let score: (_ responses: [SurveyResponse]) -> SurveyComputed

    /// Resolve a SurveyType (and optional dimension) to its definition.
    /// Returns nil if the type/dimension combination is unsupported.
    static func lookup(
        _ type: SurveyType,
        dimension: WellnessDimension?
    ) -> SurveyDefinition? {
        switch type {
        case .importanceCheckIn:
            return ImportanceSurveyDefinition.make()
        case .eightDim:
            guard let dim = dimension else { return nil }
            return EightDimSurveyDefinition.make(dimension: dim)
        case .stateOfChange:
            guard let dim = dimension else { return nil }
            return StateOfChangeSurveyDefinition.make(dimension: dim)
        case .satisfactionCheckIn:
            return SatisfactionSurveyDefinition.make()
        }
    }
}
```

- [ ] **Step 4: Run — still failing (per-type factories don't exist)**

This is expected. The test will pass after Task 9. Commit the scaffolding now so subsequent tasks can build on it.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/SurveyDefinition.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/SurveyDefinitionExhaustivenessTests.swift
git commit -m "feat(quest): scaffold SurveyDefinition struct and lookup registry"
```

(Code will not compile yet — references to `ImportanceSurveyDefinition` etc. are forward references resolved in the next 4 tasks. If your team's pre-commit hook runs the build, push the lookup body into a `fatalError("not implemented")` placeholder per type and uncomment as each task completes.)

---

## Task 6: `ImportanceSurveyDefinition` — 32 questions + 8-category scoring + tie-breaker

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Definitions/ImportanceSurveyDefinition.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/ImportanceScoringTests.swift`

The Importance Check-In has 32 questions on a 5-point importance scale. Scoring computes mean per category (8 categories) per spec §4.3 formulas, then picks `topCategory` by highest mean. **Tie-breaker level 1+2 logic happens server-side** (Cloud Function reads `mood_checkins` to count topic frequency at level 2). The client is responsible only for reporting the highest-mean dimension and `tieBreakerLevel: 1` if unambiguous, or marking it as a tie for the server to resolve.

Per spec §6.4, our client implementation:
- If exactly one dimension has the highest mean → `topCategory = that dim, tieBreakerLevel = 1`.
- If 2+ tie at the highest mean → fall back to predetermined order (`WellnessDimension.priorityOrder`); set `tieBreakerLevel = 3` (the level-2 mood-topic-count tie-break is server-side and the Cloud Function may overwrite `topCategory` and `tieBreakerLevel` after reading the user's mood check-in history). For MVP, the client always uses level-1-or-3 since it has no mood-topic data here.

> **Note for engineer:** the design doc allows the server to overwrite. To keep the client simple and the data schema honest, we report the dimension we computed, and the Cloud Function in Plan 1 may upgrade `tieBreakerLevel` to 2 and pick a different dimension based on mood topics. This is acknowledged in spec §6.4.

Per spec §4.3 — category formulas:

| Category       | Sum of question values | Divide by |
|----------------|------------------------|-----------|
| physical       | Q2 + Q3 + Q4 + Q5 + Q15 + Q16 | 6 |
| emotional      | Q6 + Q7 + Q8 + Q12 + Q14 | 5 |
| social         | Q19 + Q20 + Q21        | 3 |
| intellectual   | Q9 + Q10 + Q11 + Q27 + Q28 | 5 |
| spiritual      | Q7 + Q8 + Q32          | 3 |
| occupational   | Q18                    | 1 |
| environmental  | Q22 + Q23 + Q30 + Q31  | 4 |
| financial      | Q17 + Q24 + Q25 + Q26  | 4 |

Q1, Q13, Q29 are **observational** (not scored into any category). They're still rendered and stored in `responses[]` for analytics. The `categoryMeans` formula simply ignores them. (Q7 and Q8 contribute to both emotional and spiritual per the wellness doc.)

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/ImportanceScoringTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class ImportanceScoringTests: XCTestCase {

    /// Helper: build 32 SurveyResponses where each Q_i has value v_i.
    /// values is 1-indexed so callers can match the spec.
    private func makeResponses(values: [Int: Int], default defaultValue: Int = 3) -> [SurveyResponse] {
        return (1...32).map { i in
            SurveyResponse(
                questionKey: String(format: "quest_survey_importance_q%02d_text", i),
                questionText: "Q\(i) snapshot",
                value: values[i] ?? defaultValue
            )
        }
    }

    func test_categoryMeans_uniform_3() {
        let resps = makeResponses(values: [:], default: 3)
        let computed = ImportanceSurveyDefinition.score(responses: resps)
        guard case let .importance(means, _, _) = computed else {
            XCTFail("expected .importance"); return
        }
        for dim in WellnessDimension.allCases {
            XCTAssertEqual(means[dim], 3.0, accuracy: 0.0001, "\(dim) should be 3.0")
        }
    }

    func test_categoryMeans_physical_formula() {
        // physical = (Q2+Q3+Q4+Q5+Q15+Q16) / 6 → set them to 5; rest = 1
        let values = [2:5, 3:5, 4:5, 5:5, 15:5, 16:5]
        let resps = makeResponses(values: values, default: 1)
        let computed = ImportanceSurveyDefinition.score(responses: resps)
        guard case let .importance(means, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(means[.physical], 5.0, accuracy: 0.0001)
    }

    func test_categoryMeans_occupational_singleQuestion_Q18() {
        let values = [18: 4]
        let resps = makeResponses(values: values, default: 1)
        let computed = ImportanceSurveyDefinition.score(responses: resps)
        guard case let .importance(means, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(means[.occupational], 4.0, accuracy: 0.0001)
    }

    func test_categoryMeans_emotional_formula_Q6_Q7_Q8_Q12_Q14() {
        let values = [6:5, 7:5, 8:5, 12:5, 14:5]
        let resps = makeResponses(values: values, default: 1)
        let computed = ImportanceSurveyDefinition.score(responses: resps)
        guard case let .importance(means, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(means[.emotional], 5.0, accuracy: 0.0001)
    }

    func test_topCategory_picks_highest_mean_unambiguous() {
        // Set emotional questions all to 5, others to 1
        let values = [6:5, 7:5, 8:5, 12:5, 14:5]
        let resps = makeResponses(values: values, default: 1)
        let computed = ImportanceSurveyDefinition.score(responses: resps)
        guard case let .importance(_, top, level) = computed else { XCTFail(); return }
        XCTAssertEqual(top, .emotional)
        XCTAssertEqual(level, 1)
    }

    func test_topCategory_tied_falls_back_to_priorityOrder_at_level_3() {
        // All categories equal at value 3 → tie. Priority order: physical first.
        let resps = makeResponses(values: [:], default: 3)
        let computed = ImportanceSurveyDefinition.score(responses: resps)
        guard case let .importance(_, top, level) = computed else { XCTFail(); return }
        XCTAssertEqual(top, .physical)
        XCTAssertEqual(level, 3)
    }

    func test_definition_questionCount_is_32() {
        XCTAssertEqual(ImportanceSurveyDefinition.make().questions.count, 32)
    }

    func test_definition_responseScale_is_importance() {
        // Identity check via discriminant
        let def = ImportanceSurveyDefinition.make()
        if case .importance = def.responseScale { /* ok */ } else { XCTFail() }
    }

    func test_question_keys_match_pattern() {
        let def = ImportanceSurveyDefinition.make()
        XCTAssertEqual(def.questions[0].key,  "quest_survey_importance_q01_text")
        XCTAssertEqual(def.questions[31].key, "quest_survey_importance_q32_text")
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement `ImportanceSurveyDefinition`**

Create `Soulverse/Features/Quest/Surveys/Definitions/ImportanceSurveyDefinition.swift`:

```swift
//
//  ImportanceSurveyDefinition.swift
//  Soulverse
//
//  32 questions on a 5-point importance scale. Scoring per spec §4.3.
//

import Foundation

enum ImportanceSurveyDefinition {

    /// Spec §4.3 — which question numbers contribute to each category.
    /// Note Q7 + Q8 contribute to both emotional and spiritual per the
    /// wellness doc. Q1, Q13, Q29 are observational and excluded.
    private static let categoryQuestionNumbers: [WellnessDimension: [Int]] = [
        .physical:      [2, 3, 4, 5, 15, 16],
        .emotional:     [6, 7, 8, 12, 14],
        .social:        [19, 20, 21],
        .intellectual:  [9, 10, 11, 27, 28],
        .spiritual:     [7, 8, 32],
        .occupational:  [18],
        .environmental: [22, 23, 30, 31],
        .financial:     [17, 24, 25, 26]
    ]

    static func make() -> SurveyDefinition {
        let questions = (1...32).map { n in
            SurveyDefinition.Question(
                key:    String(format: "quest_survey_importance_q%02d_text", n),
                number: n
            )
        }
        return SurveyDefinition(
            surveyType:    .importanceCheckIn,
            dimension:     nil,
            questions:     questions,
            responseScale: .importance,
            titleKey:      "quest_survey_importance_title",
            score:         { responses in score(responses: responses) }
        )
    }

    /// Pure scoring function — exposed for unit tests.
    static func score(responses: [SurveyResponse]) -> SurveyComputed {
        precondition(responses.count == 32, "Importance survey requires 32 responses")

        // Build 1-indexed value lookup
        var values: [Int: Int] = [:]
        for (idx, r) in responses.enumerated() { values[idx + 1] = r.value }

        // Compute per-category means
        var means: [WellnessDimension: Double] = [:]
        for (dim, qs) in categoryQuestionNumbers {
            let sum = qs.reduce(0) { $0 + (values[$1] ?? 0) }
            means[dim] = Double(sum) / Double(qs.count)
        }

        // Pick top category — ties resolve to priorityOrder (level 3)
        let (topCategory, level) = pickTopCategory(means: means)
        return .importance(
            categoryMeans:   means,
            topCategory:     topCategory,
            tieBreakerLevel: level
        )
    }

    private static func pickTopCategory(
        means: [WellnessDimension: Double]
    ) -> (WellnessDimension, Int) {
        // Highest mean
        let highest = means.values.max() ?? 0
        let tied = WellnessDimension.priorityOrder.filter {
            (means[$0] ?? 0) == highest
        }
        if tied.count == 1 {
            return (tied[0], 1)
        }
        // Level-2 (mood-topic-count) is server-side. Client falls back to level 3.
        return (tied[0], 3)
    }
}
```

- [ ] **Step 4: Run, all 9 tests pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Definitions/ImportanceSurveyDefinition.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/ImportanceScoringTests.swift
git commit -m "feat(quest): add ImportanceSurveyDefinition with 32-question 8-category scoring"
```

---

## Task 7: `EightDimSurveyDefinition` — 10 questions × 8 dimensions, stage 1-3

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Definitions/EightDimSurveyDefinition.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/EightDimScoringTests.swift`

The 8-Dim survey has 10 questions per dimension. The user takes it against their currently-assigned focus dimension. Scoring per spec §4.3:

- `totalScore = sum of 10 values` (range 10–50)
- `meanScore  = totalScore / 10` (range 1.0–5.0)
- Stage:
  - Stage 1: meanScore ∈ [1.0, 2.5)
  - Stage 2: meanScore ∈ [2.5, 3.8)
  - Stage 3: meanScore ∈ [3.8, 5.0]

(Boundaries chosen so a tie at exactly 2.5 reads as stage 2 — "Steady Flame" — which is the friendly intent of the wellness doc.)

`stageKey = "quest_stage_8dim_<dim>_<stage>_label"`
`messageKey = "quest_stage_8dim_<dim>_<stage>_message"`

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/EightDimScoringTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class EightDimScoringTests: XCTestCase {

    private func makeResponses(
        dimension: WellnessDimension,
        values: [Int]
    ) -> [SurveyResponse] {
        precondition(values.count == 10)
        return values.enumerated().map { (idx, v) in
            SurveyResponse(
                questionKey: String(
                    format: "quest_survey_8dim_%@_q%02d_text",
                    dimension.rawValue, idx + 1
                ),
                questionText: "8dim Q\(idx + 1)",
                value: v
            )
        }
    }

    func test_meanScore_all_3() {
        let resps = makeResponses(dimension: .emotional, values: Array(repeating: 3, count: 10))
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, total, mean, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(total, 30)
        XCTAssertEqual(mean, 3.0, accuracy: 0.0001)
        XCTAssertEqual(stage, 2)
    }

    func test_stage1_lowestRange() {
        let resps = makeResponses(dimension: .emotional, values: Array(repeating: 1, count: 10))
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, _, _, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(stage, 1)
    }

    func test_stage1_at_24() {
        // mean 2.4 → stage 1
        let resps = makeResponses(
            dimension: .emotional,
            values: [2,2,2,2,2,2,3,3,3,3]   // sum 24, mean 2.4
        )
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, _, mean, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(mean, 2.4, accuracy: 0.0001)
        XCTAssertEqual(stage, 1)
    }

    func test_stage2_at_25() {
        // mean 2.5 → stage 2 (lower boundary inclusive)
        let resps = makeResponses(dimension: .emotional, values: [2,2,2,2,2,3,3,3,3,3])
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, _, mean, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(mean, 2.5, accuracy: 0.0001)
        XCTAssertEqual(stage, 2)
    }

    func test_stage2_at_37() {
        // mean 3.7 → stage 2
        let resps = makeResponses(dimension: .emotional, values: [3,3,3,4,4,4,4,4,4,4])
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, _, mean, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(mean, 3.7, accuracy: 0.0001)
        XCTAssertEqual(stage, 2)
    }

    func test_stage3_at_38() {
        // mean 3.8 → stage 3 (lower boundary inclusive)
        let resps = makeResponses(dimension: .emotional, values: [3,4,4,4,4,4,4,4,4,3])
        // sum = 38, mean = 3.8
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, _, mean, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(mean, 3.8, accuracy: 0.0001)
        XCTAssertEqual(stage, 3)
    }

    func test_stage3_at_50() {
        let resps = makeResponses(dimension: .emotional, values: Array(repeating: 5, count: 10))
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .eightDim(_, _, _, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(stage, 3)
    }

    func test_stageKey_and_messageKey_match_pattern_per_dimension() {
        let resps = makeResponses(dimension: .physical, values: Array(repeating: 4, count: 10))
        let computed = EightDimSurveyDefinition.score(responses: resps, dimension: .physical)
        guard case let .eightDim(dim, _, _, _, stageKey, messageKey) = computed else { XCTFail(); return }
        XCTAssertEqual(dim, .physical)
        XCTAssertEqual(stageKey,   "quest_stage_8dim_physical_3_label")
        XCTAssertEqual(messageKey, "quest_stage_8dim_physical_3_message")
    }

    func test_definition_questionCount_is_10_per_dim() {
        let def = EightDimSurveyDefinition.make(dimension: .emotional)
        XCTAssertEqual(def.questions.count, 10)
        XCTAssertEqual(def.questions[0].key,  "quest_survey_8dim_emotional_q01_text")
        XCTAssertEqual(def.questions[9].key,  "quest_survey_8dim_emotional_q10_text")
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement `EightDimSurveyDefinition`**

Create `Soulverse/Features/Quest/Surveys/Definitions/EightDimSurveyDefinition.swift`:

```swift
//
//  EightDimSurveyDefinition.swift
//  Soulverse
//
//  10 questions × 8 dimensions = 80 question keys total.
//  User takes it against their focus dimension.
//

import Foundation

enum EightDimSurveyDefinition {

    static func make(dimension: WellnessDimension) -> SurveyDefinition {
        let questions = (1...10).map { n in
            SurveyDefinition.Question(
                key:    String(
                    format: "quest_survey_8dim_%@_q%02d_text",
                    dimension.rawValue, n
                ),
                number: n
            )
        }
        return SurveyDefinition(
            surveyType:    .eightDim,
            dimension:     dimension,
            questions:     questions,
            responseScale: .agreement,
            titleKey:      "quest_survey_8dim_\(dimension.rawValue)_title",
            score:         { responses in
                score(responses: responses, dimension: dimension)
            }
        )
    }

    static func score(
        responses: [SurveyResponse],
        dimension: WellnessDimension
    ) -> SurveyComputed {
        precondition(responses.count == 10, "8-Dim survey requires 10 responses")
        let total = responses.reduce(0) { $0 + $1.value }
        let mean  = Double(total) / 10.0
        let stage = stageFor(mean: mean)
        return .eightDim(
            dimension:  dimension,
            totalScore: total,
            meanScore:  mean,
            stage:      stage,
            stageKey:   "quest_stage_8dim_\(dimension.rawValue)_\(stage)_label",
            messageKey: "quest_stage_8dim_\(dimension.rawValue)_\(stage)_message"
        )
    }

    /// Stage boundaries per spec §4.3:
    ///   Stage 1: [1.0, 2.5)
    ///   Stage 2: [2.5, 3.8)
    ///   Stage 3: [3.8, 5.0]
    private static func stageFor(mean: Double) -> Int {
        if mean < 2.5 { return 1 }
        if mean < 3.8 { return 2 }
        return 3
    }
}
```

- [ ] **Step 4: Run, all 9 tests pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Definitions/EightDimSurveyDefinition.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/EightDimScoringTests.swift
git commit -m "feat(quest): add EightDimSurveyDefinition with 3-stage wellness scoring"
```

---

## Task 8: `StateOfChangeSurveyDefinition` — 15 questions, substage means + Readiness Index

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Definitions/StateOfChangeSurveyDefinition.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/StateOfChangeScoringTests.swift`

State-of-Change has 15 questions on a 5-point frequency scale. Per spec §4.3:

| Substage          | Question numbers | Divide by |
|-------------------|------------------|-----------|
| precontemplation  | Q2 + Q9 + Q15    | 3 |
| contemplation     | Q4 + Q11 + Q14   | 3 |
| preparation       | Q6 + Q10 + Q12   | 3 |
| action            | Q3 + Q7 + Q8     | 3 |
| maintenance       | Q1 + Q5 + Q13    | 3 |

`readinessIndex = PC*1 + C*2 + P*3 + A*4 + M*5` where each substage value is its mean.

Stage selection: pick the substage with the **highest mean**; ties resolve to **higher-numbered substage** (i.e. the user is "further along"). Mapping:
- precontemplation → stage 1 (Considering)
- contemplation    → stage 2 (Planning)
- preparation      → stage 3 (Preparing)
- action           → stage 4 (Doing)
- maintenance      → stage 5 (Sustaining)

`stageKey = "quest_stage_soc_<stage>_label"`
`stageMessageKey = "quest_stage_soc_<stage>_message"`

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/StateOfChangeScoringTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class StateOfChangeScoringTests: XCTestCase {

    private func makeResponses(values: [Int: Int], default defaultValue: Int = 3) -> [SurveyResponse] {
        return (1...15).map { i in
            SurveyResponse(
                questionKey: String(format: "quest_survey_soc_q%02d_text", i),
                questionText: "SoC Q\(i)",
                value: values[i] ?? defaultValue
            )
        }
    }

    func test_substageMeans_precontemplation_formula() {
        let resps = makeResponses(values: [2:5, 9:5, 15:5], default: 1)
        let computed = StateOfChangeSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .stateOfChange(_, means, _, _, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(means.precontemplation, 5.0, accuracy: 0.0001)
    }

    func test_substageMeans_contemplation_formula() {
        let resps = makeResponses(values: [4:5, 11:5, 14:5], default: 1)
        let computed = StateOfChangeSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .stateOfChange(_, means, _, _, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(means.contemplation, 5.0, accuracy: 0.0001)
    }

    func test_readinessIndex_uniform_3() {
        // All means = 3 → 3*1 + 3*2 + 3*3 + 3*4 + 3*5 = 3*15 = 45
        let resps = makeResponses(values: [:], default: 3)
        let computed = StateOfChangeSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .stateOfChange(_, _, readiness, _, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(readiness, 45.0, accuracy: 0.0001)
    }

    func test_stage_picks_highest_mean_substage() {
        // Maintenance highest → stage 5
        let resps = makeResponses(values: [1:5, 5:5, 13:5], default: 1)
        let computed = StateOfChangeSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .stateOfChange(_, _, _, stage, key, msg) = computed else { XCTFail(); return }
        XCTAssertEqual(stage, 5)
        XCTAssertEqual(key, "quest_stage_soc_5_label")
        XCTAssertEqual(msg, "quest_stage_soc_5_message")
    }

    func test_stage_tie_breaks_higher_substage() {
        // Equal means in contemplation and preparation; pick preparation (stage 3)
        let resps = makeResponses(values: [4:5, 11:5, 14:5, 6:5, 10:5, 12:5], default: 1)
        let computed = StateOfChangeSurveyDefinition.score(responses: resps, dimension: .emotional)
        guard case let .stateOfChange(_, _, _, stage, _, _) = computed else { XCTFail(); return }
        XCTAssertEqual(stage, 3)
    }

    func test_definition_questionCount_is_15() {
        let def = StateOfChangeSurveyDefinition.make(dimension: .emotional)
        XCTAssertEqual(def.questions.count, 15)
        XCTAssertEqual(def.questions[0].key,  "quest_survey_soc_q01_text")
        XCTAssertEqual(def.questions[14].key, "quest_survey_soc_q15_text")
    }

    func test_definition_responseScale_is_frequency() {
        let def = StateOfChangeSurveyDefinition.make(dimension: .emotional)
        if case .frequency = def.responseScale { /* ok */ } else { XCTFail() }
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement `StateOfChangeSurveyDefinition`**

Create `Soulverse/Features/Quest/Surveys/Definitions/StateOfChangeSurveyDefinition.swift`:

```swift
//
//  StateOfChangeSurveyDefinition.swift
//  Soulverse
//
//  15 questions, 5-point frequency scale. Substage means + Readiness Index
//  per spec §4.3. Stage 1-5 with friendly labels (Considering / Planning /
//  Preparing / Doing / Sustaining) per spec §9.4.
//

import Foundation

enum StateOfChangeSurveyDefinition {

    /// Note: SoC question keys are dimension-agnostic (per spec §9.1 namespace).
    /// User takes the survey against their focus dimension; the dimension is
    /// recorded in the submission payload but doesn't affect question text.

    private static let substageQuestionNumbers: [(label: String, qs: [Int], stage: Int)] = [
        ("precontemplation", [2,  9, 15], 1),
        ("contemplation",    [4, 11, 14], 2),
        ("preparation",      [6, 10, 12], 3),
        ("action",           [3,  7,  8], 4),
        ("maintenance",      [1,  5, 13], 5)
    ]

    static func make(dimension: WellnessDimension) -> SurveyDefinition {
        let questions = (1...15).map { n in
            SurveyDefinition.Question(
                key:    String(format: "quest_survey_soc_q%02d_text", n),
                number: n
            )
        }
        return SurveyDefinition(
            surveyType:    .stateOfChange,
            dimension:     dimension,
            questions:     questions,
            responseScale: .frequency,
            titleKey:      "quest_survey_soc_title",
            score:         { responses in
                score(responses: responses, dimension: dimension)
            }
        )
    }

    static func score(
        responses: [SurveyResponse],
        dimension: WellnessDimension
    ) -> SurveyComputed {
        precondition(responses.count == 15, "SoC survey requires 15 responses")
        var values: [Int: Int] = [:]
        for (idx, r) in responses.enumerated() { values[idx + 1] = r.value }

        func mean(_ qs: [Int]) -> Double {
            let sum = qs.reduce(0) { $0 + (values[$1] ?? 0) }
            return Double(sum) / Double(qs.count)
        }

        let pc = mean(substageQuestionNumbers[0].qs)
        let c  = mean(substageQuestionNumbers[1].qs)
        let p  = mean(substageQuestionNumbers[2].qs)
        let a  = mean(substageQuestionNumbers[3].qs)
        let m  = mean(substageQuestionNumbers[4].qs)

        let readiness = pc * 1 + c * 2 + p * 3 + a * 4 + m * 5

        // Pick highest mean substage; ties → higher stage number.
        let staged: [(stage: Int, value: Double)] = [
            (1, pc), (2, c), (3, p), (4, a), (5, m)
        ]
        let highest = staged.max { lhs, rhs in
            if lhs.value != rhs.value { return lhs.value < rhs.value }
            return lhs.stage < rhs.stage           // tie → prefer higher stage
        }!

        return .stateOfChange(
            dimension: dimension,
            substageMeans: SurveyComputed.SubstageMeans(
                precontemplation: pc,
                contemplation:    c,
                preparation:      p,
                action:           a,
                maintenance:      m
            ),
            readinessIndex:  readiness,
            stage:           highest.stage,
            stageKey:        "quest_stage_soc_\(highest.stage)_label",
            stageMessageKey: "quest_stage_soc_\(highest.stage)_message"
        )
    }
}
```

- [ ] **Step 4: Run, all 7 tests pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Definitions/StateOfChangeSurveyDefinition.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/StateOfChangeScoringTests.swift
git commit -m "feat(quest): add StateOfChangeSurveyDefinition with 5-stage readiness scoring"
```

---

## Task 9: `SatisfactionSurveyDefinition` — 32 questions + top + lowest category

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Definitions/SatisfactionSurveyDefinition.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/SatisfactionScoringTests.swift`

The Satisfaction Check-In has 32 questions on a 5-point satisfaction scale. **Same 8-category formulas as Importance** (spec §4.3 says Satisfaction reuses the formulas, just different scale wording). Output adds `lowestCategory`.

Tie-breaker for `topCategory`/`lowestCategory`: same priority-order fallback as Importance.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/SatisfactionScoringTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class SatisfactionScoringTests: XCTestCase {

    private func makeResponses(values: [Int: Int], default defaultValue: Int = 3) -> [SurveyResponse] {
        return (1...32).map { i in
            SurveyResponse(
                questionKey: String(format: "quest_survey_satisfaction_q%02d_text", i),
                questionText: "Satisfaction Q\(i)",
                value: values[i] ?? defaultValue
            )
        }
    }

    func test_categoryMeans_uniform_3() {
        let resps = makeResponses(values: [:], default: 3)
        let computed = SatisfactionSurveyDefinition.score(responses: resps)
        guard case let .satisfaction(means, _, _) = computed else { XCTFail(); return }
        for dim in WellnessDimension.allCases {
            XCTAssertEqual(means[dim], 3.0, accuracy: 0.0001)
        }
    }

    func test_topCategory_highest_unambiguous() {
        let values = [6:5, 7:5, 8:5, 12:5, 14:5]   // emotional
        let resps = makeResponses(values: values, default: 1)
        let computed = SatisfactionSurveyDefinition.score(responses: resps)
        guard case let .satisfaction(_, top, lowest) = computed else { XCTFail(); return }
        XCTAssertEqual(top, .emotional)
        XCTAssertNotEqual(lowest, .emotional)
    }

    func test_lowestCategory_picked_by_lowest_mean() {
        // Force occupational (Q18 only) to 1; others default 3
        let resps = makeResponses(values: [18: 1], default: 3)
        let computed = SatisfactionSurveyDefinition.score(responses: resps)
        guard case let .satisfaction(_, _, lowest) = computed else { XCTFail(); return }
        XCTAssertEqual(lowest, .occupational)
    }

    func test_top_and_lowest_priorityOrder_tieBreak() {
        // All equal → top and lowest both = priority-order winner = .physical
        // This is unusual but exercises the deterministic tie-break.
        let resps = makeResponses(values: [:], default: 3)
        let computed = SatisfactionSurveyDefinition.score(responses: resps)
        guard case let .satisfaction(_, top, lowest) = computed else { XCTFail(); return }
        XCTAssertEqual(top, .physical)
        XCTAssertEqual(lowest, .physical)   // documented behavior under uniform input
    }

    func test_definition_questionCount_is_32() {
        let def = SatisfactionSurveyDefinition.make()
        XCTAssertEqual(def.questions.count, 32)
        XCTAssertEqual(def.questions[0].key, "quest_survey_satisfaction_q01_text")
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement `SatisfactionSurveyDefinition`**

Create `Soulverse/Features/Quest/Surveys/Definitions/SatisfactionSurveyDefinition.swift`:

```swift
//
//  SatisfactionSurveyDefinition.swift
//  Soulverse
//
//  32 questions on a 5-point satisfaction scale. Reuses Importance's
//  8-category formulas per spec §4.3.
//

import Foundation

enum SatisfactionSurveyDefinition {

    /// Same formulas as Importance (spec §4.3).
    private static let categoryQuestionNumbers: [WellnessDimension: [Int]] = [
        .physical:      [2, 3, 4, 5, 15, 16],
        .emotional:     [6, 7, 8, 12, 14],
        .social:        [19, 20, 21],
        .intellectual:  [9, 10, 11, 27, 28],
        .spiritual:     [7, 8, 32],
        .occupational:  [18],
        .environmental: [22, 23, 30, 31],
        .financial:     [17, 24, 25, 26]
    ]

    static func make() -> SurveyDefinition {
        let questions = (1...32).map { n in
            SurveyDefinition.Question(
                key:    String(format: "quest_survey_satisfaction_q%02d_text", n),
                number: n
            )
        }
        return SurveyDefinition(
            surveyType:    .satisfactionCheckIn,
            dimension:     nil,
            questions:     questions,
            responseScale: .satisfaction,
            titleKey:      "quest_survey_satisfaction_title",
            score:         { responses in score(responses: responses) }
        )
    }

    static func score(responses: [SurveyResponse]) -> SurveyComputed {
        precondition(responses.count == 32, "Satisfaction survey requires 32 responses")
        var values: [Int: Int] = [:]
        for (idx, r) in responses.enumerated() { values[idx + 1] = r.value }

        var means: [WellnessDimension: Double] = [:]
        for (dim, qs) in categoryQuestionNumbers {
            let sum = qs.reduce(0) { $0 + (values[$1] ?? 0) }
            means[dim] = Double(sum) / Double(qs.count)
        }

        let top    = pick(means: means, comparator: >)
        let lowest = pick(means: means, comparator: <)

        return .satisfaction(
            categoryMeans:  means,
            topCategory:    top,
            lowestCategory: lowest
        )
    }

    /// Pick by extreme value with priority-order tie-break.
    private static func pick(
        means: [WellnessDimension: Double],
        comparator: (Double, Double) -> Bool
    ) -> WellnessDimension {
        let extreme = means.values.reduce(into: nil) { (acc: inout Double?, v) in
            if let cur = acc {
                acc = comparator(v, cur) ? v : cur
            } else {
                acc = v
            }
        } ?? 0
        // Filter to dimensions matching the extreme value, then take the first
        // in priority order.
        for dim in WellnessDimension.priorityOrder {
            if (means[dim] ?? 0) == extreme { return dim }
        }
        return .physical
    }
}
```

- [ ] **Step 4: Run, all 5 tests + Task 5 exhaustiveness tests now pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Definitions/SatisfactionSurveyDefinition.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/SatisfactionScoringTests.swift
git commit -m "feat(quest): add SatisfactionSurveyDefinition with top + lowest category scoring"
```

---

## Task 10: Add Importance survey question localizations (32 keys, en)

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

Add the 32 Importance Check-In question texts per the wellness assessment doc (Google Doc `19wH1834cHdwyIuFfT3YkXOHaXOrES78S`). Format: each user-facing string under one comment block.

- [ ] **Step 1: Append to `Soulverse/en.lproj/Localizable.strings`**

Append the following block at the end of `Soulverse/en.lproj/Localizable.strings`:

```objc
// MARK: - Quest survey: Importance Check-In (32 questions)

"quest_survey_importance_title" = "Importance Check-In";

"quest_importance_response_1" = "Not important";
"quest_importance_response_2" = "Slightly important";
"quest_importance_response_3" = "Moderately important";
"quest_importance_response_4" = "Very important";
"quest_importance_response_5" = "Extremely important";

"quest_survey_importance_q01_text" = "How important to you is your overall quality of life?";
"quest_survey_importance_q02_text" = "How important to you is maintaining a healthy body?";
"quest_survey_importance_q03_text" = "How important to you is regular physical activity?";
"quest_survey_importance_q04_text" = "How important to you is eating nourishing food?";
"quest_survey_importance_q05_text" = "How important to you is restful sleep?";
"quest_survey_importance_q06_text" = "How important to you is feeling emotionally balanced?";
"quest_survey_importance_q07_text" = "How important to you is having a sense of meaning in your life?";
"quest_survey_importance_q08_text" = "How important to you is connecting with something larger than yourself?";
"quest_survey_importance_q09_text" = "How important to you is learning new things?";
"quest_survey_importance_q10_text" = "How important to you is exercising your mind?";
"quest_survey_importance_q11_text" = "How important to you is being curious about the world?";
"quest_survey_importance_q12_text" = "How important to you is processing difficult emotions?";
"quest_survey_importance_q13_text" = "How important to you is having time to reflect?";
"quest_survey_importance_q14_text" = "How important to you is feeling joy in everyday moments?";
"quest_survey_importance_q15_text" = "How important to you is preventing illness through self-care?";
"quest_survey_importance_q16_text" = "How important to you is your physical comfort?";
"quest_survey_importance_q17_text" = "How important to you is having enough money for daily needs?";
"quest_survey_importance_q18_text" = "How important to you is finding fulfillment in your work?";
"quest_survey_importance_q19_text" = "How important to you is feeling close to friends?";
"quest_survey_importance_q20_text" = "How important to you is having strong family bonds?";
"quest_survey_importance_q21_text" = "How important to you is being part of a community?";
"quest_survey_importance_q22_text" = "How important to you is living in a clean and safe space?";
"quest_survey_importance_q23_text" = "How important to you is spending time in nature?";
"quest_survey_importance_q24_text" = "How important to you is saving for the future?";
"quest_survey_importance_q25_text" = "How important to you is feeling financially secure?";
"quest_survey_importance_q26_text" = "How important to you is making informed money decisions?";
"quest_survey_importance_q27_text" = "How important to you is reading or studying regularly?";
"quest_survey_importance_q28_text" = "How important to you is having intellectually stimulating conversations?";
"quest_survey_importance_q29_text" = "How important to you is your reputation among peers?";
"quest_survey_importance_q30_text" = "How important to you is the aesthetic of where you spend your time?";
"quest_survey_importance_q31_text" = "How important to you is reducing your impact on the environment?";
"quest_survey_importance_q32_text" = "How important to you is exploring spiritual or philosophical questions?";
```

- [ ] **Step 2: Verify build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add Importance Check-In en strings (32 questions + scale)"
```

---

## Task 11: Add Satisfaction survey question localizations (32 keys, en)

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

- [ ] **Step 1: Append to `Soulverse/en.lproj/Localizable.strings`**

```objc
// MARK: - Quest survey: Satisfaction Check-In (32 questions)

"quest_survey_satisfaction_title" = "Satisfaction Check-In";

"quest_satisfaction_response_1" = "Very dissatisfied";
"quest_satisfaction_response_2" = "Slightly dissatisfied";
"quest_satisfaction_response_3" = "Neutral";
"quest_satisfaction_response_4" = "Slightly satisfied";
"quest_satisfaction_response_5" = "Very satisfied";

"quest_survey_satisfaction_q01_text" = "How satisfied are you with your overall quality of life?";
"quest_survey_satisfaction_q02_text" = "How satisfied are you with the health of your body?";
"quest_survey_satisfaction_q03_text" = "How satisfied are you with your level of physical activity?";
"quest_survey_satisfaction_q04_text" = "How satisfied are you with how you eat?";
"quest_survey_satisfaction_q05_text" = "How satisfied are you with the quality of your sleep?";
"quest_survey_satisfaction_q06_text" = "How satisfied are you with how you handle your emotions?";
"quest_survey_satisfaction_q07_text" = "How satisfied are you with the meaning you find in life?";
"quest_survey_satisfaction_q08_text" = "How satisfied are you with your sense of connection to something larger than yourself?";
"quest_survey_satisfaction_q09_text" = "How satisfied are you with how much you're learning?";
"quest_survey_satisfaction_q10_text" = "How satisfied are you with how you exercise your mind?";
"quest_survey_satisfaction_q11_text" = "How satisfied are you with how curious you stay?";
"quest_survey_satisfaction_q12_text" = "How satisfied are you with how you process difficult emotions?";
"quest_survey_satisfaction_q13_text" = "How satisfied are you with how much time you spend in reflection?";
"quest_survey_satisfaction_q14_text" = "How satisfied are you with the joy you find in everyday moments?";
"quest_survey_satisfaction_q15_text" = "How satisfied are you with how you take care of your body to prevent illness?";
"quest_survey_satisfaction_q16_text" = "How satisfied are you with your physical comfort?";
"quest_survey_satisfaction_q17_text" = "How satisfied are you with your ability to meet daily needs?";
"quest_survey_satisfaction_q18_text" = "How satisfied are you with the fulfillment you find in your work?";
"quest_survey_satisfaction_q19_text" = "How satisfied are you with your closeness to friends?";
"quest_survey_satisfaction_q20_text" = "How satisfied are you with the strength of your family bonds?";
"quest_survey_satisfaction_q21_text" = "How satisfied are you with feeling part of a community?";
"quest_survey_satisfaction_q22_text" = "How satisfied are you with the cleanliness and safety of your space?";
"quest_survey_satisfaction_q23_text" = "How satisfied are you with how much time you spend in nature?";
"quest_survey_satisfaction_q24_text" = "How satisfied are you with what you're saving for the future?";
"quest_survey_satisfaction_q25_text" = "How satisfied are you with your sense of financial security?";
"quest_survey_satisfaction_q26_text" = "How satisfied are you with the financial decisions you make?";
"quest_survey_satisfaction_q27_text" = "How satisfied are you with how often you read or study?";
"quest_survey_satisfaction_q28_text" = "How satisfied are you with the intellectual conversations you have?";
"quest_survey_satisfaction_q29_text" = "How satisfied are you with how peers see you?";
"quest_survey_satisfaction_q30_text" = "How satisfied are you with the aesthetic of where you spend your time?";
"quest_survey_satisfaction_q31_text" = "How satisfied are you with how you reduce your environmental impact?";
"quest_survey_satisfaction_q32_text" = "How satisfied are you with how you explore spiritual or philosophical questions?";
```

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add Satisfaction Check-In en strings (32 questions + scale)"
```

---

## Task 12: Add 8-Dim survey question localizations (80 keys, en)

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

The 8-Dim survey has 10 questions per dimension × 8 dimensions = **80 question texts**. Localization key list (full enumeration so engineer doesn't guess):

```
quest_survey_8dim_physical_q01_text       through  quest_survey_8dim_physical_q10_text
quest_survey_8dim_emotional_q01_text      through  quest_survey_8dim_emotional_q10_text
quest_survey_8dim_social_q01_text         through  quest_survey_8dim_social_q10_text
quest_survey_8dim_intellectual_q01_text   through  quest_survey_8dim_intellectual_q10_text
quest_survey_8dim_spiritual_q01_text      through  quest_survey_8dim_spiritual_q10_text
quest_survey_8dim_occupational_q01_text   through  quest_survey_8dim_occupational_q10_text
quest_survey_8dim_environmental_q01_text  through  quest_survey_8dim_environmental_q10_text
quest_survey_8dim_financial_q01_text      through  quest_survey_8dim_financial_q10_text
```

Plus per-dimension titles (8): `quest_survey_8dim_<dim>_title` for each dim. Plus the shared agreement scale (5):

```
quest_survey_response_1 = "Not true for me"
quest_survey_response_2 = "Slightly true for me"
quest_survey_response_3 = "Sometimes true for me"
quest_survey_response_4 = "Often true for me"
quest_survey_response_5 = "Very true for me"
```

- [ ] **Step 1: Append to `Soulverse/en.lproj/Localizable.strings`**

Add the shared agreement/frequency scale plus titles plus all 80 question keys. **Representative emotional sample shown below (5 of 10 questions); the other 75 follow the same pattern from the wellness doc.** Engineer must populate all 80 from the doc.

```objc
// MARK: - Quest survey: shared 5-point agreement / frequency scale

"quest_survey_response_1" = "Not true for me";
"quest_survey_response_2" = "Slightly true for me";
"quest_survey_response_3" = "Sometimes true for me";
"quest_survey_response_4" = "Often true for me";
"quest_survey_response_5" = "Very true for me";

// MARK: - Quest survey: 8-Dim — per-dimension titles

"quest_survey_8dim_physical_title"      = "Physical Wellness";
"quest_survey_8dim_emotional_title"     = "Emotional Wellness";
"quest_survey_8dim_social_title"        = "Social Wellness";
"quest_survey_8dim_intellectual_title"  = "Intellectual Wellness";
"quest_survey_8dim_spiritual_title"     = "Spiritual Wellness";
"quest_survey_8dim_occupational_title"  = "Occupational Wellness";
"quest_survey_8dim_environmental_title" = "Environmental Wellness";
"quest_survey_8dim_financial_title"     = "Financial Wellness";

// MARK: - Quest survey: 8-Dim — Emotional (10 questions)
//   [Sample of 5 below; engineer adds q06-q10 from wellness doc]

"quest_survey_8dim_emotional_q01_text" = "I notice physical sensations in my body when I feel emotion.";
"quest_survey_8dim_emotional_q02_text" = "I can name what I'm feeling, even when it's complicated.";
"quest_survey_8dim_emotional_q03_text" = "I let myself feel difficult emotions without pushing them away.";
"quest_survey_8dim_emotional_q04_text" = "I take time to understand why I'm reacting the way I am.";
"quest_survey_8dim_emotional_q05_text" = "I respond to my emotions with kindness rather than judgment.";
// q06-q10: populated from wellness doc emotional section

// MARK: - Quest survey: 8-Dim — Physical (10 questions)
//   keys quest_survey_8dim_physical_q01_text through ..._q10_text — populate from wellness doc

// MARK: - Quest survey: 8-Dim — Social (10 questions)
//   keys quest_survey_8dim_social_q01_text through ..._q10_text — populate from wellness doc

// MARK: - Quest survey: 8-Dim — Intellectual (10 questions)
//   keys quest_survey_8dim_intellectual_q01_text through ..._q10_text — populate from wellness doc

// MARK: - Quest survey: 8-Dim — Spiritual (10 questions)
//   keys quest_survey_8dim_spiritual_q01_text through ..._q10_text — populate from wellness doc

// MARK: - Quest survey: 8-Dim — Occupational (10 questions)
//   keys quest_survey_8dim_occupational_q01_text through ..._q10_text — populate from wellness doc

// MARK: - Quest survey: 8-Dim — Environmental (10 questions)
//   keys quest_survey_8dim_environmental_q01_text through ..._q10_text — populate from wellness doc

// MARK: - Quest survey: 8-Dim — Financial (10 questions)
//   keys quest_survey_8dim_financial_q01_text through ..._q10_text — populate from wellness doc
```

> **IMPORTANT:** Replace each `// keys ... — populate from wellness doc` placeholder with the actual 10 entries before merge. **All 80 keys must be present** in the en file when this task closes. The placeholder comments are scaffolding only.

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add 8-Dim en strings (80 questions, 8 titles, agreement scale)"
```

---

## Task 13: Add 8-Dim stage labels & messages (48 keys, en)

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

For each of 8 dimensions × 3 stages × 2 fields (label + message) = 48 keys. Stage names per dimension are listed in design doc §9 — friendly, not clinical (e.g., physical: "Slow-Burner / Regular Pacer / Strong Mover").

Full key list:

```
quest_stage_8dim_physical_1_label,      quest_stage_8dim_physical_1_message
quest_stage_8dim_physical_2_label,      quest_stage_8dim_physical_2_message
quest_stage_8dim_physical_3_label,      quest_stage_8dim_physical_3_message
quest_stage_8dim_emotional_1_label,     quest_stage_8dim_emotional_1_message
quest_stage_8dim_emotional_2_label,     quest_stage_8dim_emotional_2_message
quest_stage_8dim_emotional_3_label,     quest_stage_8dim_emotional_3_message
quest_stage_8dim_social_1_label,        quest_stage_8dim_social_1_message
quest_stage_8dim_social_2_label,        quest_stage_8dim_social_2_message
quest_stage_8dim_social_3_label,        quest_stage_8dim_social_3_message
quest_stage_8dim_intellectual_1_label,  quest_stage_8dim_intellectual_1_message
quest_stage_8dim_intellectual_2_label,  quest_stage_8dim_intellectual_2_message
quest_stage_8dim_intellectual_3_label,  quest_stage_8dim_intellectual_3_message
quest_stage_8dim_spiritual_1_label,     quest_stage_8dim_spiritual_1_message
quest_stage_8dim_spiritual_2_label,     quest_stage_8dim_spiritual_2_message
quest_stage_8dim_spiritual_3_label,     quest_stage_8dim_spiritual_3_message
quest_stage_8dim_occupational_1_label,  quest_stage_8dim_occupational_1_message
quest_stage_8dim_occupational_2_label,  quest_stage_8dim_occupational_2_message
quest_stage_8dim_occupational_3_label,  quest_stage_8dim_occupational_3_message
quest_stage_8dim_environmental_1_label, quest_stage_8dim_environmental_1_message
quest_stage_8dim_environmental_2_label, quest_stage_8dim_environmental_2_message
quest_stage_8dim_environmental_3_label, quest_stage_8dim_environmental_3_message
quest_stage_8dim_financial_1_label,     quest_stage_8dim_financial_1_message
quest_stage_8dim_financial_2_label,     quest_stage_8dim_financial_2_message
quest_stage_8dim_financial_3_label,     quest_stage_8dim_financial_3_message
```

- [ ] **Step 1: Append to en strings**

Representative emotional sample shown below; the other 21 dimension/stage rows follow the same pattern with copy from the wellness doc:

```objc
// MARK: - Quest survey: 8-Dim stage labels & messages (48 keys total)

"quest_stage_8dim_emotional_1_label"   = "Quiet Embers";
"quest_stage_8dim_emotional_1_message" = "Your emotional awareness is just starting to flicker. Each check-in adds a little warmth.";
"quest_stage_8dim_emotional_2_label"   = "Steady Flame";
"quest_stage_8dim_emotional_2_message" = "You're tuning in to your feelings with growing consistency. Keep noticing.";
"quest_stage_8dim_emotional_3_label"   = "Bright Fire";
"quest_stage_8dim_emotional_3_message" = "Your emotional fluency is strong. You move through feelings with skill and grace.";

// quest_stage_8dim_physical_{1,2,3}_label  / _message            — populate from wellness doc
// quest_stage_8dim_social_{1,2,3}_label    / _message            — populate from wellness doc
// quest_stage_8dim_intellectual_{1,2,3}_label / _message         — populate from wellness doc
// quest_stage_8dim_spiritual_{1,2,3}_label / _message            — populate from wellness doc
// quest_stage_8dim_occupational_{1,2,3}_label / _message         — populate from wellness doc
// quest_stage_8dim_environmental_{1,2,3}_label / _message        — populate from wellness doc
// quest_stage_8dim_financial_{1,2,3}_label / _message            — populate from wellness doc
```

> **IMPORTANT:** Replace each placeholder line with the 6 entries (3 stages × label + message) before merge. **All 48 keys** must be in the en file when this task closes.

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add 8-Dim stage labels & messages (48 keys)"
```

---

## Task 14: Add State-of-Change question localizations + stage labels (15 + 10 keys, en)

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

Friendly stage labels are locked per spec §9.4: Considering / Planning / Preparing / Doing / Sustaining (clinical names not surfaced).

Full key list:
- 15 questions: `quest_survey_soc_q01_text` through `quest_survey_soc_q15_text`
- Title: `quest_survey_soc_title`
- 10 stage strings: `quest_stage_soc_1_label`, `_message`, ..., `quest_stage_soc_5_label`, `_message`

- [ ] **Step 1: Append to en strings**

```objc
// MARK: - Quest survey: State-of-Change (15 questions)

"quest_survey_soc_title" = "Where you are right now";

"quest_survey_soc_q01_text" = "I took steps to prevent myself from slipping back into old patterns.";
"quest_survey_soc_q02_text" = "I don't feel like I need to change anything right now.";
"quest_survey_soc_q03_text" = "I made concrete progress toward a change this week.";
"quest_survey_soc_q04_text" = "I've been thinking about wanting to change something, but haven't acted yet.";
"quest_survey_soc_q05_text" = "I kept up the new habits I've been working on.";
"quest_survey_soc_q06_text" = "I made a specific plan for how I'll start changing.";
"quest_survey_soc_q07_text" = "I tried something new this week related to my change.";
"quest_survey_soc_q08_text" = "I followed through on a small action toward my change.";
"quest_survey_soc_q09_text" = "Other people seem more concerned about my behavior than I am.";
"quest_survey_soc_q10_text" = "I gathered information about how to make the change I want.";
"quest_survey_soc_q11_text" = "I'm aware that I should change, but I'm not ready yet.";
"quest_survey_soc_q12_text" = "I told someone close to me about my plan to change.";
"quest_survey_soc_q13_text" = "I returned to my new habit even after a setback.";
"quest_survey_soc_q14_text" = "I'm weighing whether the change is worth the effort.";
"quest_survey_soc_q15_text" = "Honestly, I don't see a problem that needs solving.";

// MARK: - Quest survey: State-of-Change stage labels & messages

"quest_stage_soc_1_label"   = "Considering";
"quest_stage_soc_1_message" = "You're sitting with the question of whether change matters right now. That's a real stage — there's no rush.";
"quest_stage_soc_2_label"   = "Planning";
"quest_stage_soc_2_message" = "You're sketching out what change could look like. Curiosity is doing the work.";
"quest_stage_soc_3_label"   = "Preparing";
"quest_stage_soc_3_message" = "You're laying the groundwork. Small commitments are stacking up.";
"quest_stage_soc_4_label"   = "Doing";
"quest_stage_soc_4_message" = "You're in the practice now. Each day is a vote for the new pattern.";
"quest_stage_soc_5_label"   = "Sustaining";
"quest_stage_soc_5_message" = "You've made the change part of your life. The work now is to protect it.";
```

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add State-of-Change en strings (15 questions + 5 stage pairs)"
```

---

## Task 15: Add miscellaneous Quest survey UI strings (en)

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

Misc UI strings the generic SurveyViewController and SurveyResultViewController need. Plus dimension labels (8) used in result views.

Full key list:
```
quest_dimension_<dim>_label              (× 8 dimensions)
quest_survey_progress_format             ("%d of %d")
quest_survey_next_button
quest_survey_back_button
quest_survey_submit_button
quest_survey_done_button
quest_survey_required_response_alert_title
quest_survey_required_response_alert_message
quest_survey_submitting
quest_survey_submission_failed_title
quest_survey_submission_failed_message
quest_survey_result_first_time_header
quest_survey_result_followup_header
quest_survey_result_done_button
quest_survey_result_top_focus_format     ("Your top priority is %@.")
quest_survey_result_lowest_focus_format
quest_survey_result_stage_format         ("You're in stage %d: %@")
quest_survey_result_readiness_index_format
```

- [ ] **Step 1: Append to en strings**

```objc
// MARK: - Quest dimension labels (used by survey result views)

"quest_dimension_physical_label"      = "Physical";
"quest_dimension_emotional_label"     = "Emotional";
"quest_dimension_social_label"        = "Social";
"quest_dimension_intellectual_label"  = "Intellectual";
"quest_dimension_spiritual_label"     = "Spiritual";
"quest_dimension_occupational_label"  = "Occupational";
"quest_dimension_environmental_label" = "Environmental";
"quest_dimension_financial_label"     = "Financial";

// MARK: - Quest survey: generic UI

"quest_survey_progress_format" = "%d of %d";
"quest_survey_next_button"     = "Next";
"quest_survey_back_button"     = "Back";
"quest_survey_submit_button"   = "Submit";
"quest_survey_done_button"     = "Done";

"quest_survey_required_response_alert_title"   = "Please choose a response";
"quest_survey_required_response_alert_message" = "Tap one of the options to continue.";

"quest_survey_submitting"               = "Submitting…";
"quest_survey_submission_failed_title"  = "Submission failed";
"quest_survey_submission_failed_message" = "We couldn't save your responses. Check your connection and try again.";

// MARK: - Quest survey: result view

"quest_survey_result_first_time_header"      = "Your first reflection";
"quest_survey_result_followup_header"        = "Your reflection";
"quest_survey_result_done_button"            = "Done";
"quest_survey_result_top_focus_format"       = "Your top priority is %@.";
"quest_survey_result_lowest_focus_format"    = "Where you'd like more is %@.";
"quest_survey_result_stage_format"           = "You're in stage %d: %@";
"quest_survey_result_readiness_index_format" = "Readiness index: %.1f";
```

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add generic survey UI + dimension label en strings"
```

---

## Task 16: `SurveyServiceProtocol` + `FirestoreSurveyService` write-once writer

**Files:**
- Create: `Soulverse/Shared/Service/QuestService/SurveyServiceProtocol.swift`
- Create: `Soulverse/Shared/Service/QuestService/FirestoreSurveyService.swift`
- Modify: `Soulverse/Shared/Service/FirestoreSchema.swift`

Add `survey_submissions` to `FirestoreCollection` and ship a service that writes one submission and queries recent ones.

- [ ] **Step 1: Add the collection name**

Edit `Soulverse/Shared/Service/FirestoreSchema.swift`. Inside the `FirestoreCollection` enum, add:

```swift
/// Subcollection for survey submissions under a user.
/// Path: `users/{uid}/survey_submissions/{submissionId}`
/// Write-once; server-stamped submittedAt.
static let surveySubmissions = "survey_submissions"

/// Aggregate quest_state document under a user.
/// Path: `users/{uid}/quest_state/state`
/// (single-document collection; doc ID is "state".)
static let questState = "quest_state"
```

- [ ] **Step 2: Write the protocol**

Create `Soulverse/Shared/Service/QuestService/SurveyServiceProtocol.swift`:

```swift
//
//  SurveyServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol SurveyServiceProtocol {

    /// Write a survey submission. Server stamps `submittedAt` via FieldValue.serverTimestamp.
    /// Write-once: rules reject any update or delete on the resulting doc.
    func submitSurvey(
        uid: String,
        payload: SurveySubmissionPayload,
        completion: @escaping (Result<String, Error>) -> Void
    )

    /// Fetch the user's most recent N submissions ordered by submittedAt desc.
    func fetchRecentSubmissions(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[SurveySubmissionRecord], Error>) -> Void
    )
}

/// Read-side projection of a stored submission. Trimmed to what the
/// RecentResultCard and SurveyResultViewController need to render.
struct SurveySubmissionRecord {
    let submissionId: String
    let surveyType: SurveyType
    let submittedAt: Date
    let dimension: WellnessDimension?
    let computed: SurveyComputed
}
```

- [ ] **Step 3: Implement the service**

Create `Soulverse/Shared/Service/QuestService/FirestoreSurveyService.swift`:

```swift
//
//  FirestoreSurveyService.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

final class FirestoreSurveyService: SurveyServiceProtocol {

    static let shared = FirestoreSurveyService()

    private let db = Firestore.firestore()

    private init() {}

    enum ServiceError: LocalizedError {
        case userNotLoggedIn
        case malformedDocument

        var errorDescription: String? {
            switch self {
            case .userNotLoggedIn:    return "User is not logged in"
            case .malformedDocument:  return "Submission document is malformed"
            }
        }
    }

    private func collection(uid: String) -> CollectionReference {
        return db.collection(FirestoreCollection.users)
            .document(uid)
            .collection(FirestoreCollection.surveySubmissions)
    }

    // MARK: - Submit

    func submitSurvey(
        uid: String,
        payload: SurveySubmissionPayload,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let docRef = collection(uid: uid).document(payload.submissionId)

        var fields: [String: Any] = [
            "submissionId":          payload.submissionId,
            "surveyType":            payload.surveyType.rawValue,
            "submittedAt":           FieldValue.serverTimestamp(),
            "appVersion":            payload.appVersion,
            "submittedFromQuestDay": payload.submittedFromQuestDay,
            "payload":               buildPayloadDict(payload: payload)
        ]
        if let dim = payload.dimension {
            // Hoist dimension into the top-level submission doc for cheap
            // listing-side filtering (some result views key by dimension).
            fields["dimension"] = dim.rawValue
        }

        docRef.setData(fields) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(docRef.documentID))
            }
        }
    }

    private func buildPayloadDict(payload: SurveySubmissionPayload) -> [String: Any] {
        var p: [String: Any] = [
            "responses": payload.responses.map { $0.firestoreDict },
            "computed":  payload.computed.firestoreDict
        ]
        if let dim = payload.dimension {
            p["dimension"] = dim.rawValue
        }
        return p
    }

    // MARK: - Fetch recent

    func fetchRecentSubmissions(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[SurveySubmissionRecord], Error>) -> Void
    ) {
        collection(uid: uid)
            .order(by: "submittedAt", descending: true)
            .limit(to: limit)
            .getDocuments { snap, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                let records = (snap?.documents ?? []).compactMap { doc -> SurveySubmissionRecord? in
                    Self.decode(doc: doc)
                }
                completion(.success(records))
            }
    }

    /// Decoder. Returns nil for unknown surveyType or missing computed payload.
    private static func decode(doc: QueryDocumentSnapshot) -> SurveySubmissionRecord? {
        let data = doc.data()
        guard
            let typeRaw = data["surveyType"] as? String,
            let type    = SurveyType(rawValue: typeRaw),
            let ts      = data["submittedAt"] as? Timestamp,
            let payload = data["payload"] as? [String: Any]
        else { return nil }

        let dim: WellnessDimension? = (data["dimension"] as? String)
            .flatMap(WellnessDimension.init(rawValue:))
        guard let computed = decodeComputed(type: type, dimension: dim, payload: payload) else {
            return nil
        }
        return SurveySubmissionRecord(
            submissionId: doc.documentID,
            surveyType:   type,
            submittedAt:  ts.dateValue(),
            dimension:    dim,
            computed:     computed
        )
    }

    private static func decodeComputed(
        type: SurveyType,
        dimension: WellnessDimension?,
        payload: [String: Any]
    ) -> SurveyComputed? {
        guard let computed = payload["computed"] as? [String: Any] else { return nil }
        switch type {
        case .importanceCheckIn:
            guard
                let meansRaw = computed["categoryMeans"] as? [String: Double],
                let topRaw   = computed["topCategory"] as? String,
                let top      = WellnessDimension(rawValue: topRaw),
                let level    = computed["tieBreakerLevel"] as? Int
            else { return nil }
            return .importance(
                categoryMeans:   parseMeans(meansRaw),
                topCategory:     top,
                tieBreakerLevel: level
            )

        case .eightDim:
            guard
                let dim       = dimension,
                let total     = computed["totalScore"] as? Int,
                let mean      = computed["meanScore"] as? Double,
                let stage     = computed["stage"] as? Int,
                let stageKey  = computed["stageKey"] as? String,
                let messageKey = computed["messageKey"] as? String
            else { return nil }
            return .eightDim(
                dimension:  dim,
                totalScore: total,
                meanScore:  mean,
                stage:      stage,
                stageKey:   stageKey,
                messageKey: messageKey
            )

        case .stateOfChange:
            guard
                let dim       = dimension,
                let meansDict = computed["substageMeans"] as? [String: Double],
                let readiness = computed["readinessIndex"] as? Double,
                let stage     = computed["stage"] as? Int,
                let stageKey  = computed["stageKey"] as? String,
                let stageMsg  = computed["stageMessageKey"] as? String
            else { return nil }
            let means = SurveyComputed.SubstageMeans(
                precontemplation: meansDict["precontemplation"] ?? 0,
                contemplation:    meansDict["contemplation"] ?? 0,
                preparation:      meansDict["preparation"] ?? 0,
                action:           meansDict["action"] ?? 0,
                maintenance:      meansDict["maintenance"] ?? 0
            )
            return .stateOfChange(
                dimension:       dim,
                substageMeans:   means,
                readinessIndex:  readiness,
                stage:           stage,
                stageKey:        stageKey,
                stageMessageKey: stageMsg
            )

        case .satisfactionCheckIn:
            guard
                let meansRaw = computed["categoryMeans"] as? [String: Double],
                let topRaw   = computed["topCategory"] as? String,
                let top      = WellnessDimension(rawValue: topRaw),
                let lowRaw   = computed["lowestCategory"] as? String,
                let lowest   = WellnessDimension(rawValue: lowRaw)
            else { return nil }
            return .satisfaction(
                categoryMeans:  parseMeans(meansRaw),
                topCategory:    top,
                lowestCategory: lowest
            )
        }
    }

    private static func parseMeans(_ raw: [String: Double]) -> [WellnessDimension: Double] {
        var out: [WellnessDimension: Double] = [:]
        for (k, v) in raw {
            if let dim = WellnessDimension(rawValue: k) { out[dim] = v }
        }
        return out
    }
}
```

- [ ] **Step 4: Build verify**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Shared/Service/FirestoreSchema.swift \
        Soulverse/Shared/Service/QuestService/
git commit -m "feat(quest): add FirestoreSurveyService for write-once submissions and recent reads"
```

---

## Task 17: `MockSurveyService` for tests

**Files:**
- Create: `SoulverseTests/Mocks/Features/Quest/MockSurveyService.swift`

Provides deterministic capture of submissions so the controller-level tests in Tasks 19+ can verify what would be written without hitting Firestore.

- [ ] **Step 1: Implement the mock**

Create `SoulverseTests/Mocks/Features/Quest/MockSurveyService.swift`:

```swift
//
//  MockSurveyService.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class MockSurveyService: SurveyServiceProtocol {

    var submitInvocations: [(uid: String, payload: SurveySubmissionPayload)] = []
    var submitResult: Result<String, Error> = .success("mock-submission-id")

    var fetchInvocations: [(uid: String, limit: Int)] = []
    var fetchResult: Result<[SurveySubmissionRecord], Error> = .success([])

    func submitSurvey(
        uid: String,
        payload: SurveySubmissionPayload,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        submitInvocations.append((uid: uid, payload: payload))
        completion(submitResult)
    }

    func fetchRecentSubmissions(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[SurveySubmissionRecord], Error>) -> Void
    ) {
        fetchInvocations.append((uid: uid, limit: limit))
        completion(fetchResult)
    }
}
```

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add SoulverseTests/Mocks/Features/Quest/MockSurveyService.swift
git commit -m "test(quest): add MockSurveyService for survey infrastructure tests"
```

---

## Task 18: `SurveyResponseScaleView` — 5-button vertical scale (presentation choice)

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Views/SurveyResponseScaleView.swift`

> **Question rendering decision:** present **one question per screen** with the 5 response options stacked vertically. Rationale:
> - Long surveys (32 / 80 / 15 questions) on small screens benefit from focused presentation.
> - Each tap advances; user always knows where they are via the progress bar at the top.
> - Vertical layout makes the scale legible for long option text ("Slightly important", "Sometimes true for me").
> - Aligns with mobile-design HIG: avoid horizontal scrolling.

The view exposes a closure `onSelect: (Int) -> Void` and a current `selectedValue` state.

- [ ] **Step 1: Implement the view**

Create `Soulverse/Features/Quest/Surveys/Views/SurveyResponseScaleView.swift`:

```swift
//
//  SurveyResponseScaleView.swift
//  Soulverse
//
//  Vertical 5-option response scale. Reused across all 4 survey types
//  via the ResponseScale enum's localization keys.
//

import UIKit
import SnapKit

final class SurveyResponseScaleView: UIView {

    private enum Layout {
        static let optionHeight: CGFloat = ViewComponentConstants.actionButtonHeight
        static let optionSpacing: CGFloat = 12
        static let optionCornerRadius: CGFloat = 12
        static let optionTitleHorizontalInset: CGFloat = 16
    }

    private let stack = UIStackView()
    private var optionButtons: [UIButton] = []

    var onSelect: ((Int) -> Void)?
    private(set) var selectedValue: Int?

    init(scale: ResponseScale) {
        super.init(frame: .zero)
        setupStack()
        configure(scale: scale)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func setupStack() {
        stack.axis = .vertical
        stack.spacing = Layout.optionSpacing
        stack.alignment = .fill
        stack.distribution = .fill
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configure(scale: ResponseScale) {
        for (index, key) in scale.optionKeys.enumerated() {
            let value = index + 1
            let button = makeOptionButton(titleKey: key, value: value)
            stack.addArrangedSubview(button)
            optionButtons.append(button)
            button.snp.makeConstraints { make in
                make.height.equalTo(Layout.optionHeight)
            }
        }
    }

    private func makeOptionButton(titleKey: String, value: Int) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(NSLocalizedString(titleKey, comment: ""), for: .normal)
        b.layer.cornerRadius = Layout.optionCornerRadius
        b.contentEdgeInsets = UIEdgeInsets(
            top: 0, left: Layout.optionTitleHorizontalInset,
            bottom: 0, right: Layout.optionTitleHorizontalInset
        )
        b.tag = value
        b.addTarget(self, action: #selector(didTapOption(_:)), for: .touchUpInside)
        applyUnselectedAppearance(b)
        return b
    }

    @objc private func didTapOption(_ sender: UIButton) {
        let value = sender.tag
        selectedValue = value
        for button in optionButtons {
            if button.tag == value {
                applySelectedAppearance(button)
            } else {
                applyUnselectedAppearance(button)
            }
        }
        onSelect?(value)
    }

    func reset() {
        selectedValue = nil
        for button in optionButtons {
            applyUnselectedAppearance(button)
        }
    }

    func setSelected(value: Int) {
        for button in optionButtons {
            if button.tag == value {
                applySelectedAppearance(button)
                selectedValue = value
            } else {
                applyUnselectedAppearance(button)
            }
        }
    }

    private func applySelectedAppearance(_ button: UIButton) {
        button.backgroundColor = .themeButtonPrimaryBackground
        button.setTitleColor(.themeButtonPrimaryText, for: .normal)
    }

    private func applyUnselectedAppearance(_ button: UIButton) {
        button.backgroundColor = .themeButtonSecondaryBackground
        button.setTitleColor(.themeTextPrimary, for: .normal)
    }
}
```

> **Theme-token note:** if `.themeButtonSecondaryBackground` is not yet defined in `Soulverse/Shared/Theme/Theme.swift`, add it during this task using the same scheme as the existing primary/disabled tokens. **Do not** fall back to hardcoded colors.

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Views/SurveyResponseScaleView.swift
git commit -m "feat(quest): add SurveyResponseScaleView (vertical 5-option scale)"
```

---

## Task 19: `SurveyQuestionCardView` + `SurveyProgressBar`

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Views/SurveyQuestionCardView.swift`
- Create: `Soulverse/Features/Quest/Surveys/Views/SurveyProgressBar.swift`

`SurveyQuestionCardView` composes a question text label + a `SurveyResponseScaleView`. `SurveyProgressBar` is a simple "N of M" bar at the top of the survey screen.

- [ ] **Step 1: Implement progress bar**

Create `Soulverse/Features/Quest/Surveys/Views/SurveyProgressBar.swift`:

```swift
//
//  SurveyProgressBar.swift
//  Soulverse
//

import UIKit
import SnapKit

final class SurveyProgressBar: UIView {

    private enum Layout {
        static let barHeight: CGFloat = 4
        static let labelSpacing: CGFloat = 6
    }

    private let label = UILabel()
    private let trackView = UIView()
    private let fillView = UIView()
    private var fillWidthConstraint: Constraint?

    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(current: Int, total: Int) {
        let format = NSLocalizedString("quest_survey_progress_format", comment: "")
        label.text = String(format: format, current, total)
        let ratio = total > 0 ? CGFloat(current) / CGFloat(total) : 0
        layoutIfNeeded()
        let fullWidth = trackView.bounds.width
        fillWidthConstraint?.update(offset: fullWidth * ratio)
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    private func setup() {
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .themeTextSecondary
        addSubview(label)
        label.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        trackView.backgroundColor = .themeBackgroundSecondary
        trackView.layer.cornerRadius = Layout.barHeight / 2
        addSubview(trackView)
        trackView.snp.makeConstraints { make in
            make.top.equalTo(label.snp.bottom).offset(Layout.labelSpacing)
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(Layout.barHeight)
        }

        fillView.backgroundColor = .themeAccent
        fillView.layer.cornerRadius = Layout.barHeight / 2
        trackView.addSubview(fillView)
        fillView.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            self.fillWidthConstraint = make.width.equalTo(0).constraint
        }
    }
}
```

- [ ] **Step 2: Implement question card**

Create `Soulverse/Features/Quest/Surveys/Views/SurveyQuestionCardView.swift`:

```swift
//
//  SurveyQuestionCardView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class SurveyQuestionCardView: UIView {

    private enum Layout {
        static let horizontalPadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let questionTopSpacing: CGFloat = 32
        static let scaleTopSpacing: CGFloat = 24
    }

    private let questionLabel = UILabel()
    private let scaleView: SurveyResponseScaleView

    var onSelect: ((Int) -> Void)? {
        get { scaleView.onSelect }
        set { scaleView.onSelect = newValue }
    }

    var selectedValue: Int? { scaleView.selectedValue }

    init(scale: ResponseScale) {
        self.scaleView = SurveyResponseScaleView(scale: scale)
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func setQuestion(_ text: String) {
        questionLabel.text = text
        scaleView.reset()
    }

    func setSelected(value: Int?) {
        if let v = value { scaleView.setSelected(value: v) }
        else { scaleView.reset() }
    }

    private func setup() {
        backgroundColor = .clear

        questionLabel.font = .preferredFont(forTextStyle: .title2)
        questionLabel.textColor = .themeTextPrimary
        questionLabel.numberOfLines = 0
        addSubview(questionLabel)
        questionLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.questionTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        addSubview(scaleView)
        scaleView.snp.makeConstraints { make in
            make.top.equalTo(questionLabel.snp.bottom).offset(Layout.scaleTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
}
```

- [ ] **Step 3: Build verify**

- [ ] **Step 4: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Views/SurveyProgressBar.swift \
        Soulverse/Features/Quest/Surveys/Views/SurveyQuestionCardView.swift
git commit -m "feat(quest): add SurveyQuestionCardView and SurveyProgressBar"
```

---

## Task 20: Generic `SurveyViewController`

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Views/SurveyViewController.swift`
- Create: `SoulverseTests/Tests/Features/Quest/Surveys/SurveyViewControllerTests.swift`

The generic controller drives any `SurveyDefinition`: renders questions one at a time, accumulates responses, validates completeness, scores via the definition's closure, and submits via the injected `SurveyServiceProtocol`. On success, it pushes `SurveyResultViewController`.

**Submitted-from-quest-day source:** Plan 5 will inject the user's current `distinctCheckInDays` from `quest_state`. For this plan, accept it as a constructor parameter (Plan 5 wires it in).

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Features/Quest/Surveys/SurveyViewControllerTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class SurveyViewControllerTests: XCTestCase {

    func test_submit_called_after_all_responses_collected() {
        let mock = MockSurveyService()
        let definition = SurveyDefinition.lookup(.importanceCheckIn, dimension: nil)!
        let vc = SurveyViewController(
            definition: definition,
            uid: "test-uid",
            submittedFromQuestDay: 7,
            appVersion: "1.0.0",
            service: mock
        )
        // Force load
        _ = vc.view

        // Simulate answering all 32 questions with value 3
        for _ in 0..<definition.questions.count {
            vc.test_selectCurrentResponse(value: 3)
            vc.test_advance()
        }

        // After final advance, submission should have fired
        XCTAssertEqual(mock.submitInvocations.count, 1)
        let captured = mock.submitInvocations.first!
        XCTAssertEqual(captured.payload.surveyType, .importanceCheckIn)
        XCTAssertEqual(captured.payload.responses.count, 32)
        XCTAssertEqual(captured.payload.submittedFromQuestDay, 7)

        // Computed payload uses the scoring function
        if case let .importance(_, top, level) = captured.payload.computed {
            XCTAssertEqual(top, .physical)   // uniform 3 → priority order
            XCTAssertEqual(level, 3)
        } else {
            XCTFail("expected .importance computed")
        }
    }

    func test_no_submission_when_a_question_is_unanswered() {
        let mock = MockSurveyService()
        let definition = SurveyDefinition.lookup(.stateOfChange, dimension: .emotional)!
        let vc = SurveyViewController(
            definition: definition,
            uid: "test-uid",
            submittedFromQuestDay: 21,
            appVersion: "1.0.0",
            service: mock
        )
        _ = vc.view

        // Try to advance without selecting → controller should refuse
        vc.test_advance()
        XCTAssertEqual(vc.test_currentIndex, 0)
        XCTAssertTrue(mock.submitInvocations.isEmpty)
    }

    func test_response_snapshot_includes_questionKey_and_questionText() {
        let mock = MockSurveyService()
        let definition = SurveyDefinition.lookup(.importanceCheckIn, dimension: nil)!
        let vc = SurveyViewController(
            definition: definition,
            uid: "test-uid",
            submittedFromQuestDay: 7,
            appVersion: "1.0.0",
            service: mock
        )
        _ = vc.view
        for _ in 0..<definition.questions.count {
            vc.test_selectCurrentResponse(value: 4)
            vc.test_advance()
        }
        let captured = mock.submitInvocations.first!.payload.responses
        XCTAssertEqual(captured[0].questionKey, "quest_survey_importance_q01_text")
        XCTAssertEqual(captured[0].value, 4)
        XCTAssertFalse(captured[0].questionText.isEmpty)
    }
}
```

- [ ] **Step 2: Run, verify failure**

- [ ] **Step 3: Implement the controller**

Create `Soulverse/Features/Quest/Surveys/Views/SurveyViewController.swift`:

```swift
//
//  SurveyViewController.swift
//  Soulverse
//
//  Generic question-by-question survey runner. Parameterized by SurveyDefinition.
//

import UIKit
import SnapKit

final class SurveyViewController: UIViewController {

    private enum Layout {
        static let progressTopOffset: CGFloat = 16
        static let progressHorizontalPadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let progressHeight: CGFloat = 24
        static let cardTopOffset: CGFloat = 16
        static let bottomButtonHeight: CGFloat = ViewComponentConstants.actionButtonHeight
        static let bottomButtonHorizontalPadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let bottomButtonBottomOffset: CGFloat = 16
    }

    private let definition: SurveyDefinition
    private let uid: String
    private let submittedFromQuestDay: Int
    private let appVersion: String
    private let service: SurveyServiceProtocol

    private var currentIndex = 0
    private var responses: [SurveyResponse?]

    private let progressBar = SurveyProgressBar()
    private let cardView: SurveyQuestionCardView
    private let nextButton = SoulverseButton(style: .primary)

    init(
        definition: SurveyDefinition,
        uid: String,
        submittedFromQuestDay: Int,
        appVersion: String,
        service: SurveyServiceProtocol
    ) {
        self.definition = definition
        self.uid = uid
        self.submittedFromQuestDay = submittedFromQuestDay
        self.appVersion = appVersion
        self.service = service
        self.cardView = SurveyQuestionCardView(scale: definition.responseScale)
        self.responses = Array(repeating: nil, count: definition.questions.count)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themeBackgroundPrimary
        title = NSLocalizedString(definition.titleKey, comment: "")
        layoutSubviews()
        cardView.onSelect = { [weak self] value in
            self?.recordCurrentResponse(value: value)
        }
        renderCurrentQuestion()
    }

    private func layoutSubviews() {
        view.addSubview(progressBar)
        progressBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.progressTopOffset)
            make.left.right.equalToSuperview().inset(Layout.progressHorizontalPadding)
            make.height.equalTo(Layout.progressHeight)
        }

        view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(Layout.cardTopOffset)
            make.left.right.equalToSuperview()
        }

        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(cardView.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(Layout.bottomButtonHorizontalPadding)
            make.height.equalTo(Layout.bottomButtonHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Layout.bottomButtonBottomOffset)
        }
        nextButton.setTitle(
            NSLocalizedString("quest_survey_next_button", comment: ""),
            for: .normal
        )
        nextButton.addTarget(self, action: #selector(didTapNext), for: .touchUpInside)
    }

    private func renderCurrentQuestion() {
        let question = definition.questions[currentIndex]
        let text = NSLocalizedString(question.key, comment: "")
        cardView.setQuestion(text)
        cardView.setSelected(value: responses[currentIndex]?.value)
        progressBar.update(current: currentIndex + 1, total: definition.questions.count)

        let isLast = currentIndex == definition.questions.count - 1
        let buttonKey = isLast ? "quest_survey_submit_button" : "quest_survey_next_button"
        nextButton.setTitle(NSLocalizedString(buttonKey, comment: ""), for: .normal)
    }

    private func recordCurrentResponse(value: Int) {
        let q = definition.questions[currentIndex]
        responses[currentIndex] = SurveyResponse(
            questionKey:  q.key,
            questionText: NSLocalizedString(q.key, comment: ""),
            value:        value
        )
    }

    @objc private func didTapNext() { advance() }

    private func advance() {
        guard responses[currentIndex] != nil else {
            presentNoResponseAlert()
            return
        }
        if currentIndex == definition.questions.count - 1 {
            submit()
        } else {
            currentIndex += 1
            renderCurrentQuestion()
        }
    }

    private func presentNoResponseAlert() {
        let alert = UIAlertController(
            title: NSLocalizedString("quest_survey_required_response_alert_title", comment: ""),
            message: NSLocalizedString("quest_survey_required_response_alert_message", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func submit() {
        let nonOptionalResponses = responses.compactMap { $0 }
        guard nonOptionalResponses.count == definition.questions.count else {
            presentNoResponseAlert()
            return
        }
        let computed = definition.score(nonOptionalResponses)
        let payload = SurveySubmissionPayload(
            submissionId:          UUID().uuidString,
            surveyType:            definition.surveyType,
            appVersion:            appVersion,
            submittedFromQuestDay: submittedFromQuestDay,
            dimension:             definition.dimension,
            responses:             nonOptionalResponses,
            computed:              computed
        )
        nextButton.isEnabled = false
        nextButton.setTitle(
            NSLocalizedString("quest_survey_submitting", comment: ""),
            for: .normal
        )
        service.submitSurvey(uid: uid, payload: payload) { [weak self] result in
            DispatchQueue.main.async {
                self?.handleSubmitResult(result, payload: payload)
            }
        }
    }

    private func handleSubmitResult(
        _ result: Result<String, Error>,
        payload: SurveySubmissionPayload
    ) {
        switch result {
        case .success:
            let resultVC = SurveyResultViewController(payload: payload, isFirstTime: true)
            navigationController?.pushViewController(resultVC, animated: true)
        case .failure:
            let alert = UIAlertController(
                title: NSLocalizedString("quest_survey_submission_failed_title", comment: ""),
                message: NSLocalizedString("quest_survey_submission_failed_message", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            nextButton.isEnabled = true
            renderCurrentQuestion()
        }
    }

    // MARK: - Test hooks (internal)

    var test_currentIndex: Int { currentIndex }

    func test_selectCurrentResponse(value: Int) {
        recordCurrentResponse(value: value)
    }

    func test_advance() { advance() }
}
```

- [ ] **Step 4: Run, all 3 tests pass**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Views/SurveyViewController.swift \
        SoulverseTests/Tests/Features/Quest/Surveys/SurveyViewControllerTests.swift
git commit -m "feat(quest): add generic SurveyViewController parameterized by SurveyDefinition"
```

---

## Task 21: Generic `SurveyResultViewController`

**Files:**
- Create: `Soulverse/Features/Quest/Surveys/Views/SurveyResultViewController.swift`

The result view receives a `SurveySubmissionPayload` (from immediate post-submission flow) **or** a `SurveySubmissionRecord` (from a later tap on a `RecentResultCard`). Renders per-type result content:

- **Importance:** "Your top priority is X." plus first-time vs follow-up header.
- **8-Dim:** stage label + message for the dimension.
- **State-of-Change:** stage label (Considering / ... / Sustaining) + readiness index.
- **Satisfaction:** top + lowest categories.

Define a single `Mode` enum so the controller can be initialized from either side.

- [ ] **Step 1: Implement the result controller**

Create `Soulverse/Features/Quest/Surveys/Views/SurveyResultViewController.swift`:

```swift
//
//  SurveyResultViewController.swift
//  Soulverse
//
//  Renders the computed result of any survey submission. Used immediately
//  post-submission and when re-opened later via tap on a RecentResultCard
//  (per Phase 5 / Q-1 = (b) in spec §11).
//

import UIKit
import SnapKit

final class SurveyResultViewController: UIViewController {

    private enum Layout {
        static let horizontalPadding: CGFloat = ViewComponentConstants.horizontalPadding
        static let topOffset: CGFloat = 32
        static let headerToBodySpacing: CGFloat = 16
        static let bodyToButtonSpacing: CGFloat = 24
        static let buttonHeight: CGFloat = ViewComponentConstants.actionButtonHeight
    }

    enum Source {
        case immediate(payload: SurveySubmissionPayload)
        case fromHistory(record: SurveySubmissionRecord)
    }

    private let source: Source
    private let isFirstTime: Bool

    private let headerLabel = UILabel()
    private let bodyLabel = UILabel()
    private let doneButton = SoulverseButton(style: .primary)

    var onDone: (() -> Void)?

    convenience init(payload: SurveySubmissionPayload, isFirstTime: Bool) {
        self.init(source: .immediate(payload: payload), isFirstTime: isFirstTime)
    }

    convenience init(record: SurveySubmissionRecord) {
        self.init(source: .fromHistory(record: record), isFirstTime: false)
    }

    private init(source: Source, isFirstTime: Bool) {
        self.source = source
        self.isFirstTime = isFirstTime
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themeBackgroundPrimary
        layoutSubviews()
        render()
    }

    private func layoutSubviews() {
        headerLabel.font = .preferredFont(forTextStyle: .largeTitle)
        headerLabel.textColor = .themeTextPrimary
        headerLabel.numberOfLines = 0
        view.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(Layout.topOffset)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.textColor = .themeTextSecondary
        bodyLabel.numberOfLines = 0
        view.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(Layout.headerToBodySpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(bodyLabel.snp.bottom).offset(Layout.bodyToButtonSpacing)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-16)
            make.height.equalTo(Layout.buttonHeight)
        }
        doneButton.setTitle(
            NSLocalizedString("quest_survey_result_done_button", comment: ""),
            for: .normal
        )
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
    }

    @objc private func didTapDone() {
        if let onDone = onDone { onDone() }
        else { navigationController?.popToRootViewController(animated: true) }
    }

    private func render() {
        let computed: SurveyComputed
        let surveyType: SurveyType
        switch source {
        case let .immediate(payload):
            computed = payload.computed
            surveyType = payload.surveyType
        case let .fromHistory(record):
            computed = record.computed
            surveyType = record.surveyType
        }
        headerLabel.text = NSLocalizedString(
            isFirstTime
                ? "quest_survey_result_first_time_header"
                : "quest_survey_result_followup_header",
            comment: ""
        )
        bodyLabel.text = bodyText(for: computed, surveyType: surveyType)
    }

    private func bodyText(for computed: SurveyComputed, surveyType: SurveyType) -> String {
        switch computed {
        case let .importance(_, top, _):
            let format = NSLocalizedString("quest_survey_result_top_focus_format", comment: "")
            return String(format: format, NSLocalizedString(top.labelKey, comment: ""))

        case let .eightDim(_, _, _, _, stageKey, messageKey):
            return NSLocalizedString(stageKey, comment: "") + "\n\n" +
                   NSLocalizedString(messageKey, comment: "")

        case let .stateOfChange(_, _, readiness, stage, stageKey, stageMessageKey):
            let stageFormat = NSLocalizedString("quest_survey_result_stage_format", comment: "")
            let readinessFormat = NSLocalizedString("quest_survey_result_readiness_index_format", comment: "")
            let stageLine = String(
                format: stageFormat, stage,
                NSLocalizedString(stageKey, comment: "")
            )
            let messageLine = NSLocalizedString(stageMessageKey, comment: "")
            let readinessLine = String(format: readinessFormat, readiness)
            return [stageLine, messageLine, readinessLine].joined(separator: "\n\n")

        case let .satisfaction(_, top, lowest):
            let topFormat = NSLocalizedString("quest_survey_result_top_focus_format", comment: "")
            let lowFormat = NSLocalizedString("quest_survey_result_lowest_focus_format", comment: "")
            return String(format: topFormat, NSLocalizedString(top.labelKey, comment: ""))
                 + "\n\n"
                 + String(format: lowFormat, NSLocalizedString(lowest.labelKey, comment: ""))
        }
    }
}
```

- [ ] **Step 2: Build verify**

- [ ] **Step 3: Commit**

```bash
git add Soulverse/Features/Quest/Surveys/Views/SurveyResultViewController.swift
git commit -m "feat(quest): add generic SurveyResultViewController for post-submit and history view"
```

---

## Task 22: Run full test suite + open PR

**Files:** none

- [ ] **Step 1: Run the entire SoulverseTests target**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test 2>&1 | tail -60
```

Expected: all tests pass. Specifically:
- `SurveyTypeTests` (6 tests)
- `ResponseScaleTests` (4)
- `SurveyResponseSnapshotTests` (3)
- `SurveyDefinitionExhaustivenessTests` (5)
- `ImportanceScoringTests` (9)
- `EightDimScoringTests` (9)
- `StateOfChangeScoringTests` (7)
- `SatisfactionScoringTests` (5)
- `SurveyViewControllerTests` (3)

= **51 tests** total in this plan.

- [ ] **Step 2: Final build check**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Push and open PR**

```bash
git push -u origin feat/quest-survey-infrastructure
gh pr create --title "feat(quest): survey infrastructure (definitions, generic VC, FirestoreSurveyService)" --body "$(cat <<'EOF'
## Summary
- Adds `SurveyType`, `WellnessDimension`, `ResponseScale`, `SurveyDefinition` infrastructure for the Onboarding Quest feature.
- 4 per-survey definitions with pure-Swift scoring (Importance / 8-Dim / SoC / Satisfaction).
- Generic `SurveyViewController` + `SurveyResultViewController` parameterized by survey type.
- `FirestoreSurveyService` write-once + recent-query reader.
- ~250 en localization keys spanning questions, response scales, stage labels, and result UI.

## Test plan
- [ ] All 51 unit tests pass on iPhone 16 Pro Max simulator (iOS 26.0).
- [ ] Manual smoke: launch a SurveyViewController for each of 4 surveys; submit a full survey; verify Firestore document created at `users/{uid}/survey_submissions/{id}` (requires Plan 1 deployed).
- [ ] Manual smoke: re-open from a `SurveySubmissionRecord` reads the same payload back.

## Cross-plan dependencies
- Plan 1 (Cloud Functions) must be deployed for end-to-end integration. Unit tests in this plan are independent.
- Plan 5 (Quest tab integration) consumes this plan's public surface; signatures are stable.

## Out of scope (this plan)
- Quest tab `SurveySection` composition (Plan 5).
- Radar chart refactor (Plan 5).
- FCM (Plan 6).
EOF
)"
```

---

## Self-review checklist

Before merging, confirm:

- [ ] All 4 survey scoring formulas implemented and unit-tested with table-driven cases.
- [ ] Response payload structure (`questionKey` + `questionText` snapshot) verified by `SurveyResponseSnapshotTests` and `SurveyViewControllerTests`.
- [ ] `SurveyType` enum exhaustiveness enforced by `SurveyDefinitionExhaustivenessTests` (adding a new case fails the test until a definition is registered).
- [ ] No hardcoded numbers in `snp.makeConstraints` — all via `Layout` enum or `ViewComponentConstants`.
- [ ] No hardcoded colors — all via `.theme*` tokens.
- [ ] Every user-facing string uses `NSLocalizedString()`; all keys present in `en.lproj/Localizable.strings`.
- [ ] `SurveyType` raw values match `functions/src/types.ts` (Plan 1) — verified by `test_surveyType_rawValue_matches_cloudFunctionContract`.
- [ ] `submittedAt` is server-stamped via `FieldValue.serverTimestamp()` (write-once enforced by Security Rules from Plan 1).
- [ ] No Quest tab UI integration in this plan (deferred to Plan 5).

---

**End of Plan 4.**
