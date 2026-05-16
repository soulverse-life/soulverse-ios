# Onboarding Quest — Design Specification

**Status:** Approved — ready for implementation planning
**Branch:** `feat/onboarding-quest`
**Decision Log (review history):** [`2026-05-01-onboarding-quest-decision-log.md`](./2026-05-01-onboarding-quest-decision-log.md)

---

## 1. Overview

The Onboarding Quest is a 21-day journey on the existing Quest tab that guides new users through wellness self-reflection, daily habit tracking, and progressive feature unlocks. After Day 21, the Quest screen becomes a permanent dashboard with periodic survey re-takes driving ongoing engagement.

The user advances through three stages by completing distinct-day Mood Check-Ins (the primary engagement loop). Each stage unlocks new Quest content. A configurable survey schedule defines when each survey type becomes available for first-time taking and re-taking.

**Stages:**
- **Stage 1** (distinctCheckInDays 1–7): Habit Checker only. 8-Dimensions card and Custom Habit slot are visible but locked (D5 affordance). **Survey section is hidden entirely** (no placeholder card).
- **Stage 2** (8–14): Importance Check-In becomes available; after submission, focus dimension is assigned and 8-Dim survey unlocks.
- **Stage 3** (15–21): State-of-Change survey becomes available; Custom Habit slot unlocks at Day 14.
- **Post-Quest** (22+): Top progress bar hides. Survey re-takes drive engagement on a configurable schedule. Satisfaction Check-In first becomes available 90 days after Day 21.

---

## 2. Scope

### 2.1 In MVP

- Quest tab full implementation (existing skeleton at index 4).
- Mood Check-In day-counter derivation (existing data, no Mood Check-In feature changes).
- Importance Check-In survey (32 Q, drives focus dimension assignment).
- 8-Dim wellness survey (10 Q × 8 dimensions).
- State-of-Change readiness survey (15 Q).
- Satisfaction Check-In survey (32 Q, observational).
- Habit Checker: 3 fixed defaults + 1 custom slot (unlocks Day 14).
- Server-side push notifications via Cloud Functions + FCM.
- Config-driven survey schedule (`SURVEY_SCHEDULE` array in **TypeScript only** — Cloud Function). Client reads server-derived pending state.
- Hardcoded question banks in client (Swift), localized **en only for MVP**. zh-TW deferred to v1.1.

### 2.2 Out of MVP (deferred)

- **zh-TW localization** (en only for MVP; ~161 strings to translate for v1.1).
- Focus-dimension switching UI.
- Full wellness-doc 12-month assessment rotation (D23 implements a simplified subset).
- Idle-user re-engagement notifications.
- Subscription/membership system (would unlock custom habit slots 2 & 3).
- Per-habit goals.
- Hard-delete of custom habits.
- Firestore-served survey schedule (v1.1 evolution).
- Day-21 completion celebration UI (no product design exists).

---

## 3. Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│ iOS Client (VIPER, SnapKit, NSLocalizedString, theme-aware colors)      │
│                                                                         │
│  Quest tab (existing QuestViewController skeleton, index 4):            │
│   ├─ QuestPresenter                                                     │
│   ├─ QuestViewModel  (framework-agnostic; derives all UI states)        │
│   ├─ Subviews:                                                          │
│   │    ProgressSection  — count + Day-1 CTA + persistent banner         │
│   │    EightDimensionsCard — radar + State-of-Change indicator          │
│   │    HabitCheckerSection — 3 default habits + 1 custom slot           │
│   │    SurveySection — PendingSurveyDeck + RecentResultCardList         │
│   │                     (hides entirely when distinctCheckInDays < 7)   │
│   ├─ Sub-flows:                                                         │
│   │    SurveyViewController (generic, parameterized by survey type)     │
│   │    SurveyResultViewController (generic, shown post-submission       │
│   │       AND accessible later via tap on RecentResultCard)             │
│   │    CustomHabitFormViewController                                    │
│   └─ Services (Soulverse/Shared/Service/, FirestoreXxxService pattern): │
│        FirestoreQuestService — quest_state reads/writes                 │
│        FirestoreSurveyService — survey_submissions writes               │
│        FirestoreHabitService — habits/state reads/writes                │
│   FCM token registration:                                               │
│        AppDelegate's MessagingDelegate extension writes                 │
│          users/{uid}/devices/{deviceId}                                 │
└─────────────────────────────────────────────────────────────────────────┘
                              ▲          │
                              │          │ FCM push
┌─────────────────────────────────────────────────────────────────────────┐
│ Firebase                                                                │
│                                                                         │
│  Firestore:                                                             │
│   users/{uid}/                                                          │
│     quest_state              ← single aggregate doc, 1 read = full state│
│     habits/state             ← single-doc habit history (Shape α)       │
│     mood_checkins/{id}       ← existing (trigger source)                │
│     survey_submissions/{id}  ← write-once, all 4 survey types           │
│     notification_state/{key} ← server-only writes; client read-only     │
│     devices/{deviceId}       ← FCM token persistence                    │
│                                                                         │
│  Cloud Functions (functions/, TypeScript, Gen 2):                       │
│    onUserCreated              — initialize quest_state                  │
│    onMoodCheckInCreated       — maintain distinctCheckInDays            │
│    onSurveySubmissionCreated  — maintain quest_state survey timestamps  │
│                                  (and focusDimension for Importance)    │
│    questNotificationCron      — hourly rule engine + FCM dispatcher     │
│                                                                         │
│  FCM (Firebase Cloud Messaging) — server-side push delivery             │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.1 Architectural pillars

1. **Aggregate-doc pattern.** `users/{uid}/quest_state` holds all rule-engine and Quest-screen state. Single read returns the full state needed to render any Quest UI.
2. **Predicate-driven UI.** The Survey section composition (PendingSurveyDeck + RecentResultCardList) is a pure function of `quest_state` + recent submissions + the schedule config.
3. **Config-driven schedule.** All survey timing rules live in a single `SURVEY_SCHEDULE` array (parallel TypeScript and Swift definitions, kept in sync). The rule engine and the client compose UI from the same config.
4. **Decoupled push and in-app.** Both channels use the same predicate engine. Push delivery has no effect on in-app surfaces; OS-level notifications-disabled users still see all available content in-app.
5. **Server-authoritative state.** Day counter, focus dimension, and notification idempotency are written by Cloud Functions. Clients read but cannot bypass (enforced via Firestore Security Rules).
6. **Atomic increments.** Habit data uses `FieldValue.increment()` on nested field paths so concurrent / offline writes converge correctly.

---

## 4. Data model

### 4.1 `users/{uid}/quest_state` (aggregate doc)

```jsonc
{
  // Day counter & quest progression
  "distinctCheckInDays":          17,
  "lastDistinctDayKey":           "2026-04-28",   // YYYY-MM-DD; trigger uses to detect new day
  "questCompletedAt":             null,           // set when distinctCheckInDays first reaches 21

  // Focus dimension & UX state
  "focusDimension":               null,           // null until Importance Check-In submitted
  "focusDimensionAssignedAt":     null,

  // Server-derived pending surveys (maintained by Cloud Function)
  "pendingSurveys": [],                            // ["importance_check_in", "8dim", ...] currently eligible
  "surveyEligibleSinceMap": {},                    // { "<surveyType>": <timestamp> } — for deck ordering

  // Survey submission timestamps (denormalized for cheap reads)
  "importanceCheckInSubmittedAt":    null,
  "lastEightDimSubmittedAt":         null,
  "lastEightDimDimension":           null,
  "lastEightDimSummary":             null,        // { stage: 1-3, stageKey, messageKey }
  "lastStateOfChangeSubmittedAt":    null,
  "lastStateOfChangeStage":          null,        // 1-5
  "satisfactionCheckInSubmittedAt":  null,
  "lastSatisfactionTopCategory":     null,        // dimension name
  "lastSatisfactionLowestCategory":  null,        // dimension name

  // Notification idempotency (server-only writes)
  "notification_state": {
    "importance_check_in_first":    { "lastSentAt": null },
    "importance_check_in_retake":   { "lastSentAt": null },
    "8dim_first":                   { "lastSentAt": null },
    "8dim_retake":                  { "lastSentAt": null },
    "state_of_change_first":        { "lastSentAt": null },
    "state_of_change_retake":       { "lastSentAt": null },
    "satisfaction_check_in_first":  { "lastSentAt": null },
    "satisfaction_check_in_retake": { "lastSentAt": null },
    "MilestoneDay14":               { "lastSentAt": null },
    "MilestoneDay21":               { "lastSentAt": null }
  },

  // Cron query optimization
  "notificationHour":             1,              // user-local 9am → UTC hour; indexed
  "timezoneOffsetMinutes":        480             // current device offset
}
```

### 4.2 `users/{uid}/habits/state` (single doc — Shape α)

```jsonc
{
  "daily": {
    "2026-04-28": { "exercise": 30, "water": 250, "meditation": 15, "h_abc123": 10 },
    "2026-04-29": { "exercise": 45, "water": 200 }
  },
  "customHabits": {                                // map keyed by habit id
    "h_abc123": {
      "id":         "h_abc123",
      "name":       "Stretch",
      "unit":       "min",
      "increments": [5, 10, 15],
      "createdAt":  "<timestamp>",
      "deletedAt":  null
    }
  }
}
```

**Increment writes:** `update(ref, { ["daily.<date>.<habitId>"]: FieldValue.increment(<amount>) })`.

**Custom habit add:** `update(ref, { ["customHabits.<newId>"]: <fullObject> })`.

**Custom habit soft-delete:** `update(ref, { ["customHabits.<id>.deletedAt"]: <timestamp> })`.

**Date key derivation:** YYYY-MM-DD in the device's *current* timezone at write time. (Different from D1's day-counter rule for Mood Check-Ins, which uses each record's stored offset. Asymmetry is intentional and documented.)

### 4.3 `users/{uid}/survey_submissions/{id}` (write-once)

```jsonc
{
  "submissionId":         "<uuid>",
  "surveyType":           "importance_check_in" | "8dim" | "state_of_change" | "satisfaction_check_in",
  "submittedAt":          "<serverTimestamp>",
  "appVersion":           "1.0.0",
  "submittedFromQuestDay": 8,
  "payload": <see per-type schema below>

  // (questionBankVersion removed — responses are self-describing via
  //  questionKey + questionText snapshot; see per-type schema)
}
```

#### Importance Check-In payload

Each response captures the **localization key** and a **snapshot of the rendered question text** at submission time. This makes responses self-describing — even if the question bank is later rewritten or keys are renamed, historical responses remain interpretable on their own.

```jsonc
{
  "responses": [
    {
      "questionKey":  "quest_survey_importance_q01_text",
      "questionText": "How important to you is your overall quality of life?",
      "value":        4
    },
    /* ...32 total */
  ],
  "computed": {
    "categoryMeans": {
      "physical":      3.5,    // (Q2+Q3+Q4+Q5+Q15+Q16) / 6
      "emotional":     4.2,    // (Q6+Q7+Q8+Q12+Q14) / 5
      "social":        3.8,    // (Q19+Q20+Q21) / 3
      "intellectual":  3.6,    // (Q9+Q10+Q11+Q27+Q28) / 5
      "spiritual":     3.3,    // (Q7+Q8+Q32) / 3
      "occupational":  4.0,    // (Q18) / 1
      "environmental": 3.5,    // (Q22+Q23+Q30+Q31) / 4
      "financial":     3.5     // (Q17+Q24+Q25+Q26) / 4
    },
    "topCategory":     "emotional",
    "tieBreakerLevel": 1                           // 1=primary, 2=mood-topic-count, 3=priority-order
  }
}
```

#### 8-Dim payload

```jsonc
{
  "dimension": "emotional",
  "responses": [
    {
      "questionKey":  "quest_survey_8dim_emotional_q01_text",
      "questionText": "I notice physical sensations in my body...",
      "value":        4
    },
    /* ...10 total — same snapshot pattern */
  ],
  "computed": {
    "totalScore":  37,
    "meanScore":   3.7,
    "stage":       2,                              // 1-3
    "stageKey":    "quest_stage_8dim_emotional_2_label",
    "messageKey":  "quest_stage_8dim_emotional_2_message"
  }
}
```

#### State-of-Change payload

```jsonc
{
  "dimension": "emotional",
  "responses": [
    {
      "questionKey":  "quest_survey_soc_q01_text",
      "questionText": "I took steps to prevent myself from slipping back into old patterns.",
      "value":        3
    },
    /* ...15 total — same snapshot pattern */
  ],
  "computed": {
    "substageMeans": {
      "precontemplation": 2.33,                    // (Q2+Q9+Q15) / 3
      "contemplation":    3.67,                    // (Q4+Q11+Q14) / 3
      "preparation":      4.00,                    // (Q6+Q10+Q12) / 3
      "action":           3.33,                    // (Q3+Q7+Q8) / 3
      "maintenance":      3.00                     // (Q1+Q5+Q13) / 3
    },
    "readinessIndex":   16.32,                     // PC*1 + C*2 + P*3 + A*4 + M*5
    "stage":            3,                         // 1-5
    "stageKey":         "quest_stage_soc_3_label", // "Preparing"
    "stageMessageKey":  "quest_stage_soc_3_message"
  }
}
```

#### Satisfaction Check-In payload

```jsonc
{
  "responses": [ /* 32 total */ ],
  "computed": {
    "categoryMeans": { /* same 8 categories as Importance, satisfaction-scored */ },
    "topCategory":     "physical",
    "lowestCategory":  "occupational"
  }
}
```

### 4.4 `users/{uid}/notification_state/{ruleId}` (server-only writes)

```jsonc
{
  "lastSentAt": "<timestamp>"
}
```

Read by client (for predicate evaluation in the Survey section); written exclusively by Cloud Functions via Admin SDK.

### 4.5 `users/{uid}/devices/{deviceId}`

```jsonc
{
  "fcmToken":   "<fcm_token>",
  "platform":   "ios",
  "appVersion": "1.0.0",
  "lastSeenAt": "<timestamp>"
}
```

### 4.6 (existing) `users/{uid}/mood_checkins/{id}`

No schema change. `createdAt` enforced as `serverTimestamp()` per Security Rules. `timezoneOffsetMinutes` constrained to range −840 to +840.

---

## 5. UI composition (Quest screen)

```
┌─ Quest tab screen ────────────────────────────────────────┐
│                                                            │
│  ProgressSection (top)                                     │
│  ───────────────────────────────                           │
│  • Day < 21:                                               │
│      Day-N pill                                            │
│      Progress dots (segmented by current stage)            │
│      Day-1 CTA "Do today's Mood Check-In →" (if not done)  │
│      [No persistent reveal banner — Day-7 announcement     │
│       merges into Importance Check-In submission flow]     │
│  • Day ≥ 21:  hidden                                       │
│                                                            │
│  EightDimensionsCard                                       │
│  ───────────────────────────────                           │
│  • Title "Your 8 Dimensions"                               │
│  • Radar chart (8 axes)                                    │
│      - Highlighted dot = current focus dim (large + glow)  │
│      - Regular dot = previously-focused dim with data      │
│        (only visible post-v1.1 switching)                  │
│      - Ghost markers at center for never-assessed axes     │
│      - Below: "Your first dimension is mapped! Take more   │
│        surveys to fill in your wellness web."              │
│  • State-of-Change indicator (5 dots)                      │
│      - Hidden until SoC submitted                          │
│      - Friendly labels:                                    │
│        Considering / Planning / Preparing / Doing /        │
│        Sustaining                                          │
│      - Below: per-stage one-sentence message               │
│  • Locked-card treatment when distinctCheckInDays < 7      │
│      AND focusDimension is null:                           │
│      tap shows context hint per D5                         │
│                                                            │
│  HabitCheckerSection                                       │
│  ───────────────────────────────                           │
│  • "Daily Micro Behaviors" header                          │
│  • Three default habit cards:                              │
│      Exercise (min) — buttons +5 +10 +15 +30               │
│      Water (ml)     — buttons +100 +200 +300               │
│      Meditation (min) — buttons +5 +10 +20                 │
│  • Each card shows:                                        │
│      Title                                                 │
│      "Today: {N} {unit}"                                   │
│      "Yesterday: {N} {unit}" (if non-zero)                 │
│      Subtitle "Resets at midnight"                         │
│  • Custom habit card (if exists; same visual pattern)      │
│  • [Add Custom Habit] button:                              │
│      Locked when distinctCheckInDays < 14                  │
│      Available when day ≥ 14 and no custom habit exists    │
│      Hidden when 1 custom habit exists (slot full)         │
│                                                            │
│  SurveySection                                             │
│  ───────────────────────────────                           │
│  • Hidden entirely when distinctCheckInDays < 7            │
│  • PendingSurveyDeck (deck-of-cards visual):               │
│      Front: oldest pending survey, full-sized              │
│      Behind: offset/dimmed cards if 2+ pending             │
│      "+N more" badge if 3+ pending                         │
│  • RecentResultCardList (vertical stack, newest top):      │
│      One card per recent submission within 7 days          │
│      Suppressed when same-type pending card exists         │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### 5.1 Survey section composition rules

| Component | Cardinality | Visibility predicate |
|---|---|---|
| **PendingSurveyDeck** | 0..1 (deck contains 1..N cards) | `distinctCheckInDays >= 7 AND pending list non-empty` |
| **RecentResultCardList** | 0..M cards | One per surveyType where: not pending AND recent submission within `recentResultWindowDays` (=7 for all) |
| **Locked state** | n/a | Section hides entirely; no placeholder card |

**Pending-suppresses-result rule:** If survey type X is currently pending, its result card is hidden. Prevents stale ghost ("you took this 8 days ago" while also "take it again").

**Deck ordering:** Front card = oldest `eligibleSince` timestamp. After submission, the next-oldest pending survey rotates to the front.

**Sort order in result list:** newest `submittedAt` on top.

### 5.2 Radar chart rendering (revised Phase 5)

The radar chart is a **State-of-Change-driven** visualization (1–5 stages from the State-of-Change survey). The 8-Dim survey's wellness stage (1–3) does **not** appear on the radar chart — it lives only in the survey result view.

**Refactor existing `QuestRadarChartView`** (`Soulverse/Features/Quest/Views/QuestRadarChartView.swift`): reuse the DGCharts axis web/grid setup and labels; **disable polygon-fill rendering** (`drawFilledEnabled = false`); add overlay UIImageViews for state-aware dots, lock icons, and the EmoPet center icon.

#### Per-axis rendering rules

| Per-dimension state | Visual |
|---|---|
| **Current focus dim, no SoC submitted yet** | 5 outline dots along the axis at positions 1, 2, 3, 4, 5 (distance from center). No solid dot yet. |
| **Current focus dim, SoC submitted** | 5 outline dots PLUS one **solid** dot at the user's current State-of-Change stage. Re-takes move the solid dot to the new stage. |
| **Previously-focused dim** (only reachable post-v1.1 switching) | Single **dim** dot at the State-of-Change stage the user reached when that dim was their focus. No outline dots, no solid dot. |
| **Never assessed** (no focus ever, no submission) | **Lock icon** at the outermost position (stage 5 distance) of the axis. |

#### Center

**EmoPet image always visible at the center**, regardless of axis state.

#### MVP reach

In MVP (no dimension switching), the rendering reduces to:
- 1 axis = current focus dim → 5 outline dots, plus 1 solid dot once SoC submitted.
- 7 axes = never assessed → lock icons.
- Center = EmoPet.

The "previously-focused dim" rendering branch is implemented but unreachable until v1.1 ships dimension switching.

#### Stage-1 locked-card state

When `distinctCheckInDays < 7` (no focus assigned yet), all 8 axes show lock icons; EmoPet is centered. The card itself has the D5 lock-affordance overlay; tap shows "Unlocks at Day 7".

### 5.3 Locked-card hint copy (proximity-based)

| Distance from unlock | Hint copy |
|---|---|
| > 3 days from threshold | "On Day {X}, you'll {feature}." |
| ≤ 2 days | "Just {N} more check-ins!" |
| 1 day | "Just 1 more check-in!" |

---

## 6. State machines & flows

### 6.1 Quest stage progression

```
        distinctCheckInDays
        0..6           7..13           14..20           21+
          │              │                │               │
          ▼              ▼                ▼               ▼
      ┌──────┐       ┌──────┐         ┌──────┐         ┌──────┐
      │Stage │ ────▶ │Stage │ ──────▶ │Stage │ ──────▶ │Done  │
      │  1   │       │  2   │         │  3   │         │      │
      └──────┘       └──────┘         └──────┘         └──────┘
                       │                │                │
                       ▼                ▼                ▼
                Importance Check-  Custom habit    Top progress bar
                In becomes pending  unlocks (Day   hides; rule engine
                MilestoneDay7-      14 milestone   schedules re-takes
                equivalent push    push)
                fires next 9am
                local              SoC becomes
                                   pending after
                                   8-Dim done
```

**Pure day-count progression** — no engagement gates. A user can reach Day 21 with only mood check-ins (no surveys, no habits) and still graduate. This is acknowledged in D3.

### 6.2 Day-bucketing rules (intentionally asymmetric)

| Domain | Rule | Why |
|---|---|---|
| Day counter (mood check-ins) | YYYY-MM-DD from each record's *stored* `timezoneOffsetMinutes` | Captures "where the user was" — travel produces 2 distinct days |
| Habit increment writes | YYYY-MM-DD from device's *current* timezone at write time | Habits don't have intrinsic context; matches the user's "today" |

**Cross-timezone telemetry:** Habit writes emit `quest_habit_timezone_shift_detected` analytics event when device tz shifts >2h within same calendar day. Used by support staff to diagnose "my exercise minutes vanished" reports.

### 6.3 Day-7 flow (Importance Check-In)

```
Day 6 → Day 7 transition (user submits 7th distinct-day mood check-in)
   │
   ▼
onMoodCheckInCreated Cloud Function:
   • Compute dayKey from record's stored timezoneOffsetMinutes
   • If dayKey != quest_state.lastDistinctDayKey:
       atomic update: distinctCheckInDays++, lastDistinctDayKey = dayKey
   • If distinctCheckInDays now == 21:
       atomic update: questCompletedAt = serverTimestamp()
   • Re-evaluate SURVEY_SCHEDULE → update pendingSurveys + surveyEligibleSinceMap
       (Importance Check-In becomes pending immediately at this transition)
   │
   ▼ (Firestore listener fires immediately)
User's open Quest tab updates IN REAL TIME:
   • Survey section becomes visible (was hidden when distinctCheckInDays < 7)
   • PendingSurveyDeck shows Importance Check-In as the only pending card
   • 8-Dim and SoC stay locked (focus not yet assigned via Importance result)
   │
   ▼ (or, if user closed the app)
Next 9am local (questNotificationCron):
   • Query users where notificationHour == currentUTCHour
   • For each matched user, re-evaluate pendingSurveys:
       For each survey in pendingSurveys: if its notification hasn't fired
       for the current eligibility window AND user hasn't already submitted
       in the meantime → fire push.
   • Importance Check-In suppression check: if user already submitted
       (importanceCheckInSubmittedAt non-null), skip the send entirely.
   │
   ▼
User taps Importance Check-In card → SurveyViewController(.importance):
   32 questions, 5-point importance scale
   On submit: write users/{uid}/survey_submissions/{newId}:
     surveyType: "importance_check_in"
     responses: [{ questionKey, questionText, value }, ...]   // self-describing
     computed: { categoryMeans, topCategory, tieBreakerLevel }
   │
   ▼
onSurveySubmissionCreated trigger:
   surveyType === "importance_check_in" → atomic update:
     quest_state.focusDimension = payload.computed.topCategory
     quest_state.focusDimensionAssignedAt = serverTimestamp()
     quest_state.importanceCheckInSubmittedAt = submittedAt
     Re-evaluate SURVEY_SCHEDULE → update pendingSurveys
       (Importance removed from pending; 8-Dim added to pending)
   │
   ▼
Client navigates from SurveyViewController to SurveyResultViewController:
   Shows wellness doc's "first-time score" message:
   "Thank you for your first check-in. Your top priority is {focus}.
    This awareness is your foundation..."
   "Done" button returns user to Quest tab.
   │
   ▼ (Firestore listener fires; UI updates in real time)
Quest tab shows:
   PendingSurveyDeck now contains 8-Dim survey for {focus}
   RecentResultCardList shows Importance Check-In summary
   8-Dimensions card unlocks (focus axis now visible with 5 outline dots)
```

**Notification permission timing**: requested at registration completion (see §12), not in this flow.

### 6.4 Focus dimension tie-breaker chain

```
1. Highest mean score across the 8 categories from
   Importance Check-In submission.

2. If tied: the tied dimension whose value also appears
   most frequently as a `topic` in the user's mood_checkins
   to date.

3. If still tied: predetermined order
   Physical → Emotional → Social → Intellectual →
   Spiritual → Occupational → Environmental → Financial.
```

`tieBreakerLevel` (1, 2, or 3) recorded in submission payload for analytics.

### 6.5 Survey-driven UI (PendingSurveyDeck composition — revised Phase 5)

The schedule lives **only** in the Cloud Function. Client doesn't compute predicates; it reads server-derived state.

```swift
func composeSurveySection(
  state: QuestState,
  recent: [SurveySubmission]
) -> SurveySectionModel {
    if state.distinctCheckInDays < 7 { return .hidden }

    // 1. Build pending list from server-derived state.pendingSurveys
    //    Sort oldest-pending-first using surveyEligibleSinceMap.
    let pending = state.pendingSurveys
      .compactMap { surveyType -> (SurveyType, Date)? in
          guard let since = state.surveyEligibleSinceMap[surveyType] else { return nil }
          return (surveyType, since)
      }
      .sorted { $0.1 < $1.1 }                                  // oldest = front of deck
      .map { buildPendingCard(surveyType: $0.0, eligibleSince: $0.1) }

    // 2. Build recent result list — suppressed for surveyTypes currently pending
    let pendingTypes = Set(state.pendingSurveys)
    let results = recent
      .filter { !pendingTypes.contains($0.surveyType) }
      .filter { daysSince($0.submittedAt) <= 7 }               // 7-day result window for all
      .sorted { $0.submittedAt > $1.submittedAt }              // newest first
      .map { buildResultCard(submission: $0) }

    return .composed(deck: PendingSurveyDeck(cards: pending), results: results)
}
```

**Real-time updates**: any change to `quest_state.pendingSurveys` (driven by Cloud Function on trigger or cron) fires the client's Firestore listener; the deck re-renders within sub-second latency.

---

## 7. Backend

### 7.1 Cloud Functions (Gen 2, TypeScript, source at `functions/`)

| Function | Trigger | Purpose | Read budget | Write budget |
|---|---|---|---|---|
| `onUserCreated` | Auth `onCreate` (or first sign-in) | Initialize `quest_state` doc | 0 | 1 |
| `onMoodCheckInCreated` | Firestore `onCreate(mood_checkins/{id})` | Increment `distinctCheckInDays` if new dayKey; set `questCompletedAt` if reaching 21 | 1 (`quest_state`) | 1 (if new day) |
| `onSurveySubmissionCreated` | Firestore `onCreate(survey_submissions/{id})` | Update `quest_state` survey timestamps; if Importance: write `focusDimension` from `payload.computed.topCategory` | 0 | 1 |
| `questNotificationCron` | `pubsub.schedule('every 1 hours')` | Hourly rule engine: query users by `notificationHour`, evaluate `SURVEY_SCHEDULE` config, dispatch FCM | ~N/24 (`quest_state` per matched user) | 1 per fired notification (`notification_state.{key}`) |

**Function configuration:**
- Memory: 256 MB default; 512 MB for `questNotificationCron` if user count grows.
- Timeout: 540 s (9 min, Gen 2 max for scheduled).
- Region: same as Firestore database.

**Cron query gating (cost optimization):**
```javascript
db.collectionGroup('quest_state')
  .where('notificationHour', '==', currentUTCHour)
  .stream()
```
Single-field index on `quest_state.notificationHour` required (`firestore.indexes.json`).

**Cron failure ordering:** for each (user, ruleKey) pair, write `notification_state.{ruleKey}.lastSentAt` to Firestore *before* calling FCM `send()`. Trade-off: prefers a rare missed notification (Firestore wrote, FCM failed) over the more-disruptive double-send.

**Self-correction guard:** ignore `lastSentAt > now` and re-fire (clock skew protection).

### 7.2 Firestore Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow create: if request.auth != null && request.auth.uid == uid;

      // Mood check-ins — server-stamped createdAt required
      match /mood_checkins/{checkinId} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.createdAt == request.time
                      && request.resource.data.timezoneOffsetMinutes is int
                      && request.resource.data.timezoneOffsetMinutes >= -840
                      && request.resource.data.timezoneOffsetMinutes <= 840;
        allow update, delete: if false;
      }

      // Aggregate quest_state — most fields server-only;
      // client may set timezoneOffsetMinutes and notificationHour at app launch
      match /quest_state/{document=**} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid;
        allow update: if request.auth.uid == uid
                      && request.resource.data.diff(resource.data).affectedKeys()
                            .hasOnly(['timezoneOffsetMinutes', 'notificationHour']);
        allow delete: if false;
      }

      // Habit doc — client read/write within own scope (shape trust accepted)
      match /habits/state {
        allow read, write: if request.auth.uid == uid;
      }

      // Survey submissions — write-once
      match /survey_submissions/{submissionId} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.submittedAt == request.time
                      && request.resource.data.surveyType in
                          ['importance_check_in', '8dim',
                           'state_of_change', 'satisfaction_check_in'];
        allow update, delete: if false;
      }

      // Notification state — server-only via Admin SDK
      match /notification_state/{ruleId} {
        allow read: if request.auth.uid == uid;
        allow write: if false;
      }

      // FCM device tokens
      match /devices/{deviceId} {
        allow read, write: if request.auth.uid == uid;
      }
    }
  }
}
```

**Custom-habits shape threat model (accepted):** `customHabits` is a Firestore map; rules cannot validate per-key shape or cap cardinality. Threat = single-user data corruption only (no cross-user impact). Mitigation: client enforces shape and 1-slot cap. Acceptable for MVP.

### 7.3 Read-budget summary

| Surface | Cold-entry doc reads |
|---|---|
| Quest tab cold start | 2 (`quest_state` + `habits/state`) |
| Survey section (recent submissions query) | +1 query, capped client-side |
| Cron iteration per matched user | 1 (`quest_state`) |

At 10k users / 24h evenly distributed: ~10k reads/day from cron + ~10k cold-start reads/day = well under Firestore Spark/Blaze 50k/day free quota.

---

## 8. Survey schedule config (D23, revised Phase 5)

**Storage:** hardcoded TypeScript constant in `functions/src/surveySchedule.ts` — **Cloud Function only**. The client does NOT have a parallel Swift schedule constant. Schedule changes require a Cloud Function deploy, **not a client release**.

**How the client knows what's pending:** Cloud Function evaluates the schedule per user (on `mood_checkins.onCreate`, on `survey_submissions.onCreate`, and during the hourly cron) and writes `quest_state.pendingSurveys` + `quest_state.surveyEligibleSinceMap`. The client reads these fields directly to render the Survey section's PendingSurveyDeck.

```typescript
// functions/src/surveySchedule.ts (Cloud Function only — no client mirror)

interface SurveyScheduleEntry {
  surveyType: SurveyType;
  firstAvailable: EligibilityCondition;
  reTakeCadence?: EligibilityCondition;
  notification: { titleKey: string; bodyKey: string };
  recentResultWindowDays: number;
  pickFocusDimensionFromResult?: boolean;
  isMilestoneOnly?: boolean;
}

type EligibilityCondition =
  | { type: 'distinctCheckInDays'; threshold: number }
  | { type: 'daysSinceQuestComplete'; days: number }
  | { type: 'daysSinceLastSubmission'; days: number; surveyType: SurveyType }
  | { type: 'focusDimensionAssigned' }
  | { type: 'allOf'; conditions: EligibilityCondition[] }
  | { type: 'oneOf'; conditions: EligibilityCondition[] };

const SURVEY_SCHEDULE: SurveyScheduleEntry[] = [
  // Importance Check-In — Day 7 first, recurring every 7 months
  {
    surveyType: 'importance_check_in',
    firstAvailable: { type: 'distinctCheckInDays', threshold: 7 },
    reTakeCadence:  { type: 'daysSinceLastSubmission', days: 210,
                      surveyType: 'importance_check_in' },
    notification: {
      titleKey: 'quest_notification_importance_title',
      bodyKey:  'quest_notification_importance_body',
    },
    recentResultWindowDays: 7,
    pickFocusDimensionFromResult: true,
  },

  // 8-Dim — gated by focus assignment, monthly re-take
  {
    surveyType: '8dim',
    firstAvailable: {
      type: 'allOf',
      conditions: [
        { type: 'distinctCheckInDays', threshold: 7 },
        { type: 'focusDimensionAssigned' },
      ],
    },
    reTakeCadence: { type: 'daysSinceLastSubmission', days: 30, surveyType: '8dim' },
    notification: {
      titleKey: 'quest_notification_8dim_title',
      bodyKey:  'quest_notification_8dim_body',
    },
    recentResultWindowDays: 7,
  },

  // State-of-Change — Day 21 + focus, quarterly re-take
  {
    surveyType: 'state_of_change',
    firstAvailable: {
      type: 'allOf',
      conditions: [
        { type: 'distinctCheckInDays', threshold: 21 },
        { type: 'focusDimensionAssigned' },
      ],
    },
    reTakeCadence: { type: 'daysSinceLastSubmission', days: 90,
                     surveyType: 'state_of_change' },
    notification: {
      titleKey: 'quest_notification_soc_title',
      bodyKey:  'quest_notification_soc_body',
    },
    recentResultWindowDays: 7,
  },

  // Satisfaction Check-In — 90 days post-Quest-complete, every 6 months
  {
    surveyType: 'satisfaction_check_in',
    firstAvailable: { type: 'daysSinceQuestComplete', days: 90 },
    reTakeCadence:  { type: 'daysSinceLastSubmission', days: 180,
                      surveyType: 'satisfaction_check_in' },
    notification: {
      titleKey: 'quest_notification_satisfaction_title',
      bodyKey:  'quest_notification_satisfaction_body',
    },
    recentResultWindowDays: 7,
  },
];

// Milestone-only notifications (no associated survey)
const MILESTONE_NOTIFICATIONS = [
  {
    notificationKey: 'MilestoneDay14',
    predicate: { type: 'distinctCheckInDays', threshold: 14 },
    titleKey: 'quest_notification_milestone_day14_title',
    bodyKey:  'quest_notification_milestone_day14_body',
  },
  {
    notificationKey: 'MilestoneDay21',
    predicate: { type: 'distinctCheckInDays', threshold: 21 },
    titleKey: 'quest_notification_milestone_day21_title',
    bodyKey:  'quest_notification_milestone_day21_body',
  },
];
```

### 8.1 Notification-state key derivation

Each `SurveyScheduleEntry` generates **two** `notification_state` keys:
- `<surveyType>_first` — idempotency for the `firstAvailable` predicate (one-shot per user).
- `<surveyType>_retake` — idempotency for the `reTakeCadence` predicate (rolls forward each cadence window).

`MILESTONE_NOTIFICATIONS` entries generate one `notification_state` key each, named after `notificationKey`.

There is intentionally **no `MilestoneDay7`** in either list — the Importance Check-In's `_first` notification serves that purpose. Push body wording is "Help us understand what matters to you 🌱" rather than a generic milestone celebration.

### 8.2 Adding a new survey type later

1. Add a new case to `SurveyType` enum (TS in `functions/src/`, Swift in client). Two files; client only knows the enum, not schedule logic.
2. Add a new `SurveyScheduleEntry` to TS-side `SURVEY_SCHEDULE`. Deploy Cloud Function.
3. Add survey questions to client question bank + localization keys (en for MVP).
4. Add submission scoring logic (in `onSurveySubmissionCreated` handler if server-derived; else client-only).
5. Update generic `SurveyViewController` if the new survey needs a different question-rendering style (e.g., a Likert scale variant).
6. Done. Card-rendering, predicate-engine, and notification-dispatch are unchanged — Cloud Function maintains `pendingSurveys` automatically.

---

## 9. Localization

All user-facing strings via `NSLocalizedString()`. **For MVP, `en.lproj/Localizable.strings` is launch-blocking.** zh-TW is deferred to v1.1 — the existing `zh-TW.lproj/Localizable.strings` file remains in the project but new Quest keys are added in en only for MVP. Existing app strings in zh-TW are unaffected.

### 9.1 Key namespace scheme

| Domain | Pattern | Example |
|---|---|---|
| Quest UI | `quest_<feature>_<element>` | `quest_progress_unlock_phase1` |
| Survey questions | `quest_survey_<type>_q<NN>_text` | `quest_survey_importance_q01_text` |
| 8-Dim question (per dimension) | `quest_survey_8dim_<dim>_q<NN>_text` | `quest_survey_8dim_emotional_q01_text` |
| Importance/Satisfaction response options | `quest_importance_response_<1..5>` / `quest_satisfaction_response_<1..5>` | |
| 8-Dim/SoC response options (shared) | `quest_survey_response_<1..5>` | "Not true for me" → "Very true for me" |
| Stage labels (8-Dim, per dimension) | `quest_stage_8dim_<dim>_<1..3>_label` + `_message` | `quest_stage_8dim_emotional_2_label` ("Steady Flame") |
| State-of-Change stage labels (5 friendly) | `quest_stage_soc_<1..5>_label` + `_message` | `quest_stage_soc_3_label` ("Preparing") |
| Importance result messages | `quest_importance_result_first_time_<dim>` / `_followup_<scenario>` | one per dimension |
| Notification copy | `quest_notification_<rule>_title` / `_body` | `quest_notification_importance_title` |

### 9.2 String count (en-only for MVP)

| Domain | Count |
|---|---|
| Importance Check-In questions | 32 |
| Satisfaction Check-In questions | 32 |
| 8-Dim questions (10 × 8 dimensions) | 80 |
| State-of-Change questions | 15 |
| Importance / Satisfaction response options | 5 + 5 |
| 8-Dim / SoC shared response options | 5 |
| 8-Dim stage labels & messages (3 stages × 8 dims × 2 fields) | 48 |
| State-of-Change stage labels & messages (5 × 2) | 10 |
| Importance/Satisfaction result messages (first-time + follow-ups) | ~30 |
| Quest UI strings (cards, buttons, hints, etc.) | ~40 |
| Notification titles + bodies | ~20 |
| **Total (en only)** | **~322 strings — but only en-side authored for MVP** |

**zh-TW deferred to v1.1.** When v1.1 ships, the same 322 keys will need translation.

### 9.3 Survey content reference

Survey question texts and result messages source from the wellness assessment doc (Google Doc `19wH1834cHdwyIuFfT3YkXOHaXOrES78S`). Translate from doc's English wording; zh-TW authored in-house.

### 9.4 State-of-Change friendly stage labels (locked)

| Stage | Internal | User-facing label key | English |
|---|---|---|---|
| 1 | Precontemplation | `quest_stage_soc_1_label` | Considering |
| 2 | Contemplation | `quest_stage_soc_2_label` | Planning |
| 3 | Preparation | `quest_stage_soc_3_label` | Preparing |
| 4 | Action | `quest_stage_soc_4_label` | Doing |
| 5 | Maintenance | `quest_stage_soc_5_label` | Sustaining |

The clinical names from the wellness doc are *not* surfaced to users.

---

## 10. UI conventions

### 10.1 Theme tokens

| Visual element | Token |
|---|---|
| Quest screen background | `.themeBackgroundPrimary` |
| All card backgrounds | `applyGlassCardEffect()` from `ViewComponentConstants` |
| Card title text | `.themeTextPrimary` |
| Secondary/subtitle text | `.themeTextSecondary` |
| Habit increment button background | `.themeButtonSecondary` |
| Take Survey CTA button | `.themeButtonPrimary` |
| Lock icon | `.themeIconMuted` |
| Locked card overlay | `.themeOverlayDimmed` |
| Progress bar fill | `.themeAccent` |
| Progress bar track | `.themeBackgroundSecondary` |
| Radar chart axis lines | `.themeChartAxis` |
| Radar focus dot (highlighted) | `.themeAccent` (with size + glow treatment) |
| Radar non-focus dot (regular) | `.themeAccent` at 0.6 alpha |
| State-of-Change indicator inactive dot | `.themeIconMuted` |
| State-of-Change indicator active dot | `.themeAccent` |

If any token doesn't exist in `Soulverse/Shared/Theme/`, add it during implementation; do not fall back to hardcoded values.

### 10.2 Layout constants

Per `CLAUDE.md`: each Quest view file defines a `private enum Layout` with named values. Shared values in `ViewComponentConstants` (e.g., `navigationBarHeight`, `actionButtonHeight`). **No hardcoded numbers in `snp.makeConstraints`.**

### 10.3 Component reuse

- All cards use `ViewComponentConstants.applyGlassCardEffect()`.
- Notification permission UX uses existing `NotificationPresenter` patterns.
- Locked-card lock affordance uses existing lock-icon assets.

---

## 11. Testing strategy

| Layer | Coverage |
|---|---|
| **ViewModel unit tests** | Survey scoring (Importance/8-Dim/SoC/Satisfaction); radar chart rendering rules; predicate composition (`composeSurveySection`); day-bucket logic; custom habit form validation; tie-breaker chain (all 3 levels); locked-card hint copy proximity logic |
| **Presenter unit tests** | Quest tab state transitions; Day-1 Mood Check-In CTA deep-link; survey submission flows (4 surveys); custom habit creation flow; pending deck rotation after submission |
| **Service unit tests (Firestore Emulator)** | `FirestoreQuestService` round-trips; `FirestoreHabitService` atomic increments; `FirestoreSurveyService` write-once enforcement |
| **Cloud Function tests (Functions Emulator)** | `onMoodCheckInCreated` increment correctness across timezone scenarios; `onSurveySubmissionCreated` per-survey-type field updates; Importance focus assignment with all 3 tie-breaker levels; `questNotificationCron` predicate evaluation; idempotency under repeated invocation |
| **Security Rules tests (Rules Emulator)** | Cross-user write attempts denied; write-once enforcement on `survey_submissions`; server-only on `notification_state`; `serverTimestamp()` enforcement on `mood_checkins.createdAt` |
| **UI tests (XCUITest)** | Day-7 → Importance Check-In → focus-assigned flow; deck-of-cards interaction (tap front, watch next survey rotate forward); locked card hint copy variants; custom habit form validation |
| **Manual QA checklist** | Cross-timezone scenarios (mood check-in vs habit asymmetry); travel from UTC+8 → UTC-5 mid-day to verify habit data lands in expected bucket and `quest_habit_timezone_shift_detected` analytics fires; DND / Do Not Disturb push delivery; OS-notifications-disabled re-take in-app surfacing; both en and zh-TW visual fit; tie-breaker telemetry (`tieBreakerLevel` field) recorded for ties at all 3 levels; deck-of-cards rotation animation polish; locked-card hint copy variants at 1/X, 6/7, 13/14, 20/21 progress states |

### 11.1 Build verification

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

### 11.2 Cloud Function emulator setup

```bash
cd functions
npm install
firebase emulators:start --only functions,firestore,auth
```

---

## 12. Pre-launch infrastructure checklist

These are non-engineering items but they are launch blockers.

- [ ] Firebase project on **Blaze plan** with credit card on file (required for Cloud Functions).
- [ ] APNs auth key (`.p8`) generated in Apple Developer Portal; key ID and team ID captured.
- [ ] APNs key uploaded to Firebase project (Project Settings → Cloud Messaging → APNs Authentication Key).
- [ ] `Messaging.messaging()` setup uncommented in `AppDelegate.swift` (currently disabled per existing codebase).
- [ ] `MessagingDelegate` implemented to receive token via `messaging(_:didReceiveRegistrationToken:)`.
- [ ] FCM token persistence wired: on token receive, write `users/{uid}/devices/{deviceId}` per §4.5.
- [ ] **Notification permission UX (revised Phase 5)** requested at **registration completion** (right after the user successfully creates their account). Use the **system iOS dialog directly** — no custom soft pre-prompt UX. If denied, in-app surfacing covers re-takes per §6.
- [ ] APNs production entitlement confirmed for App Store builds.
- [ ] Cloud Logging quota / retention set; Cloud Monitoring alert on function error rate >5% over 1-hour rolling window.
- [ ] `firebase.json` and `firestore.indexes.json` updated with single-field index on `quest_state.notificationHour` (ascending).
- [ ] Firestore Security Rules deployed; rule-emulator tests passing.
- [ ] `en.lproj/Localizable.strings` complete with all Quest keys (~322 strings). **zh-TW deferred to v1.1**.

---

## 13. Implementation risks and caveats

Carry these into the implementation plan as explicit gates or watch items:

1. **Security Rules implementation gate** — §7.2 is a design-stage sketch. Engineering must finalize and pass Firestore Rules Emulator tests before launch.

2. **Blaze plan prerequisite** — Confirm credit-card-on-file owner before any Cloud Functions deploy.

3. **Scale-out path** — At ~10k matched users/hour, the cron processes sequentially within the 9-min timeout. Beyond that, sharding via Pub/Sub fan-out is the v1.1 evolution. Flag if MVP launch exceeds that scale before that work lands.

4. **zh-TW localization deferred to v1.1** — only en is launch-blocking. When v1.1 picks up zh-TW, the deliverable is ~322 strings.

5. **Custom-habits threat model deferral** — Single-user shape corruption is acceptable for MVP per §7.2. Revisit if threat model tightens.

6. **D21 checklist as acceptance gates** — Each pre-launch infrastructure item must be tracked in the implementation plan as an explicit gate, not as a TODO comment.

7. **Cross-timezone habit bucket** — The asymmetric date-key rules (§6.2) are a known UX edge. Watch for user-research feedback; v1.1 fix would capture per-write timezone in a parallel `habit_logs` collection.

8. **Day-7 announcement merged into Importance Check-In submission flow** — There is no separate post-Day-7 modal. The "your top priority is X" moment is part of the Importance Check-In submission UX. Engineers should not build a separate announcement screen.

9. **Day-21 completion celebration UI is out of MVP scope** — No special "Quest Complete!" screen; just the natural progress-bar-hides + State-of-Change-becomes-pending transition. Product may design this later.

10. **MVP radar chart only renders one dot** — The multi-dot rendering branch is unreachable in MVP (no dimension switching). Code should still implement it for v1.1.

11. **Multi-pending deck rotation animation** — The deck-of-cards visual (offset stack, "+N more" badge, rotation after submission) is a notable UI investment. Allocate design + animation polish time.

13. **Existing `QuestRadarChartView` refactor (Phase 5)** — Existing class uses DGCharts polygon-fill rendering. New design (per §5.2) requires per-axis individual dots + lock icons + center EmoPet, no polygon. Refactor approach: keep web/grid/axis-label setup; disable `drawFilledEnabled`; add overlay UIImageView layer for state-aware dots, lock icons, and EmoPet. EmoPet asset must be sourced from existing app assets if available, or product must provide.

14. **Generic `SurveyViewController` and `SurveyResultViewController`** — Phase 5 consolidated four per-survey controllers into one generic controller parameterized by survey type. The controller renders questions from the bundled question bank for the given type, applies the type-specific response scale (importance / satisfaction / agreement / frequency), and submits via `FirestoreSurveyService`. Each response captures `questionKey` + `questionText` snapshot for self-describing data.

12. **Survey question banks are large** — 159 question texts before stage labels and result messages. Bundle in client code, but organize by survey type in separate files to keep each file scannable.

---

**End of design specification.**
