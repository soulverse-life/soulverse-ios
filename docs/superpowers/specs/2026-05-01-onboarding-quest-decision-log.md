# Onboarding Quest — Decision Log

**Status:** In multi-agent review (Phase 2)
**Primary Designer:** Claude (Opus 4.7, 1M context)
**Date opened:** 2026-05-01
**Branch:** `feat/onboarding-quest`

This log records every locked decision from the single-agent brainstorming phase plus any revisions during multi-agent review. Each entry: **Decision · Alternatives considered · Objections raised · Resolution.**

---

## Source materials

1. Product spec (provided in chat by user, 2026-05-01)
2. Quest screen overview screenshot (`~/Desktop/quest/overview.png`)
3. Wellness assessment doc (Google Doc `19wH1834cHdwyIuFfT3YkXOHaXOrES78S`) — contains 8-Dimension surveys, State-of-Change survey, monthly assessment schedule
4. Codebase survey of `/Users/mingshing/Soulverse` (Quest tab skeleton exists; mood check-ins persist to `users/{uid}/mood_checkins/{id}` with no streak field; `UNUserNotificationCenter` wired; Firebase Messaging imported but not active; no surveys or habit tracker exist)

---

## Locked decisions (Phase 1)

### D1 — Day counter
- **Decision:** Distinct calendar days with ≥1 mood check-in. Day boundary = user's local time, derived from `timezoneOffsetMinutes` already stored on each check-in record.
- **Bucketing rule (locked Phase 2):** Day key = `YYYY-MM-DD` computed by applying the record's *own* stored `timezoneOffsetMinutes` to its `createdAt` timestamp. So a check-in's bucket is determined by where the user **was** when they made it. Travel-day case: a user who flies UTC+8 → UTC-7 and checks in on both ends will register **two** distinct days (defensible — they were in two different local days).
- **DST/clock-change behavior (acknowledged limitation):** Best-effort, trusts device clock at write time. Manual clock abuse is out of MVP scope and not defended against.
- **Alternatives:** Count of records (gameable in 1 day); calendar days regardless of activity (doesn't tie to engagement); any-quest-activity (couples Quest progression to habit tracker).
- **Phase 2 objections:** #1 (offset bucketing rule undefined), #2 (DST/clock abuse).
- **Resolution:** Locked with bucketing rule clarified and DST behavior acknowledged.

### D2 — Focus dimension assignment via Importance Check-In (revised Phase 4, user-driven)
- **Decision:** Focus dimension is determined by the user's **Importance Check-In** survey response, not by mood-check-in topic frequency. The Importance Check-In is now in MVP scope (was previously out-of-scope until Phase 4).
- **Flow:**
  1. User reaches Day 7 (7th distinct mood-check-in day).
  2. `MilestoneDay7` push notification invites them to take the Importance Check-In.
  3. User opens app → Survey section's PendingSurveyDeck shows Importance Check-In as the front (and only) card.
  4. User completes the 32-question survey.
  5. Submission is written to `survey_submissions` with computed 8-category means.
  6. `onSurveySubmissionCreated` Cloud Function detects `surveyType: importance_check_in`, picks the top category using the tie-breaker chain below, and writes `quest_state.focusDimension`.
  7. The Importance Check-In submission's result screen shows the wellness doc's "first-time score" message ("Your top priority is {focus}…") — this replaces the previously-planned separate Day-7 in-app announcement pop-up (D4 obsoleted in Phase 4).
- **Tie-breaker chain (locked Phase 4):**
  1. **Primary:** highest mean score across the 8 categories.
  2. **Secondary** (when primary ties): the tied dimension whose value appears most frequently as a `topic` in the user's `mood_checkins` to date. (This is where mood-check-in topic data still has signal — as a tie-breaker, not a primary source.)
  3. **Tertiary** (when primary and secondary both tie): predetermined order — Physical → Emotional → Social → Intellectual → Spiritual → Occupational → Environmental → Financial.
- **Tie-breaker telemetry:** `survey_submissions/{id}.payload.computed.tieBreakerLevel` records which level (1, 2, or 3) decided the focus, for analytics.
- **Re-take behavior:** Importance Check-In is **re-takeable on a 7-month cadence** (every 210 days since last submission). On re-take, the focus dimension is **re-derived** by the same tie-breaker chain. **In MVP, the re-take's recomputed focusDimension is written to `quest_state.focusDimension`** — but per D8, dimension switching during MVP is out-of-scope, so practically the re-take usually re-confirms the same focus. If user inputs change such that re-take produces a *different* top category, the new value still gets written; v1.1's switching feature will surface this transition explicitly.
- **D16 obsolete:** topic-to-dimension mapping is gone; topic enum and dimension enum share vocabulary (Phase 3 clarification still holds).
- **Phase 2 objection #3 still resolved:** tie-break and unmapped-fallback rules are stricter and more deterministic now.
- **Resolution:** Locked.

### D3 — Stage progression mechanics
- **Decision:** Pure day-count progression. Stage 1 = Days 1–7, Stage 2 = Days 8–14, Stage 3 = Days 15–21. Quest ends at Day 21. No task gates.
- **Acknowledged trade-off (Phase 2):** A user can graduate (reach Day 21) with 21 mood check-ins and zero engagement with surveys, habits, or any other Quest content. "Quest complete" is an engagement signal only insofar as 21 check-ins requires sustained app open behavior — it is *not* a signal of full feature engagement. Downstream metrics (e.g., "engaged graduates") will need a separate definition that adds activity gates outside the Quest state machine.

- **Day-21 completion celebration (revised Phase 3 — out of MVP scope):** No dedicated CompletionCard or "Quest Complete!" UI in MVP — product hasn't designed it yet. The User Advocate's recommendations for personalized stats and disengaged-graduate copy (originally accepted in Phase 2) are deferred to a future iteration when product designs the celebration moment. For MVP at Day 21+, the only Quest screen change is: top progress bar hides per D10. The State-of-Change survey availability surfaces normally through the Survey section's PendingSurveyDeck.
- **Alternatives:** Day-count + task gate (e.g., "must complete 8-Dim survey to advance to Stage 3") — adds stuck-states; explicitly rejected.
- **Phase 2 objections:** #4 (engagement-less graduation).
- **Resolution:** Locked with trade-off acknowledged in product copy/metrics — no design change.

### D4 — Topic announcement (OBSOLETE — Phase 4)
- **Status:** This decision is replaced by the Importance Check-In flow (D2 revised). The "Day-7 announcement pop-up" was for the auto-pick mechanism; with explicit Importance Check-In, the announcement moment becomes the survey's submission-result screen instead. The wellness doc's "first-time score" message ("Thank you for your first check-in. Your top priority is {focus}…") shows on the result screen.
- **`day7AnnouncementAcknowledgedAt` field removed** from `quest_state`. Replaced by the survey-submission timestamp.
- **Persistent in-app banner** for unacknowledged announcement: replaced by the PendingSurveyDeck's natural rendering of Importance Check-In as a pending card.
- **Day-7 reveal moment:** is now wholly inside the Importance Check-In's submission-result screen.
- **Original (now obsolete) decision text follows for historical context:**

ORIGINAL (Phase 1–3, NO LONGER IN EFFECT):
- One-shot pop-up after Day 7 announces the auto-picked focus dimension. No user choice. Pop-up acknowledges-once (does not re-prompt).
- **Persistence (locked Phase 2):** Acknowledgement state lives in **Firestore** at `users/{uid}/quest_state` with field `day7AnnouncementAcknowledgedAt: timestamp | null`. Server-side persistence ensures cross-device consistency.
- **Trigger surface (locked Phase 2):** The pop-up is in-app only — driven by the Quest screen reading `distinctCheckInDays >= 7 AND day7AnnouncementAcknowledgedAt is null` on Quest tab entry. The push notification (D11 `MilestoneDay7`) is a separate channel that nudges the user *to open the app*; the in-app pop-up is what actually shows the focus dimension. They are decoupled — push delivery has no effect on whether the pop-up fires.
- **Recovery from accidental dismissal:** Even after dismissal, the focus dimension is visible at all times on (a) the Survey card's "8-Dim available" state, (b) the radar chart once 8-Dim is submitted, and (c) the Quest screen's existing dashboard layout. No re-prompt of the pop-up itself.

- **Pop-up content (locked Phase 2 — addresses User Advocate #2, #3, #14, #15):** The pop-up is informational but must include:
  1. **Headline:** "Your focus area is **{Dimension}**" with the dimension shown prominently.
  2. **Why this dimension** (transparency — addresses #2, #3): "Based on your most-frequent topics from the past {N} days." Optionally show top 1–3 mood-check-in topics with their dimension mappings ("Work → Occupational, Sleep → Physical, Stress → Emotional"). This makes the algorithm legible.
  3. **Date range disclosure** (addresses #14): "We considered your check-ins from {firstCheckInDate} to {today}." Prevents the surprise of stale data driving the choice for users with non-contiguous check-in patterns.
  4. **Future-flexibility reassurance** (addresses #2): "After your 21-day Quest, you can re-take this for any dimension you like." Removes the trapped feeling.
  5. **Call to action:** "Start exploring →" — which dismisses the pop-up and (post-Phase 2) acknowledges via Firestore.
- **Persistent in-app surface when pending (locked Phase 2 — addresses User Advocate #15):** Treat the in-app pop-up as the canonical "Day 7 reveal" moment, not the push notification (which is just an invitation to come see the reveal). Whenever the predicate `distinctCheckInDays >= 7 AND day7AnnouncementAcknowledgedAt is null` is true, the Quest screen surfaces a persistent "Your focus is ready! Tap to reveal" banner at the top — even if the modal was dismissed without the action button. Push delivery (Do Not Disturb, denied permissions, etc.) doesn't gate the reveal.
- **App killed before display:** Firestore is the source of truth — next Quest tab entry re-evaluates the predicate. No pop-up state lives only in memory.
- **Alternatives:** Re-prompt-until-acknowledged (rejected after user said "keep it simple"); user-picks-from-top-2 (rejected — auto-pick chosen).
- **Phase 2 objections:** #5 (dismissal/reinstall recovery).
- **Resolution:** Locked with persistence and re-display surfaces specified.

### D5 — Locked content card UX
- **Decision:** All cards visible from Day 1, locked cards dimmed with lock affordance. Tap on locked card shows a context-aware hint (see proximity-based copy below).
- **Day-1 explicit Mood Check-In CTA (locked Phase 2 — addresses User Advocate #1):** The progress section at the top of the Quest screen must include a tappable "Do today's Mood Check-In →" CTA whenever the user hasn't yet checked in today. The CTA deep-links to the Mood Check-In tab. Without this, users land on the Quest tab on Day 1 with zero affordance to begin the loop — "check in" happens on a separate tab and the connection isn't obvious.
- **Empty-state explanation:** below the progress dots, one short sentence: "Quest progress is earned through daily Mood Check-Ins. Each new day with a check-in moves you forward." (localization key: `quest_progress_empty_state_explanation`)
- **Proximity-based locked-card hint copy (locked Phase 2 — addresses User Advocate #6):**
  - When user is **far** (>3 days from unlock): tap shows what unlocks ("On Day 14, you'll create your own habit." `quest_locked_card_far_<feature>`)
  - When user is **close** (≤2 days from unlock): tap shows excitement ("Just 2 more check-ins!" `quest_locked_card_close`)
  - When user is **at threshold** (count == X-1): tap shows "Just 1 more check-in!" `quest_locked_card_one_away`)
- **Alternatives:** Hidden until unlocked (rejected — telegraphs less of the journey); flat numeric copy (rejected by Phase 2 — discouraging at low progress, dull at high).
- **Phase 2 objections:** User Advocate #1, #6.
- **Resolution:** Locked with proximity copy + Day-1 CTA.

### D6 — Default habits
- **Decision:** Three fixed defaults — Exercise (unit: min, increments: +5/+10/+15/+30), Water (unit: ml, increments: +100/+200/+300), Meditation (unit: min, increments: +5/+10/+20). Daily reset at user's local midnight. No per-habit goals.
- **"User's local midnight" definition (locked Phase 2):** Date key for habit increment writes = `YYYY-MM-DD` in the device's *current* timezone at write time. "Today" view in the UI uses the same. This is a different rule than D1 (which uses each record's *stored* offset for the day-counter). Habits don't carry per-record offsets — each tap is a write to a date-keyed field, and we use device-now consistently.
- **Acknowledged cross-timezone limitation:** A user who logs Exercise +30 at 23:55 in UTC+8, then immediately flies to UTC-5, then taps Exercise +10 — the second tap writes to a *different* date key (yesterday in UTC-5 terms). The user may perceive it as "today" but the data lands in yesterday's bucket. No correction in MVP. Documented for QA.

- **Reset surprise mitigation (locked Phase 2 — addresses User Advocate #9):** Habit cards must defuse the midnight-reset feeling-of-erasure with two affordances:
  1. A small "**Today**" label + reset-time hint (`quest_habit_today_label` and `quest_habit_resets_at_midnight`) on each habit card subtitle, so the user understands the scope of the displayed total.
  2. When the user has nonzero data from yesterday (`daily.{yesterday-date-key}.{habitId} > 0`), show a one-line "Yesterday: {N} {unit}" reference in small type below today's total. This dissolves the anxiety that effort was deleted — the data is preserved, just under a different label. (`quest_habit_yesterday_total`)
- **No "history view" in MVP** beyond the yesterday-reference. Full month/avg views can come in a future iteration; the data model already supports computing them.
- **Alternatives:** Per-record offset (rejected — habits don't have a "context" to capture; would require asking user "is this counting for today or yesterday?"); UTC-only buckets (rejected — confuses users on the boundaries).
- **Phase 2 objections:** #6 (HIGH — local midnight undefined).
- **Resolution:** Locked with timezone rule specified.

### D7 — Custom habits (Day 14+)
- **Decision:** **Exactly 1 active slot in MVP**, unlocks at Day 14. Form: name (text) + unit (free text) + 3 increment values (numeric). Soft-deletable (sets `deletedAt`, preserves historical totals).
- **"1 slot" semantics (locked Phase 2 — addresses User Advocate #11):** "1 slot" means **1 active (non-deleted) custom habit at a time**. Soft-deleting frees the slot — the user can create a new custom habit afterward. The Custom Habit creation surface must explicitly state the rule: "You can have 1 custom habit at a time. Deleting it frees the slot for a new one." (`quest_custom_habit_slot_explanation`). The deletion confirmation dialog reinforces the same: "Delete '{Name}'? You can create a new custom habit after this." (`quest_custom_habit_delete_confirm`)
- **Form validation (locked Phase 2 — addresses User Advocate #10):**
  - **Name:** required, 1–24 characters, trimmed.
  - **Unit:** required, 1–8 characters, trimmed (e.g., "min", "ml", "pages", "cups").
  - **Increment values:** all three required, must be positive integers, must be distinct from one another (no two slots can hold the same value).
  - **Suggestions** based on detected unit text: if user types "min" or "minute" → suggest +5/+10/+15; "ml" → +100/+200/+300; "page" or "book" → +1/+5/+10. Suggestions are pre-filled but editable.
  - **Live preview**: as user types name + unit + increments, render a preview of the resulting habit card below the form so the user sees what they'll get.
  - **Save button** disabled until all validators pass.
- **Forward-compatibility framing dropped (Phase 2):** The earlier "data model supports future subscription-tier expansion to 2 or 3 slots" framing is removed (YAGNI). When subscriptions ship later, the data model can be revisited then. **Build for 1 slot.**
- **Alternatives:** Name-only counter (rejected — too thin); milestone-based slot expansion (rejected — gating belongs to subscription system that doesn't exist yet).
- **Phase 2 objections:** #14 (YAGNI on forward-compat), User Advocate #10 (validation), User Advocate #11 (slot semantics).
- **Resolution:** Locked at 1 active slot with full validation rules.

### D8 — Focus-dimension switching (revised Phase 3, user-driven)
- **Decision (MVP):** **Not supported.** A user has exactly one focus dimension throughout MVP — the one auto-picked at Day 7. All 8-Dim re-takes (post-Day-21 monthly nudges) are for that same dimension. The radar chart shows exactly one highlighted dot at the focus dim's most-recent wellness stage; other 7 axes are blank.
- **Post-MVP (v1.1+):** A switching mechanism is planned. After it ships, completed dimensions will appear on the radar chart as regular dots at their most-recent wellness stage; the current focus dim will be visually highlighted. The chart's rendering code in MVP must already support the multi-dim case so v1.1 doesn't require a chart rewrite.
- **Screenshot copy correction:** The Survey card's "switch your focus dimension and explore different growth paths" copy must be removed for MVP.
- **Alternatives:** Allow switching mid-Quest (rejected); allow per-re-take dimension choice in MVP (rejected — Phase 3, scope tightened).
- **Phase 3 origin:** user-driven — earlier draft incorrectly allowed re-take dimension choice.
- **Resolution:** Locked at single-focus-dim, no switching in MVP.

### D9 — Survey section composition (revised Phase 3, user-driven post-Arbiter)

**Phase 3 revision rationale:** The original 5-state machine conflated `(surveyType × lifecycle)` into a single card, making extension to a third or fourth survey type combinatorially expensive and unable to express "two surveys pending simultaneously" cleanly. User feedback (post-Arbiter) replaced it with a generic two-component composition. No data model changes; only client-side UI composition logic differs.

#### Composition

The "Survey card" in the screenshot becomes a **Survey section** containing two component lists composed dynamically from `quest_state` + the recent `survey_submissions`:

1. **PendingSurveyDeck** — at most one **deck-of-cards** surface. The deck shows the oldest-pending survey as the front card, with a **visual stacking effect** (offset cards peeking behind, slightly scaled-down and dimmed) to indicate additional pending surveys. Tap the front card → take that survey. After submission, the next-oldest pending survey rotates to the front.
   - "Oldest" = earliest `eligibleSince` timestamp, computed from the rule predicate.
   - If only one survey is pending → render a single card (no stacking visual).
   - If 0 pending → no PendingSurveyDeck.
   - If 3+ pending → optionally show a "+N more" badge on the deck (low priority; defer if not needed).
2. **RecentResultCardList** — 0..M cards stacked **vertically** (not deck-style), sorted by submission date (newest first). One card per recent submission within its survey's `recentResultWindowDays`. If a survey is currently *pending*, its result card is suppressed (avoids stale ghosts).
3. **Hidden when locked (revised Phase 3, user-driven):** When `distinctCheckInDays < 7`, the entire Survey section is hidden — no placeholder card. The Stage 1 experience focuses visually on the Habit Checker (the only unlocked content) without competing locked elements. This is an intentional exception to D5's "all locked cards visible" rule, applied only to the Survey section.

#### Survey definition registry (extensibility hook)

```swift
enum SurveyType: String, CaseIterable {
    case eightDim       = "8dim"
    case stateOfChange  = "state_of_change"
    // Future surveys plug in here without changing card composition logic
}

struct SurveyDefinition {
    let type: SurveyType
    let displayTitleKey: LocalizedKey
    let estimatedMinutes: Int
    let isPending: (QuestState) -> PendingReason?    // nil if not pending
    let eligibleSince: (QuestState) -> Date?         // for deck ordering
    let recentResultWindowDays: Int
}

enum PendingReason {
    case firstTimeAvailable(focus: WellnessDimension)
    case reTakeDue(daysSinceLastSubmission: Int)
}
```

#### MVP survey definitions (revised Phase 4 — config-driven)

The schedule is defined declaratively in a single config (see new D23 below), driving both the rule engine (server) and Survey section composition (client).

| Survey | First-time eligible | Re-take cadence | recentResultWindowDays |
|---|---|---|---|
| **Importance Check-In** | distinctCheckInDays ≥ 7 | every 210 days (7 months) since last submission | 7 |
| **8-Dim** | distinctCheckInDays ≥ 7 AND focusDimension assigned (= Importance submitted) | every 30 days since last submission | 7 |
| **State-of-Change** | distinctCheckInDays ≥ 21 AND focusDimension assigned | every 90 days since last submission | 7 |
| **Satisfaction Check-In** | calendar days ≥ 90 since `questCompletedAt` | every 180 days since last submission | 7 |

Note: 8-Dim and State-of-Change predicates now require `focusDimension assigned`, which couples them to Importance Check-In completion. If the user reaches Day 21 without taking Importance Check-In, only Importance is pending — 8-Dim and State-of-Change stay locked behind it.

#### Pending logic (suppression rules)

- A pending card for survey type X **suppresses** the result card for the same X (so user sees "take it" not "you took it long ago").
- Suppression is applied at composition time: build pending list first, then filter result list by `surveyType not in pendingTypes`.

#### Stage 1 → 2 transition example

| User state | PendingDeck | ResultList | LockedPlaceholder |
|---|---|---|---|
| Day 1 (no checkins) | — | — | Visible |
| Day 5 (5 checkins) | — | — | Visible |
| Day 7 (just crossed) | 1 card: 8-Dim first-time | — | — |
| Day 10 (8-Dim done) | — | 1 card: 8-Dim summary | — |
| Day 21 (only 8-Dim done) | 1 card: SoC first-time | 1 card: 8-Dim summary | — |
| Day 21 (both done) | — | 2 cards: SoC summary (top), 8-Dim summary (below) | — |
| Day 51 (Quest done, 8-Dim re-take due) | 1 card: 8-Dim re-take | 1 card: SoC summary | — |
| Day 91 (Quest done, both re-takes due) | **2-card deck**: 8-Dim re-take front, SoC re-take stacked behind | — | — |

#### Predicate-driven composition (pseudocode)

```swift
func composeSurveySection(state: QuestState, recent: [SurveySubmission]) -> SurveySectionModel {
    // 1. Build pending list
    let pending = SurveyDefinition.allMVP
        .compactMap { def -> (SurveyDefinition, PendingReason, Date)? in
            guard let reason = def.isPending(state),
                  let since  = def.eligibleSince(state) else { return nil }
            return (def, reason, since)
        }
        .sorted { $0.2 < $1.2 }   // oldest eligibleSince first → front of deck
    
    // 2. Build result list, suppressing types currently pending
    let pendingTypes = Set(pending.map { $0.0.type })
    let results = SurveyDefinition.allMVP
        .filter { !pendingTypes.contains($0.type) }
        .compactMap { def -> RecentResultCardModel? in
            guard let mostRecent = recent.first(where: { $0.surveyType == def.type }),
                  daysSince(mostRecent.submittedAt) <= def.recentResultWindowDays
            else { return nil }
            return def.buildResultCard(mostRecent)
        }
        .sorted { $0.submittedAt > $1.submittedAt }   // newest result on top
    
    // 3. Locked placeholder fallback
    if pending.isEmpty && results.isEmpty && state.distinctCheckInDays < 7 {
        return .lockedPlaceholder
    }
    return .composed(deck: PendingSurveyDeck(cards: pending), results: results)
}
```

#### Why this revision works

- **Two surveys pending simultaneously** (e.g., post-Quest both re-takes due): naturally expressed by a 2-card deck. Old design forced an awkward state-4-with-stacked-summary kludge.
- **N future surveys** (Importance Check-In, Satisfaction Check-In, etc.): add to the registry, no card-composition code changes.
- **Result-card retention window**: configurable per survey type, defaults align with re-take cadence (30/90 days) so the section never goes empty between expiring result and incoming pending.
- **No data model impact**: `survey_submissions`, `quest_state` aggregate, rule engine all unchanged. Only the client's composition logic shifted.

- **Phase 2 objections still resolved** (precedence rule no longer needed since composition handles ordering): #8 (push-disabled users) — the predicate-driven `isPending` is the same engine used by the rule cron, decoupling push from in-app surfacing. #13 (state precedence) — superseded by composition rules above.
- **Phase 3 origin:** user-driven simplification post-Arbiter. Contained scope (UI composition only); does not require re-review.
- **Resolution:** Locked at composition design.

### D10 — State-of-Change UX & radar chart stage indicator
- **Decision:** State-of-Change lives in the same Survey card (as state #4). After the user submits, the radar chart's "current stage" 1-of-5 indicator (the row of dots labeled Stage 1 / Stage 2 / ... / Stage 5 below the chart) becomes visible for the focus dimension. The top progress bar at the top of the Quest screen hides at Day 21.
- **Alternatives:** New dedicated card; modal-only one-shot (rejected — user picked card-based).
- **Objections raised in Phase 1:** None.
- **Resolution:** Locked.

### D11 — Notification architecture (centralized rule engine)
- **Decision:** Single scheduled Cloud Function iterates over users and evaluates a list of rules. Each rule has a predicate and a payload. Idempotency state is stored at `users/{uid}/notification_state/{ruleId}` with `lastSentAt`. Pre-Day-21 milestones become rules in this engine (no separate `onCreate` triggers).
- **Cron cadence (locked Phase 2):** **Hourly**, with each invocation gated by a per-user "is the user's current local time between 09:00 and 09:59?" predicate. Rationale: avoids 2am push deliveries to users in adversarial timezones; cost remains within the Cloud Functions free tier even at 24× the daily-cron rate (each invocation is small).
- **Failure ordering (locked Phase 2):** For each (user, rule) pair, **write `notification_state.{ruleId}.lastSentAt` to Firestore *before* calling FCM `send()`**. Trade-off: prefers a rare missed notification (Firestore write succeeds, FCM call fails) over the more disruptive double-send (FCM succeeds, Firestore write fails). Acceptable for MVP. Cloud Function logging captures FCM failures for manual recovery if needed.
- **MVP notification rule list (revised Phase 4 — config-driven, derived from D23):**

The hardcoded rule predicates are replaced by a generic engine that reads the survey schedule config (D23) plus a small list of milestone-only entries. Each notification fires when `(survey isPending) AND (notification not sent for current eligibility window)`. The rule engine has no per-rule code; it iterates the config.

  - **Survey-driven notifications (one per `SurveyConfig` entry):**
    - Importance Check-In: title "Help us understand what matters to you 🌱", body "Take the 5-minute Importance Check-In to discover your focus area." — fires when first-available predicate goes true; re-take notification fires every 210 days.
    - 8-Dim first-available: title "Time for a fresh reflection 🌿", body "Reflect on your current {focus} stage." — fires when 8-Dim goes pending after Importance submission. Re-takes fire every 30 days.
    - State-of-Change first-available: title "Where are you now?", body "A short reflection on your readiness." — at Day 21 with focus assigned. Re-takes every 90 days.
    - Satisfaction Check-In first-available: title "How's it going?", body "A short check-in on how satisfied you are with each area of your life." — at Day 21 + 90 calendar days. Re-takes every 180 days.

  - **Milestone-only notifications (no associated survey):**
    - `MilestoneDay14` — predicate: `distinctCheckInDays >= 14 AND lastSentAt is null` — body: "Time for a new habit ✨ — Stage 2 unlocked. Add a custom habit to track what matters."
    - `MilestoneDay21` — predicate: `distinctCheckInDays >= 21 AND lastSentAt is null` — body: "Quest complete! 🎉 — Reflect on your readiness with one final survey." (When this fires, the State-of-Change card is becoming pending in the same window — this push functions as the SoC invitation too.)
    - (No standalone `MilestoneDay7`: the Importance Check-In's first-available notification serves that purpose.)
    - (No standalone State-of-Change first-available notification at MilestoneDay21 — they coalesce.)
- **OS-level notifications-disabled users (Phase 2 — addresses #8):** Push delivery is best-effort. Users with notifications disabled still get the *in-app* surface of due re-takes via D9's predicate-driven "available" states. The rule engine's `lastSentAt` is *not* a proxy for "user was informed."

- **Notification body copy (locked Phase 2 — addresses User Advocate #12):** Pushes must avoid jargon. No "8-Dim" or "State-of-Change" in user-facing strings. Required copy for each rule:
  - `MilestoneDay7` title: "Your focus area is ready 🌱" — body: "After a week of reflection, we've found a meaningful focus for you." (`quest_notification_milestone_day7_*`)
  - `MilestoneDay14` title: "Time for a new habit ✨" — body: "Stage 2 unlocked. Add a custom habit to track what matters to you." (`quest_notification_milestone_day14_*`)
  - `MilestoneDay21` title: "Quest complete! 🎉" — body: "Reflect on your readiness with one final survey." (`quest_notification_milestone_day21_*`)
  - `Monthly8DimNudge` title: "Time for a fresh reflection 🌿" — body: "It's been a month since your last check-in on **{focusDimension}**. See how things have shifted." (`quest_notification_monthly_8dim_*`) — Phase 3 revision: dropped the "choose differently" promise since dim-switching isn't in MVP. Body interpolates the user's focus dimension display name.
  - `QuarterlyStateOfChangeNudge` title: "Where are you now?" — body: "A short reflection on your readiness — see what's shifted in the last 3 months." (`quest_notification_quarterly_soc_*`)
- All copy localized in en + zh-TW at launch.
- **Alternatives:** Per-event `onCreate` triggers (rejected — doesn't compose); client-side local notifications only (rejected); daily UTC cron (rejected — adversarial-timezone delivery).
- **Phase 2 objections:** #7 (partial-failure ordering), #8 (notifications-off lockout — addressed via D9 + in-app surfacing), #15 (cron cadence).
- **Resolution:** Locked with cadence, ordering, and in-app fallback specified.

### D12 — Post-Quest experience
- **Decision:** Quest screen becomes a permanent dashboard after Day 21. Top progress bar hidden. Re-takes are surfaced only via push notifications from the rule engine (D11). Re-takes allow the user to choose a different dimension for 8-Dim — that's the only mechanism for filling out the radar chart with multi-dimension data. The wellness doc's full 12-month assessment schedule (Importance / Satisfaction Check-Ins) is **out of MVP scope**.
- **Alternatives:** Light recurring nudges (subset of full schedule); full 12-month schedule (rejected as too large).
- **Objections raised in Phase 1:** None.
- **Resolution:** Locked.

### D13 — Habit data model (Shape α revised)
- **Decision:** Single Firestore document at `users/{uid}/habits/state` with the following shape:

```jsonc
{
  "daily": {
    "YYYY-MM-DD": {
      "exercise":     <int>,   // minutes
      "water":        <int>,   // ml
      "meditation":   <int>,   // minutes
      "<customId>":   <int>    // unit-specific, see customHabits
    },
    ...
  },
  "customHabits": {                      // ← MAP (was array in Phase 1)
    "h_<uuid>": {
      "id":         "h_<uuid>",
      "name":       "<user-typed name>",
      "unit":       "<user-typed unit string>",
      "increments": [<int>, <int>, <int>],
      "createdAt":  <timestamp>,
      "deletedAt":  <timestamp | null>
    }
  }
}
```
- **`customHabits` is a map keyed by habit id, not an array (revised Phase 2).** Rationale (#10): mixing `FieldValue.increment` writes (on `daily.<date>.<id>`) with array updates (`arrayUnion`/`arrayRemove`) on the same offline batch can produce merge conflicts. Map-keyed entries use per-field updates throughout, which compose cleanly with offline queueing.
- Each tap of an increment button: `update(ref, { ["daily.<date>.<habitId>"]: FieldValue.increment(<amount>) })`.
- Adding a custom habit: `update(ref, { ["customHabits.<newId>"]: { name, unit, increments, createdAt, deletedAt: null } })`.
- Soft-deleting: `update(ref, { ["customHabits.<id>.deletedAt"]: <timestamp> })`.
- Today / month / avg-per-day all computed client-side from a single doc read.
- Custom habit ids prefixed `h_` to avoid colliding with default semantic keys (`exercise`, `water`, `meditation`).
- **Doc growth (Phase 2 — addresses #9):** ~76 KB/year for 4 active habits (3 default + 1 custom). Hits 1MB Firestore doc limit at ~13 years of continuous use. Acceptable for MVP; archival/rollover plan can be added if/when long-term users approach the limit (very unlikely to be the binding constraint vs. other product evolution).
- **Forward-compat for subscription tiers dropped (Phase 2):** Per D7, build for 1 custom slot. Revisit when subscriptions ship.
- **Alternatives:** Per-day-per-habit doc (rejected — overhead); per-day-all-habits doc with sub-collection (rejected — same); event-log per-tap (rejected — month queries get expensive at scale); array-of-customHabits (rejected after #10).
- **Phase 2 objections:** #9 (doc growth), #10 (HIGH — array-of-customHabits offline merge), #14 (forward-compat YAGNI).
- **Resolution:** Locked at Shape α with `customHabits` as a map, no forward-compat framing.

### D14 — Radar chart rendering (revised Phase 5, user-driven)

**Phase 5 redesign:** the radar chart is now driven by **State-of-Change stages (1–5)**, not 8-Dim wellness stages (1–3). Each axis shows individual dots per stage rather than a connected polygon.

#### Per-axis rules
- **Current focus dim, no SoC submitted yet:** 5 outline dots along the axis at positions 1, 2, 3, 4, 5. No solid dot.
- **Current focus dim, SoC submitted:** 5 outline dots PLUS one **solid** dot at the user's current State-of-Change stage. Re-takes move the solid dot.
- **Previously-focused dim** (post-v1.1 only): single **dim** dot at the State-of-Change stage the user reached when that dim was their focus.
- **Never assessed:** **lock icon** at the outermost position (stage 5 distance) of the axis.
- **Center:** EmoPet image **always** visible.

#### Implementation

Refactor existing `QuestRadarChartView` (`Soulverse/Features/Quest/Views/QuestRadarChartView.swift`):
- Reuse DGCharts axis web/grid setup and labels.
- Disable polygon-fill rendering (`drawFilledEnabled = false`).
- Add overlay UIImageView layer for state-aware dots, lock icons, and EmoPet center.

#### MVP reach

In MVP (no dimension switching), only one axis ever has data:
- Day 1–6 (no focus): 8 axes show lock icons; EmoPet center.
- Day 7+ (focus assigned, no SoC yet): focus axis has 5 outline dots; 7 other axes have lock icons.
- Day 21+ (SoC submitted): focus axis adds the solid stage dot.

#### What about 8-Dim wellness stage?

The 8-Dim survey produces a wellness stage (1–3, e.g. "Steady Flame"). **This stage no longer appears on the radar chart.** It's surfaced only on the survey result view (and the RecentResultCard's tap target).

#### Phase history

- Phase 1: original idea — distance-from-center = 8-Dim wellness stage 1–3.
- Phase 5: complete redesign per user feedback. State-of-Change drives axes; 8-Dim becomes a result-only signal.

- **Resolution:** Locked at Phase 5 design.


- **Decision:**
  - Chart shows 8 axes (one per wellness dimension).
  - Per-dimension dot is rendered iff the user has at least one 8-Dim survey submission for that dimension.
  - Dot distance from center = wellness stage from the 8-Dim survey (1–3 scale).
  - **Highlighted (distinct, attention-grabbing visual treatment — accent color + larger size + glow/halo)** = current focus dimension dot.
  - **Regular solid dot** = a previously-focused dimension with data (post-switch — only reachable in v1.1+ when switching ships).
  - **No dot / ghost marker at center** = dimension never assessed.
  - Below the chart: a separate "current stage" 1-of-5 indicator reflects the State-of-Change readiness stage for the focus dimension only. Hidden until State-of-Change is submitted.
- **Per-dimension result history rule (locked Phase 2 — addresses #11):** When a user re-takes 8-Dim for a previously-assessed dimension, the **most recent submission wins**. Prior submissions for that dimension are preserved in the underlying data store (for future analytics/trend views) but are not rendered on the chart. Same rule applies to State-of-Change.
- **MVP rendering reach (revised Phase 3):** Since dimension-switching is out of MVP scope (D8), only the user's single focus dimension ever has data in MVP. The chart shows exactly one **highlighted** dot at the focus dim's most-recent wellness stage; the other 7 axes are blank/ghost. The "regular dot" rendering branch (for completed-but-not-current dims) is implemented in code but unreachable until v1.1 switching ships. Tested via unit tests, not user-visible in MVP.

- **Single-dot empty-state copy (locked Phase 2 — addresses User Advocate #7):** When the radar chart has only one dot, render the other 7 axes with **placeholder ghost markers** at the center (a faint dot at distance 0 on each axis), and below the chart show one explanatory line: "Your first dimension is mapped! Re-take surveys after Day 21 to fill in the rest of your wellness web." (`quest_radar_single_dot_explanation`) — this prevents the chart from reading as broken/empty.

- **State-of-Change stage labels: user-friendly, not clinical (locked Phase 2 — addresses User Advocate #8):** The 5-stage indicator below the chart MUST NOT use raw "Stage 1 / Stage 2 / ... / Stage 5" labels nor the wellness doc's clinical names (Precontemplation / Contemplation / Preparation / Action / Maintenance). Required user-facing labels (en):
  - Stage 1 → **Considering** (`quest_stage_soc_1_label`)
  - Stage 2 → **Planning** (`quest_stage_soc_2_label`)
  - Stage 3 → **Preparing** (`quest_stage_soc_3_label`)
  - Stage 4 → **Doing** (`quest_stage_soc_4_label`)
  - Stage 5 → **Sustaining** (`quest_stage_soc_5_label`)
  - Plus a one-sentence "what this means for you" message per active stage, displayed below the dots (`quest_stage_soc_<n>_message`). zh-TW translations required at launch.
  - Wording is intentionally aspirational and present-tense to match the wellness app's emotional register.
- **Alternatives:** Static decorative shape (rejected — no informational value); use State-of-Change result for axis distance (rejected — confusing, conflates two surveys); aggregate of multiple submissions (rejected — too clever, hides real values).
- **Phase 2 objections:** #11 (multi-dot dead code; per-dimension overwrite rule).
- **Resolution:** Locked with most-recent-wins rule and MVP reach documented.

### D15 — Survey question bank storage (revised Phase 5)

**Phase 5 update:** zh-TW translation is **deferred to v1.1**. Only en is launch-blocking for MVP. The localization key scheme below remains unchanged; only the en-side strings are authored.

Original decision text follows:


- **Decision:** Bundle survey questions in client code as Swift structs with `NSLocalizedString()` keys. Don't store survey content in Firestore.
- **Localization key scheme (locked Phase 2 — addresses Constraint #11):**
  - Quest UI strings: `quest_<feature>_<element>` (e.g., `quest_progress_unlock_phase1`, `quest_card_8dim_locked_title`).
  - 8-Dim survey questions: `quest_survey_8dim_<dimension>_q<NN>_text` (e.g., `quest_survey_8dim_emotional_q01_text`).
  - 8-Dim response options (always 5): `quest_survey_response_<1..5>` (shared across surveys — reusable since wording is consistent).
  - State-of-Change questions: `quest_survey_soc_q<NN>_text`.
  - State-of-Change response options: `quest_survey_response_<1..5>` (reused).
  - Stage labels (per-dimension wellness stages, e.g., "Quiet Seed"): `quest_stage_8dim_<dimension>_<1..3>_label` and `..._message`.
  - State-of-Change stage names: `quest_stage_soc_<1..5>_label` and `..._message`.
  - Notification copy: `quest_notification_<rule>_title` and `..._body`.
- **Question ordering:** Hardcoded array order in Swift; no `displayOrder` field. Questions are static.
- **zh-TW translations: required at launch.** Both en and zh-TW `Localizable.strings` must be complete before merge to main. Question wording will be sourced from the wellness assessment doc (existing material) and translated in-house.
- **Alternatives:** Firestore-served (rejected — conflicts with project's `NSLocalizedString` localization convention; adds reads).
- **Phase 2 objections:** Constraint #11.
- **Resolution:** Locked with key scheme.

### D16 — ~~Topic-to-dimension mapping table storage~~ (OBSOLETE — Phase 3)
- **Status:** Removed. Phase 3 user clarification: topic == dimension (same enum, same values). No mapping table is needed. The recommendation Cloud Function frequency-counts the `topic` field directly and writes the result to `quest_state.focusDimension` — no translation step in between.
- See revised D2 for the simplified recommendation logic.

### D18 — Aggregate `quest_state` doc and read budget (added Phase 2 — addresses Constraint #1, #2, #3)

The hourly cron iterates only *matched* users via an indexed query, and per-user rule evaluation reads exactly **one** aggregate doc.

#### Aggregate document schema: `users/{uid}/quest_state` (single doc)

```jsonc
{
  // — Day counter & quest progression (maintained by Cloud Function trigger on mood_checkins.onCreate)
  "distinctCheckInDays":          <int>,         // count of unique day-buckets across user's mood_checkins
  "lastDistinctDayKey":           "YYYY-MM-DD",  // most recent day-bucket (so trigger knows when to increment)

  // — Focus dimension & UX state (Phase 4: focus is set by Importance Check-In submission)
  "focusDimension":               "<dimension>", // null until Importance Check-In submitted
  "focusDimensionAssignedAt":     <timestamp>,
  "questCompletedAt":             <timestamp | null>,    // set when distinctCheckInDays first reaches 21 (Phase 4)
  // (day7AnnouncementAcknowledgedAt removed Phase 4 — see D4)

  // — Survey submission timestamps (maintained by Cloud Function trigger on survey_submissions.onCreate)
  "importanceCheckInSubmittedAt":  <timestamp | null>,   // (Phase 4)
  "lastEightDimSubmittedAt":      <timestamp | null>,
  "lastEightDimDimension":        "<dimension>", // which dimension was most recently assessed
  "lastEightDimSummary":          { "stage": <int 1-3>, "label": "<localized key>" },
  "lastStateOfChangeSubmittedAt": <timestamp | null>,
  "lastStateOfChangeStage":       <int 1-5 | null>,
  "satisfactionCheckInSubmittedAt": <timestamp | null>,  // (Phase 4)
  "lastSatisfactionTopCategory":   "<dimension | null>", // (Phase 4)
  "lastSatisfactionLowestCategory": "<dimension | null>", // (Phase 4)

  // — Notification state (server-side authoritative; client read-only)
  // Phase 4: keys are now derived from D23 schedule entries instead of hardcoded
  "notification_state": {
    "importance_check_in_first":  { "lastSentAt": <timestamp | null> },
    "importance_check_in_retake": { "lastSentAt": <timestamp | null> },
    "8dim_first":                 { "lastSentAt": <timestamp | null> },
    "8dim_retake":                { "lastSentAt": <timestamp | null> },
    "state_of_change_first":      { "lastSentAt": <timestamp | null> },
    "state_of_change_retake":     { "lastSentAt": <timestamp | null> },
    "satisfaction_check_in_first":  { "lastSentAt": <timestamp | null> },
    "satisfaction_check_in_retake": { "lastSentAt": <timestamp | null> },
    "MilestoneDay14":             { "lastSentAt": <timestamp | null> },
    "MilestoneDay21":             { "lastSentAt": <timestamp | null> }
    // Phase 4: removed MilestoneDay7 (replaced by importance_check_in_first),
    //          removed Monthly8DimNudge (replaced by 8dim_retake),
    //          removed QuarterlyStateOfChangeNudge (replaced by state_of_change_retake)
  },

  // — Cron query optimization
  "notificationHour":             <int 0-23>,    // user-local 09:00 expressed as UTC hour; indexed
  "timezoneOffsetMinutes":        <int>          // current device offset (updated on app launch)
}
```

#### Aggregate maintenance — replaces ad-hoc client writes

A small set of **lightweight Cloud Function triggers** maintains the aggregate. These triggers are *separate* from the rule-engine cron and exist solely for data-integrity. (Per-event triggers were rejected in D11 only for *notification routing*; using them for aggregate maintenance is a different concern.)

- `onCreate(users/{uid}/mood_checkins/{id})` →
  1. Compute `dayKey` = YYYY-MM-DD using the record's stored `timezoneOffsetMinutes`.
  2. If `dayKey != quest_state.lastDistinctDayKey` → atomic transaction: `distinctCheckInDays++`, `lastDistinctDayKey = dayKey`.
- `onCreate(users/{uid}/survey_submissions/{id})` →
  1. Inspect `submission.surveyType`. Update `lastEightDim*` or `lastStateOfChange*` fields accordingly.
- `onCreate(users/{uid})` (sign-up) → initialize `quest_state` with defaults including `notificationHour = 9 - (timezoneOffsetMinutes / 60)` mod 24.
- App launch (client write) → updates `timezoneOffsetMinutes` and recomputes `notificationHour`.

#### Cron-engine query optimization

The hourly Cloud Function query:

```javascript
db.collectionGroup('quest_state')
  .where('notificationHour', '==', currentUTCHour)
  .stream()
```

- **Index required:** `quest_state.notificationHour` (ascending), single-field index. Set in `firestore.indexes.json`.
- **Read cost:** evenly-distributed users → ~N/24 docs read per hour. At 10k users: ~417 reads/hour → ~10k reads/day. Well under the 50k/day Spark/Blaze free tier.
- **Per-user evaluation cost:** 1 read of `quest_state` (already in the query result) + 0 additional doc reads (everything needed is in the aggregate). Total: 1 read per matched user.

#### Quest tab cold-start read budget

Target: **≤2 doc reads per cold entry to the Quest tab.**
- `users/{uid}/quest_state` (1 read) — drives all UI states (lock, focus dimension, milestone counts, survey availability, summaries).
- `users/{uid}/habits/state` (1 read) — drives habit cards.
- Mood check-ins are **not** re-read on Quest entry; the count lives in `quest_state.distinctCheckInDays`.

In-session caching: Quest presenter caches both docs in memory. Tab-switch re-entry within the session uses cache; full app foreground re-reads.

#### Cost projections (back-of-envelope)
| Metric | At 1k users | At 10k users | At 100k users |
|---|---|---|---|
| Cron reads/day | ~1k | ~10k | ~100k → **moves to ~25 read-window-tightened or sharded approach** |
| Aggregate-trigger writes/day | ~5k (5 events × 1k users) | ~50k | ~500k → still within Spark write quotas |
| Function invocations/day | ~30k (24 + per-event triggers) | ~300k | ~3M → likely exceeds free tier |

**Take-away:** design holds free-tier through ~10k users. Beyond that, sharding + read-windowing is straightforward but should be flagged as a v1.1 task.

- **Phase 2 objections addressed:** Constraint #1, #2, #3, plus partially #7 (self-correction now trivial because predicates use `lastSubmittedAt`, not `lastSentAt`).
- **Resolution:** Locked.

---

### D17 — Cross-cutting account/device state (added Phase 2)
- **Decision:** All Quest progression and state lives under `users/{uid}/...` in Firestore — UID-scoped. This includes:
  - `users/{uid}/quest_state` (focus dimension, day7 announcement ack, milestone counters)
  - `users/{uid}/notification_state/{ruleId}` (per-rule lastSentAt)
  - `users/{uid}/habits/state` (single habit doc)
  - `users/{uid}/survey_submissions/{submissionId}` (8-Dim and State-of-Change results)
  - Existing `users/{uid}/mood_checkins/{id}` (already exists)
- **Auth-provider change behavior:** Soulverse's existing auth flow assigns a new UID when a user changes auth providers (Apple → Google, etc.). The Quest does not migrate across UIDs — it restarts at Day 1 with the new account. This matches existing app behavior for other features.
- **Account deletion behavior:** Deleting an account removes all `users/{uid}/...` data including Quest state. Re-creating an account (same email, new UID) restarts Quest at Day 1.
- **Cross-device persistence:** Sign-in on a new device with the same UID restores Quest state in full. No device-local-only state outside ephemeral UI animation state.
- **FCM device token (server-side push):** Stored at `users/{uid}/devices/{deviceId}` so multiple-device users get pushes on each device. Token registration happens at app launch and on token refresh.
- **Rationale:** Phase 2 objection #12 surfaced that the original log didn't address account/device migration. This decision documents existing app behavior + Quest-specific implications.
- **Phase 2 objections:** #12 (cross-cutting state).
- **Resolution:** Locked.

### D19 — Firestore Security Rules (added Phase 2 — addresses Constraint #4, #5, #8)

All Quest-related paths require explicit Security Rules. Sketch (final form to be authored alongside engineering):

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {

    match /users/{uid} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow create: if request.auth != null && request.auth.uid == uid;

      // Mood check-ins — server-stamped createdAt is required
      match /mood_checkins/{checkinId} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.createdAt == request.time
                      && request.resource.data.timezoneOffsetMinutes is int
                      && request.resource.data.timezoneOffsetMinutes >= -840
                      && request.resource.data.timezoneOffsetMinutes <= 840;
        allow update, delete: if false;  // immutable
      }

      // Aggregate quest_state — most fields server-only; client may set day7AnnouncementAcknowledgedAt once
      match /quest_state/{document=**} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid;  // sign-up trigger initializes
        allow update: if request.auth.uid == uid
                      && request.resource.data.diff(resource.data).affectedKeys()
                          .hasOnly(['timezoneOffsetMinutes', 'notificationHour',
                                    'day7AnnouncementAcknowledgedAt']);
        allow delete: if false;
      }

      // Habit doc — client writes daily.* increments and customHabits.* additions/soft-deletes
      // (see threat-model note below for shape limitations)
      match /habits/state {
        allow read, write: if request.auth.uid == uid;
      }

      // Survey submissions — write-once
      match /survey_submissions/{submissionId} {
        allow read: if request.auth.uid == uid;
        allow create: if request.auth.uid == uid
                      && request.resource.data.submittedAt == request.time;
        allow update, delete: if false;
      }

      // Notification state — server-only (Admin SDK bypasses rules; clients fully blocked)
      match /notification_state/{ruleId} {
        allow read: if request.auth.uid == uid;
        allow write: if false;
      }

      // Device tokens — strict per-uid write
      match /devices/{deviceId} {
        allow read, write: if request.auth.uid == uid;
      }
    }
  }
}
```

#### Custom-habits shape threat model (addresses Constraint #5)

Firestore Security Rules cannot iterate map values to validate shape, nor enforce map cardinality (the 1-slot MVP cap from D7). Therefore:
- **Threat:** A malicious user with valid auth can write garbage into their own `habits/state.customHabits` (e.g., 100 habits, malformed shapes, oversized strings), bloating their own document. The 1MB doc limit is a natural ceiling, but they can still corrupt their own UI before that.
- **Impact:** Single-user data corruption only — **no cross-user impact**, no privilege escalation, no data exfiltration.
- **Mitigation in MVP:** Client enforces 1-slot cap and field shapes. Threat is acceptable: a user breaking their own UI is recoverable (they can soft-delete or the support team can manually clean their doc).
- **Future hardening:** if the threat model tightens, migrate `customHabits` to a sub-collection with per-doc rules + `count()` aggregation. Defer to v1.1.

#### Server-side timestamps (addresses Constraint #8)
- `mood_checkins.createdAt` — set via `FieldValue.serverTimestamp()` on the client; rule asserts equality with `request.time`.
- `survey_submissions.submittedAt` — same pattern.
- `quest_state.day7AnnouncementAcknowledgedAt` — accepts client value (it's just a "user saw the dialog" flag; spoofing it has no privilege impact).
- All notification_state writes happen via Admin SDK in Cloud Functions, bypassing rules.

#### Device-token writes (addresses Constraint #4 sub-point)
- Path is `users/{uid}/devices/{deviceId}` and rule requires `request.auth.uid == uid`. **Cross-user token hijack is blocked.**
- The `deviceId` itself can be any client-chosen string (typically the FCM token's installation ID). Recommend the client use the iOS `vendor identifier` or FCM-provided ID.

- **Phase 2 objections:** Constraint #4 (Security Rules unspecified), Constraint #5 (custom-habits enforcement), Constraint #8 (server-authoritative timestamps).
- **Resolution:** Locked.

### D20 — Cloud Functions deployment & monitoring (added Phase 2 — addresses Constraint #6, #10)

- **Source location:** `functions/` directory at the repo root, alongside the iOS workspace. Standard Firebase Functions project layout. Same git history.
- **Language:** TypeScript. Idiomatic for Firebase Admin SDK; type safety reduces bugs in payload shaping.
- **Function generation:** Gen 2. Required for the 9-minute scheduled-function timeout (vs. Gen 1's 60-second cap).
- **Functions to deploy:**
  | Function | Trigger | Purpose |
  |---|---|---|
  | `questNotificationCron` | `pubsub.schedule('every 1 hours')` | Hourly rule-engine evaluation |
  | `onMoodCheckInCreated` | Firestore onCreate `users/{uid}/mood_checkins/{id}` | Increment `quest_state.distinctCheckInDays` if new day-bucket |
  | `onSurveySubmissionCreated` | Firestore onCreate `users/{uid}/survey_submissions/{id}` | Update `quest_state.lastEightDim*` or `lastStateOfChange*` |
  | `onUserCreated` | Auth `onCreate` (or first sign-in trigger) | Initialize `quest_state` doc for new users |
- **Batching strategy (`questNotificationCron`):** Process matched users sequentially within the 9-minute timeout. At expected MVP scale (≤10k users, ~417 matches/hour), this completes in well under 60 seconds. **Scale-out path** (v1.1, when matched-user count exceeds ~10k/hour): split into Pub/Sub fan-out — scheduler emits one message per N-user batch; each message triggers a function instance.
- **Resume semantics:** if `questNotificationCron` exits before completing all users, the next hourly invocation re-queries the same `where notificationHour == currentUTCHour` predicate. Self-healing because (a) `MilestoneDay*` rules are idempotent via `notification_state.lastSentAt`, and (b) recurring rules' predicates use `lastSubmittedAt`, not `lastSentAt`, so a missed cron re-evaluates true the next hour.
- **Self-correction guard:** ignore `lastSentAt > now` (clock skew protection). Re-fire if encountered.
- **Deploy mechanism:** manual `firebase deploy --only functions` for MVP. CI integration via GitHub Actions deferred to v1.1.
- **Monitoring (MVP minimum):**
  - Cloud Logging: structured logs from all functions, severity tagged.
  - Firebase console: function error rate dashboard.
  - Email alert: trigger if any function's error rate exceeds 5% over a rolling 1-hour window. Configured via Cloud Monitoring alerting policy.
- **Phase 2 objections:** Constraint #6 (timeout), Constraint #10 (deployment infrastructure), Constraint #7 (self-correction).
- **Resolution:** Locked.

### D21 — Pre-launch infrastructure checklist (added Phase 2 — addresses Constraint #9)

The following items are **not engineering tasks** but are **launch blockers** without owners. Each must be checked off before MVP ships:

- [ ] **Firebase project on Blaze plan** — required for Cloud Functions. Credit card on file. Owner: project admin.
- [ ] **APNs auth key generated in Apple Developer Portal** — `.p8` key, key ID, team ID captured. Owner: iOS dev.
- [ ] **APNs key uploaded to Firebase project** — Firebase console → Project Settings → Cloud Messaging → APNs Authentication Key.
- [ ] **`Messaging.messaging()` setup uncommented** in `AppDelegate.swift` (currently disabled per codebase survey).
- [ ] **`MessagingDelegate` implemented** to receive token via `messaging(_:didReceiveRegistrationToken:)`.
- [ ] **FCM token persistence** wired: on token receive → write `users/{uid}/devices/{deviceId}` per D17.
- [ ] **Notification permission UX (revised Phase 2 — addresses User Advocate #5):** request via `UNUserNotificationCenter.current().requestAuthorization(...)` **immediately after the user taps "Start exploring →" on the Day-7 announcement pop-up**, NOT on first Quest tab entry. Rationale: this places the ask at the moment of earned trust, after the user has experienced one full cycle of value (7 days of check-ins → focus reveal). Pre-prompt soft dialog (in-app, before the OS prompt) explains the value: "We'll send you 3 milestone notifications during your Quest, plus a friendly check-in once a month after." If the user denies, the in-app surfacing per D9 covers them, but a persistent settings-link reminder ("Notifications are off — turn on for milestone reminders") appears on the Quest screen.
- [ ] **APNs sandbox vs. production** — confirm prod entitlement for App Store builds.
- [ ] **Cloud Logging quota / retention** — accept defaults for MVP; alert thresholds set.
- [ ] **`firebase.json` and `firestore.indexes.json` updated** with the `notificationHour` index (D18).
- [ ] **Firestore Security Rules deployed** per D19, with rule-emulator tests passing.

- **Phase 2 objections:** Constraint #9.
- **Resolution:** Locked. Checklist items must be tracked in the implementation plan.

### D22 — UI conventions for Quest screen (added Phase 2 — addresses Constraint #13)

CLAUDE.md mandates theme-aware colors, `private enum Layout` for spacing, and reuse of existing component helpers. Specific Quest UI applications:

#### Theme tokens used per visual element

| Visual | Token |
|---|---|
| Quest screen background | `.themeBackgroundPrimary` |
| Card backgrounds (8-Dim, Habit, Survey) | `applyGlassCardEffect()` from `ViewComponentConstants` |
| Card title text | `.themeTextPrimary` |
| Card subtitle/secondary text | `.themeTextSecondary` |
| Habit increment button background | `.themeButtonSecondary` |
| Habit increment button text | `.themeTextOnSecondary` |
| Take Survey CTA button | `.themeButtonPrimary` |
| Lock icon | `.themeIconMuted` |
| Locked card overlay | `.themeOverlayDimmed` (e.g., 0.4 alpha layered) |
| Progress bar fill | `.themeAccent` |
| Progress bar track | `.themeBackgroundSecondary` |
| Radar chart axis lines | `.themeChartAxis` |
| Radar focus dot (solid) | `.themeAccent` |
| Radar non-focus dot (semi-transparent) | `.themeAccent` at 0.4 alpha |
| State-of-Change indicator inactive dot | `.themeIconMuted` |
| State-of-Change indicator active dot | `.themeAccent` |

If any of the above tokens don't exist in the current theme system, add them — don't fall back to hardcoded values. Verify by searching `Soulverse/Shared/Theme/` for the token catalog.

#### Layout constants

Each Quest view file defines a `private enum Layout` with named values. Shared constants live in `ViewComponentConstants` (`navigationBarHeight`, `actionButtonHeight`, etc.). **No hardcoded numbers in `snp.makeConstraints`.**

#### Component reuse

- Survey card and Habit card use `ViewComponentConstants.applyGlassCardEffect()` for the glass-morphism background (per existing project pattern).
- Notification permission prompt UX uses existing `NotificationPresenter` patterns (located at `Soulverse/Notification/Presenter/NotificationPresenter.swift`).
- Locked-card lock affordance uses any existing lock-icon asset (verify in `Soulverse/Shared/Resources/Images.xcassets/`).

- **Phase 2 objections:** Constraint #13.
- **Resolution:** Locked.

### D23 — Survey schedule config (revised Phase 5 — Cloud Function only, no client mirror)

**Phase 5 revision:** The schedule lives **only in TypeScript** (Cloud Function source). The earlier proposal of "parallel TypeScript + Swift constants kept in sync" is dropped because it duplicated logic the client doesn't need to know.

#### Storage location (locked Phase 5)

**Hardcoded in `functions/src/surveySchedule.ts` (Cloud Function only).** No Swift mirror. Schedule changes require a Cloud Function deploy, **not** a client release.

#### How the client knows what's pending

Cloud Function evaluates the schedule per user (on `mood_checkins.onCreate`, on `survey_submissions.onCreate`, and during the hourly cron) and writes to `quest_state`:
- `pendingSurveys: SurveyType[]` — the surveys currently eligible to take.
- `surveyEligibleSinceMap: { [surveyType]: timestamp }` — for client-side deck ordering (oldest pending = front).

The client subscribes via Firestore listener; deck re-renders within sub-second latency on any change.

#### Why this works
- **Schedule is server-only logic.** Client never computes predicates, never knows cadence numbers.
- **Updates without app release.** A cadence change (e.g., "monthly 8-Dim → bi-monthly") = TS edit + Cloud Function deploy. No iOS release needed.
- **Real-time UI.** Cloud Function writes pendingSurveys atomically with submissions; client listener fires immediately.
- **Test surface concentrated server-side.** Cloud Function emulator tests cover scheduling correctness; no parallel Swift tests required.

#### Phase history

- Phase 4: introduced D23 with parallel TS + Swift constants.
- Phase 5: dropped Swift mirror entirely; schedule is server-only.



A single declarative config drives both the rule-engine cron and the client-side Survey section composition. Adding a new survey type or changing a cadence is one config edit.

#### Storage location (locked Phase 4)

**Hardcoded in code, parallel TypeScript + Swift constants** kept in sync. Updates require a release. Rationale: simplest path; avoids the operational cost of a Firestore-stored config with caching/staleness concerns. Firestore-served config is a v1.1 evolution if product wants cadence experiments without releases.

#### Schema

```typescript
// functions/src/surveySchedule.ts (Cloud Function)
// Soulverse/Quest/SurveySchedule.swift (Client) — kept in sync

interface SurveyScheduleEntry {
  surveyType: SurveyType;
  firstAvailable: EligibilityCondition;
  reTakeCadence?: EligibilityCondition;          // omit for one-shot (none in MVP)
  notification: { titleKey: string; bodyKey: string };
  recentResultWindowDays: number;                 // 7 for all in MVP
  pickFocusDimensionFromResult?: boolean;         // true only for Importance Check-In
  isMilestoneOnly?: boolean;                       // synthetic (no survey doc), milestone push only
}

type EligibilityCondition =
  | { type: 'distinctCheckInDays'; threshold: number }
  | { type: 'daysSinceQuestComplete'; days: number }                // anchored to quest_state.questCompletedAt
  | { type: 'daysSinceLastSubmission'; days: number; surveyType: SurveyType }
  | { type: 'focusDimensionAssigned' }                                // synthetic flag
  | { type: 'allOf'; conditions: EligibilityCondition[] }
  | { type: 'oneOf'; conditions: EligibilityCondition[] };

enum SurveyType {
  importanceCheckIn   = 'importance_check_in',
  eightDim            = '8dim',
  stateOfChange       = 'state_of_change',
  satisfactionCheckIn = 'satisfaction_check_in',
}
```

#### MVP config (locked)

```typescript
const SURVEY_SCHEDULE: SurveyScheduleEntry[] = [
  // Importance Check-In — Day 7 first-time, recurring every 7 months
  {
    surveyType: SurveyType.importanceCheckIn,
    firstAvailable: { type: 'distinctCheckInDays', threshold: 7 },
    reTakeCadence:  { type: 'daysSinceLastSubmission', days: 210, surveyType: SurveyType.importanceCheckIn },
    notification: {
      titleKey: 'quest_notification_importance_title',
      bodyKey:  'quest_notification_importance_body',
    },
    recentResultWindowDays: 7,
    pickFocusDimensionFromResult: true,
  },

  // 8-Dim — gated by focus assignment, monthly re-take
  {
    surveyType: SurveyType.eightDim,
    firstAvailable: {
      type: 'allOf',
      conditions: [
        { type: 'distinctCheckInDays', threshold: 7 },
        { type: 'focusDimensionAssigned' },
      ],
    },
    reTakeCadence: { type: 'daysSinceLastSubmission', days: 30, surveyType: SurveyType.eightDim },
    notification: {
      titleKey: 'quest_notification_8dim_title',
      bodyKey:  'quest_notification_8dim_body',
    },
    recentResultWindowDays: 7,
  },

  // State-of-Change — Day 21 + focus, quarterly re-take
  {
    surveyType: SurveyType.stateOfChange,
    firstAvailable: {
      type: 'allOf',
      conditions: [
        { type: 'distinctCheckInDays', threshold: 21 },
        { type: 'focusDimensionAssigned' },
      ],
    },
    reTakeCadence: { type: 'daysSinceLastSubmission', days: 90, surveyType: SurveyType.stateOfChange },
    notification: {
      titleKey: 'quest_notification_soc_title',
      bodyKey:  'quest_notification_soc_body',
    },
    recentResultWindowDays: 7,
  },

  // Satisfaction Check-In — 90 days post-Quest-complete, every 6 months
  {
    surveyType: SurveyType.satisfactionCheckIn,
    firstAvailable: { type: 'daysSinceQuestComplete', days: 90 },
    reTakeCadence:  { type: 'daysSinceLastSubmission', days: 180, surveyType: SurveyType.satisfactionCheckIn },
    notification: {
      titleKey: 'quest_notification_satisfaction_title',
      bodyKey:  'quest_notification_satisfaction_body',
    },
    recentResultWindowDays: 7,
  },
];

// Milestone-only notifications (no survey)
const MILESTONE_NOTIFICATIONS = [
  {
    notificationKey: 'milestone_day14',
    predicate: { type: 'distinctCheckInDays', threshold: 14 },
    titleKey: 'quest_notification_milestone_day14_title',
    bodyKey:  'quest_notification_milestone_day14_body',
  },
  {
    notificationKey: 'milestone_day21',
    predicate: { type: 'distinctCheckInDays', threshold: 21 },
    titleKey: 'quest_notification_milestone_day21_title',
    bodyKey:  'quest_notification_milestone_day21_body',
  },
];
```

#### Engine semantics

- **Pending evaluation:** for each schedule entry, evaluate `firstAvailable` against `quest_state`; if true and no submission of that type yet, the survey is in *first-time pending*. Otherwise, evaluate `reTakeCadence` against the most-recent submission's timestamp; if true and no notification has fired for this re-take window, the survey is in *re-take pending*.
- **Notification dispatch:** rule-engine cron (D11) fires at most one notification per (user, surveyType, eligibility-window). Idempotency tracked by `notification_state.{surveyType}.lastSentAt`.
- **Result card visibility:** for each surveyType not currently pending, if its most-recent submission is within `recentResultWindowDays`, render a RecentResultCard.

#### Adding a new survey type

1. Add a new case to `SurveyType` enum (TS + Swift).
2. Add a new `SurveyScheduleEntry` to `SURVEY_SCHEDULE`.
3. Add the survey's questions to the client question bank + localization keys.
4. Add the survey's submission scoring logic (client-side or in `onSurveySubmissionCreated`).
5. Done. No card-rendering, predicate-engine, or notification-dispatch changes required.

- **Phase 4 origin:** user-driven — to make the schedule mechanism configurable as more surveys come into scope (Importance + Satisfaction added in this phase; v1.1 may add full wellness-doc rotation).
- **Resolution:** Locked.

### D24 — Importance Check-In + Satisfaction Check-In survey content (added Phase 4)

Both surveys come from the wellness assessment doc (Google Doc `19wH1834cHdwyIuFfT3YkXOHaXOrES78S`). Content references rather than duplicating:

#### Importance Check-In
- 32 questions, 5-point importance scale (Not important → Extremely important).
- Computes 8 category averages per the doc's formulas:
  - Physical: (Q2 + Q3 + Q4 + Q5 + Q15 + Q16) / 6
  - Emotional: (Q6 + Q7 + Q8 + Q12 + Q14) / 5
  - Social: (Q19 + Q20 + Q21) / 3
  - Intellectual: (Q9 + Q10 + Q11 + Q27 + Q28) / 5
  - Spiritual: (Q7 + Q8 + Q32) / 3
  - Occupational: (Q18) / 1
  - Environmental: (Q22 + Q23 + Q30 + Q31) / 4
  - Financial: (Q17 + Q24 + Q25 + Q26) / 4
- Result: highest-mean category becomes the focus dimension (with tie-breaker chain per D2).
- Result screen copy: wellness doc's "first-time score" message ("Your top priority is {focus}. This awareness is your foundation…"). On re-take: "follow-up: priority changed" or "follow-up: same priority" copy from the doc.

#### Satisfaction Check-In
- 32 questions, 5-point satisfaction scale (Very dissatisfied → Very satisfied), reworded from Importance Check-In with the same question structure.
- Same 8-category averaging formulas as Importance.
- Result: highest-mean category (most satisfied area) and lowest-mean category (room for growth) shown.
- Result screen copy: wellness doc's "first-time", "improved", "decreased" messages.
- **No effect on `focusDimension`** — Satisfaction is observational, not directional.

#### Localization keys
- `quest_survey_importance_q<NN>_text` (32 keys)
- `quest_survey_satisfaction_q<NN>_text` (32 keys)
- `quest_importance_response_<1..5>` (importance scale labels)
- `quest_satisfaction_response_<1..5>` (satisfaction scale labels)
- `quest_importance_result_first_time_<dimension>` (8 keys, one per focus dimension's first-time message)
- `quest_importance_result_followup_same_priority_<dimension>` (8 keys)
- `quest_importance_result_followup_priority_changed_<from>_<to>` (potentially 56 keys for the cross-product; alternatively use a generic message with interpolation: `quest_importance_result_followup_priority_changed` with `{from}` and `{to}` params)
- `quest_satisfaction_result_first_time_<topCategory>_<lowestCategory>` (potentially many; use generic with interpolation)

en + zh-TW translations launch-blocking per D15.

- **Resolution:** Locked.

### D6 (amendment) — Cross-timezone habit telemetry (added Phase 2 — addresses Constraint #14)

When a habit increment write occurs and the device's `timezoneOffsetMinutes` has shifted by **>2 hours** since the user's last habit write within the same calendar day (UTC), emit an analytics event:

- Event name: `quest_habit_timezone_shift_detected`
- Properties: `previousOffset`, `currentOffset`, `affectedHabitId`, `dayKeyBefore`, `dayKeyAfter`.

This event has no UX impact (the write still goes through with the new tz) but provides support staff with a diagnostic trail when a confused user reports "my exercise minutes vanished." Implementation: track previous offset in a private app-level singleton or `UserDefaults`; compare on each habit write.

- **Phase 2 objections:** Constraint #14.
- **Resolution:** Locked.

---

## Out-of-MVP scope (explicitly deferred)

- ~~Importance Check-In survey~~ (in scope as of Phase 4)
- ~~Satisfaction Check-In survey~~ (in scope as of Phase 4)
- Full 12-month assessment schedule rotation per the wellness doc's exact monthly table (the schedule in D23 is a simplified subset)
- Focus-dimension switching mechanism (separate UI to change focus dim manually)
- Idle-user re-engagement notifications (e.g., "you haven't checked in for X days")
- Subscription/membership system (which would unlock custom habit slots 2 & 3)
- Per-habit goals
- Hard-delete of custom habits
- Firestore-stored survey schedule config (current MVP uses hardcoded code; v1.1 evolution if cadence experiments are desired) (only soft-delete in MVP)

---

## Multi-agent review (Phase 2) — to be filled

### Skeptic / Challenger objections (round 1 — completed 2026-05-01)

| # | Decision | Severity | Title | Resolution |
|---|---|---|---|---|
| 1 | D1 | MEDIUM | Day-counter offset bucketing rule undefined | **Accepted.** D1 updated with explicit "record's own offset" rule. |
| 2 | D1 | LOW/MEDIUM | DST / manual clock changes corrupt day count | **Acknowledged.** D1 notes best-effort, trusts device clock; abuse out of MVP scope. |
| 3 | D2, D16 | **HIGH** | Tie-breaker + unmapped-topic fallback undefined | **Accepted.** D2 updated: tie-breaker = most-recent check-in among tied topics; unmapped-topic fallback = ignore for counting, default to Emotional if all unmapped. |
| 4 | D3 | MEDIUM | Pure day-count means engagement-less graduation | **Acknowledged.** D3 documents the trade-off; downstream metrics need a separate "engaged graduate" definition. No design change. |
| 5 | D4 | MEDIUM | Day-7 pop-up dismissal/reinstall recovery | **Accepted.** D4 updated: ack-state in Firestore (`users/{uid}/quest_state.day7AnnouncementAcknowledgedAt`); re-display surfaces enumerated; push and in-app pop-up decoupled. |
| 6 | D6, D13 | **HIGH** | "User's local midnight" undefined for habit reset | **Accepted.** D6 updated: device's *current* timezone at write time defines the date key; cross-tz limitation acknowledged. |
| 7 | D11 | MEDIUM | Cloud Function partial-failure ordering undefined | **Accepted.** D11 updated: write `lastSentAt` *before* FCM `send()`. Trade-off: prefer rare miss over double-send. |
| 8 | D11, D9 | **HIGH** | Notifications-disabled users locked out of post-Quest re-takes | **Accepted with revision.** D9 updated: Survey card's "available" states are predicate-driven on Quest entry, decoupled from push delivery. Push and in-app are independent channels for the same state. |
| 9 | D13 | LOW/MEDIUM | Single-doc growth bound by claim, not math | **Acknowledged.** D13 updated with concrete math (~76 KB/year, 1MB cap at ~13 years). Acceptable for MVP. |
| 10 | D13 | MEDIUM | Offline merge of `customHabits` array updates | **Accepted.** D13 revised: `customHabits` switched from array to map (keyed by id). Per-field updates compose cleanly with offline queue. |
| 11 | D14, D8 | MEDIUM | Multi-dot rendering is dead code in MVP; per-dimension overwrite rule undefined | **Accepted.** D14 updated: most-recent submission per dimension wins; multi-dot path testable but not user-visible until Day 51+. |
| 12 | Cross-cutting | MEDIUM | Account deletion / cross-device migration undefined | **Accepted.** New D17 added documenting UID-scoped state, auth-provider behavior, deletion behavior. |
| 13 | D9 | MEDIUM | Survey card state precedence undefined | **Accepted.** D9 updated with explicit precedence (5 > 4 > 3 > 2 > 1) and Day-21-with-no-8-Dim handling. |
| 14 | D7 | LOW | YAGNI on subscription forward-compat | **Accepted.** D7 and D13 updated to drop forward-compat framing; build for 1 slot. |
| 15 | D11 | MEDIUM | Cron cadence "[UTC or hourly]" unresolved | **Accepted.** D11 updated: hourly cron with per-user 09:00–09:59 local-time predicate. |

**Net design changes from Skeptic review:**
- 12 of 15 objections required actual decision-log updates (the other 3 were acknowledgements without changes).
- One new decision added (D17 — cross-cutting state).
- One data structure changed (`customHabits`: array → map in D13).
- Two new failure-mode rules locked (D2 tie-breaker + fallback; D11 ordering).
- D9 evolved meaningfully (predicate-driven in-app states decoupled from push).

### Constraint Guardian objections (round 2 — completed)

| # | Decision | Category | Severity | Title | Resolution |
|---|---|---|---|---|---|
| 1 | D11 | Cost / Scalability | **BLOCKING** | Hourly cron + per-user gating busts free-tier reads | **Accepted.** D18 added: `notificationHour` indexed field on `quest_state`; cron query matches only ~N/24 users per invocation. |
| 2 | D11 | Cost / Scalability | **BLOCKING** | Per-user read amplification (8+ reads × N users) | **Accepted.** D18 added: aggregate `quest_state` doc holds all rule-engine state → 1 read per matched user. |
| 3 | D9, D14, X-cut | Performance | HIGH | Quest tab cold-start read budget unspecified | **Accepted.** D18 specifies ≤2 doc reads on cold entry (`quest_state` + `habits/state`); in-session caching documented. |
| 4 | D17, D13 | Security / Privacy | **BLOCKING** | Firestore Security Rules entirely unspecified | **Accepted.** D19 added: full rules sketch covering all paths, write-once survey submissions, server-only notification_state. |
| 5 | D13 | Security / Maintainability | HIGH | `customHabits` map shape unenforceable by rules | **Accepted with documented threat model.** D19 includes explicit threat-model section: single-user data corruption only, no cross-user impact, mitigation deferred to v1.1. |
| 6 | D11 | Reliability | HIGH | 60s timeout vs. unbounded user iteration | **Accepted.** D20 specifies Gen 2 functions (9-min timeout); MVP scale fits comfortably; Pub/Sub fan-out documented as v1.1 scale-out path. |
| 7 | D11 | Reliability | MEDIUM | Self-correcting recurring rules behavior | **Accepted.** D20 documents: predicates use `lastSubmittedAt` (not `lastSentAt`), so missed crons self-correct. Self-correction guard for `lastSentAt > now` added. |
| 8 | D9, D1, D11 | Security / Privacy | MEDIUM | Server-side authority on day-counter & timestamps | **Accepted.** D19 mandates `serverTimestamp()` for `mood_checkins.createdAt` and `survey_submissions.submittedAt`; rule asserts `request.resource.data.createdAt == request.time`; `timezoneOffsetMinutes` constrained to ±840. |
| 9 | D11, D17 | Operational / Cost | **BLOCKING** | APNs / FCM / Blaze setup prerequisites unaddressed | **Accepted.** D21 added: pre-launch infrastructure checklist with 11 ownership items. |
| 10 | D11, X-cut | Operational / Maintainability | HIGH | No Cloud Functions deployment infra | **Accepted.** D20 specifies source location (`functions/` in repo), language (TypeScript), deploy mechanism (`firebase deploy`), monitoring strategy. |
| 11 | D15, D16 | Maintainability | MEDIUM | Localization scale of bundled survey questions unorganized | **Accepted.** D15 amended with full key namespace scheme, ordering policy, and zh-TW launch requirement. |
| 12 | D2, D16 | Maintainability / Reliability | MEDIUM | Topic-to-dimension mapping has no schema validation | **Accepted.** D2 amended: mapping uses Swift `switch` over the topic enum without `default`, so the compiler enforces exhaustiveness; unit test confirms every case maps. |
| 13 | X-cut | Maintainability | MEDIUM | Theme-aware colors / layout-constants compliance unmentioned | **Accepted.** D22 added: theme tokens enumerated per visual; layout-constants requirement re-stated; component reuse (`applyGlassCardEffect`) explicit. |
| 14 | D6 | Reliability / Maintainability | LOW | Cross-timezone habit-bucket data corruption has no telemetry | **Accepted.** D6 amendment added: emits `quest_habit_timezone_shift_detected` analytics event when device tz shifts >2h within same day. |

**Net design changes from Constraint Guardian review:**
- 5 new decisions added: D18 (aggregate doc + read budget), D19 (Security Rules), D20 (Functions deployment), D21 (pre-launch checklist), D22 (UI conventions).
- 3 existing decisions amended: D2 (mapping exhaustiveness), D6 (telemetry), D15 (localization keys).
- All 4 BLOCKING objections resolved.
- All 4 HIGH objections resolved.
- All 5 MEDIUM/LOW objections resolved.

### User Advocate objections (round 3 — completed)

| # | Decision | Severity | Title | Resolution |
|---|---|---|---|---|
| 1 | D5, X-cut | **HIGH** | "Check-in" verb ambiguity strands new users | **Accepted.** D5 updated: Day-1 progress section includes explicit "Do today's Mood Check-In →" CTA deep-linking to the Mood Check-In tab + one-sentence empty-state explanation. |
| 2 | D4, D2, D8 | **HIGH** | Day-7 announcement removes user agency | **Accepted (transparency, not agency).** D4 updated: pop-up explains *why* (top topics + mappings shown), discloses date range considered, reassures user that re-takes after Day 21 allow choosing differently. Auto-pick remains per user's stated preference. |
| 3 | D2, D16, D4 | MEDIUM | Topic-to-dimension mapping is a black box | **Accepted.** D4 updated: pop-up shows top 1–3 topics and their dimension mappings inline. |
| 4 | D9 | MEDIUM | State 3 → State 4 transition buries 8-Dim summary | **Accepted.** D9 updated: stacked two-section layout in State 4 — preserves the 8-Dim summary above the new State-of-Change CTA. |
| 5 | D11, D21, D9 | **HIGH** | Notification permission ask poorly timed | **Accepted.** D21 revised: ask immediately after Day-7 announcement acknowledgement (point of earned trust), not on first Quest tab entry. Soft pre-prompt explains cadence. Persistent settings-link reminder shown if denied. |
| 6 | D5 | MEDIUM | Locked card hint flat copy | **Accepted.** D5 updated: proximity-based copy (far / close / one-away) with distinct localization keys. |
| 7 | D14 | MEDIUM | Radar chart with one dot looks broken | **Accepted.** D14 updated: render placeholder ghost markers on un-assessed axes; one explanatory line below chart. |
| 8 | D14, D10, D15 | **HIGH** | "Stage 1–5" labels are clinical jargon | **Accepted.** D14 updated: friendly user-facing labels (Considering / Planning / Preparing / Doing / Sustaining) authored at launch in en + zh-TW. Per-stage one-sentence message also required. |
| 9 | D6 | **HIGH** | Habit reset at midnight erases without warning | **Accepted.** D6 updated: "Today" subtitle + reset-time hint on each habit card; one-line "Yesterday: {N} {unit}" reference when prior-day data exists. |
| 10 | D7 | MEDIUM | Custom habit form has no validation guidance | **Accepted.** D7 updated: full validation rules (name 1–24, unit 1–8, increments positive + distinct), unit-aware suggestions, live preview, save-disabled-until-valid. |
| 11 | D7 | MEDIUM | "1 slot" semantics ambiguous (1 active vs 1 ever) | **Accepted.** D7 updated: explicitly "1 active at a time" — soft-deletion frees the slot. Surfaced in creation copy and deletion confirmation. |
| 12 | D12, D11 | **HIGH** | Re-take notifications use jargon, hide dimension choice | **Accepted.** D11 updated: full notification body copy authored, jargon-free. Monthly nudge explicitly invites dimension choice ("Pick any of 8 dimensions to revisit — you can choose differently this time"). |
| 13 | D3, D12 | MEDIUM | "Quest complete" feels hollow for disengaged path | **Accepted.** D3 updated: personalized completion stats (check-ins, habit logs, surveys, dimensions). Disengaged-graduate path uses softer "21 days of check-ins — that's a real foundation. Want to go deeper?" copy with prompts for unfinished surveys. |
| 14 | D1, D2, D4 | MEDIUM | Stale mood data drives focus reveal for non-contiguous users | **Accepted.** D4 pop-up content includes the date range of check-ins considered, so user can mentally calibrate. |
| 15 | D11 | LOW | Notification timing assumes push == attention | **Accepted.** D4 updated: in-app pop-up is canonical reveal moment. Persistent in-app banner ("Your focus is ready! Tap to reveal") shown whenever announcement is pending, regardless of push delivery. |

**Net design changes from User Advocate review:**
- 8 existing decisions amended: D3, D4, D5, D6, D7, D9, D11, D14, D21.
- No new decisions added (all UX issues were addressable within existing decision scope).
- Significant copy/microcopy specifications added throughout — these become localization deliverables for the launch.
- Three architectural decisions (D11 cron, D17 cross-cutting, D18 aggregate doc) confirmed as not needing UX changes.

### Arbiter resolution (final — 2026-05-02)

**Verdict: APPROVED**

The Arbiter verified resolution completeness across all three review rounds (Skeptic 15/15, Constraint Guardian 14/14, User Advocate 15/15 — total 44 objections resolved), checked internal consistency between locked decisions (5 cross-checks, no contradictions), audited critical-path adequacy on all 16+ HIGH/BLOCKING findings, and confirmed no scope creep beyond correctness/operational scaffolding.

**Single acknowledged tension:** Original "MVP, no budget" premise vs. D21's Firebase Blaze plan requirement. Resolution: Blaze is pay-as-you-go; at projected MVP scale (≤10k DAU) will run $0–10/month. Flagged as launch dependency, not silent contradiction.

**Implementation-tracking caveats** (carry into the implementation plan, not requiring re-review):

1. **Security Rules implementation gate** — D19 is a design-stage sketch. Engineering must finalize and pass Firestore Rules Emulator tests before launch. Hold launch on this checklist item.
2. **Blaze plan prerequisite** — D21 mandates Firebase Blaze. Confirm credit-card-on-file owner before any Cloud Functions deploy.
3. **Scale-out path is v1.1** — D18 / D20 sharding + Pub/Sub fan-out at >10k matched users/hour is documented as v1.1. Flag if MVP launch exceeds 10k DAU before that work lands.
4. **zh-TW localization launch-blocking** — D15 specifies all en + zh-TW strings must be complete before merge to main. Confirm translation owner early in the implementation plan.
5. **Custom-habits threat model deferral** — D19 / Constraint #5: acceptable for MVP; revisit if threat model tightens.
6. **D21 checklist as acceptance gates** — Each of the 11 pre-launch infrastructure items must be tracked as an explicit gate in the implementation plan, not as a TODO comment.
7. **Decision Log finalization** — This Arbiter section concludes the Phase 2 review. The Decision Log is now considered canonical and should not be edited without explicit re-review.

**Exit criteria status:**
- ✅ Understanding Lock completed (Phase 1)
- ✅ All reviewer agents invoked (Skeptic, Constraint Guardian, User Advocate)
- ✅ All objections resolved (44/44)
- ✅ Decision Log complete
- ✅ Arbiter has declared the design acceptable

**The Primary Designer may proceed to `superpowers:writing-plans` for implementation planning.**

END MULTI-AGENT BRAINSTORMING — Verdict: APPROVED
