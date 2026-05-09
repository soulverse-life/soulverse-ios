# Onboarding Quest MVP — Manual QA Checklist

**Spec:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md`
**Plan:** `docs/superpowers/plans/2026-05-06-quest-plan-7-polish-qa.md`
**Created:** 2026-04-29
**Owner:** iOS dev (rotated)

Run each scenario against the dev environment (`https://summit-dev.thekono.com/api`) on iPhone 16 Pro Max simulator first, then on a TestFlight build on a real device. Tick each box only when actual matches expected.

## Happy paths (Plan 7 Task 6)

### 6.1 — Day 7 → Importance Check-In → 8-Dim flow

- [ ] Simulator: progress shows "Day 7 of 21" after the 7th distinct check-in
- [ ] Simulator: SurveySection becomes visible (was hidden when count < 7)
- [ ] Simulator: PendingSurveyDeck shows Importance card as the only pending item
- [ ] Simulator: 8-Dim card stays locked (8-Dim unlocks after Importance, not at Day 7)
- [ ] Simulator: tapping Importance card opens SurveyViewController with 32 questions
- [ ] Simulator: submission shows SurveyResultViewController with first-time message
- [ ] Simulator: after dismissing, Importance card is gone, 8-Dim card is in deck, RecentResultCardList shows Importance result
- [ ] Real device: same as above end-to-end

### 6.2 — Day 14 milestone + custom habit unlock

- [ ] Simulator: progress shows "Day 14 of 21"
- [ ] Simulator: [Add Custom Habit] button transitions Locked → Available
- [ ] Real device: push notification arrives at next 9 a.m. local with Day-14 milestone copy
- [ ] Simulator: tapping [Add Custom Habit] opens CustomHabitFormViewController
- [ ] Simulator: form validates name (1-24), unit (1-8), 3 distinct positive increments
- [ ] Simulator: after submit, custom habit card appears in HabitCheckerSection; [Add Custom Habit] hides
- [ ] Real device: same end-to-end

### 6.3 — Day 21 → State-of-Change pending; progress bar hides

- [ ] Simulator: progress section hides at Day 21
- [ ] Simulator: State-of-Change Check-In card appears in PendingSurveyDeck
- [ ] Simulator: 8-Dim radar still visible; SoC indicator absent until SoC submitted
- [ ] Simulator: SoC submission populates SoC indicator with active stage label (Considering/Planning/Preparing/Doing/Sustaining)
- [ ] Real device: same end-to-end

## Edge cases (Plan 7 Task 7)

### 7.1 — Mood check-in across midnight (timezone shift)

- [ ] Simulator: check-in just before midnight + check-in just after counts as 1 distinct day if same calendar day
- [ ] Simulator: check-ins on 2 distinct local days count as 2 even when within 24 hours
- [ ] Telemetry: `quest_habit_timezone_shift_detected` fires when device timezone changes >2h within same calendar day

### 7.2 — Notification permission denied

- [ ] Simulator: skipping the iOS permission prompt does not block Quest functionality
- [ ] Simulator: settings link works correctly if user later wants to enable

### 7.3 — Survey submission while offline

- [ ] Simulator: SurveyViewController buttons disabled until all questions answered
- [ ] Simulator: Firebase offline queue stores submission and replays on reconnect
- [ ] Simulator: successful re-sync updates RecentResultCardList automatically (Firestore listener)

### 7.4 — Multiple pending surveys (deck of cards)

- [ ] Simulator: front card shows oldest-eligibleSince first (correct ordering)
- [ ] Simulator: 0–2 stacked back cards visually offset
- [ ] Simulator: "+N more" badge appears when deck has 3+ items

### 7.5 — Custom habit deletion

- [ ] Simulator: confirmation alert appears before delete
- [ ] Simulator: post-delete, [Add Custom Habit] reappears and habit row hides
- [ ] Simulator: Firestore `customHabits.<id>.deletedAt` is set, isActive=false

## Theming + accessibility (Plan 7 Tasks 1, 10)

- [ ] Light theme: every Quest surface uses the correct theme tokens (no hardcoded grays)
- [ ] Dark theme: every surface adapts; contrast meets WCAG AA
- [ ] Dynamic Type: largest accessibility size doesn't truncate critical text
- [ ] VoiceOver: every tappable element has a meaningful label
- [ ] VoiceOver: deck navigation reads "Importance Check-In, 1 of 3 pending reflections"
- [ ] VoiceOver: habit increment buttons read e.g. "Add 5 minutes of exercise"

## Localization (Plan 7 Task 4)

- [ ] en strings count ≥ 322 quest-namespaced keys
- [ ] No `quest_<key>` text literals appear at runtime (would mean missing key)
- [ ] Tone consistent across 20 spot-checked keys (warm, encouraging, second-person)
- [ ] zh-TW deferred to v1.1 per spec §2.2 — confirm en is the only launch-blocking locale

## Sign-off

- [ ] Simulator: all happy paths + edge cases passed
- [ ] Real device: all happy paths + Day-14 push notification verified
- [ ] iOS dev sign-off date: __________
- [ ] Product sign-off date: __________
