# Onboarding Quest — Plan 7 of 7: Polish + Final QA + Pre-launch Sign-off

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to execute this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Land the Onboarding Quest feature on `main` and into TestFlight with zero hard-coded colors, zero hard-coded layout numbers, zero un-localized user-facing strings, a polished deck-of-cards animation, a passing accessibility sweep, every D21 pre-launch infrastructure item verified, and a complete manual-QA pass on simulator and a real device. After this plan, the Onboarding Quest is feature-complete and ready for App Store submission.

**Architecture:** Audit-and-fix passes over the existing Quest source tree (`Soulverse/Features/Quest/`) plus three small QA artefacts (a manual-QA checklist file and two in-code polish patches: deck-of-cards animation timing and VoiceOver labels). All Plans 1–6 source code is assumed shipped to `main`; Plan 7 only modifies what already exists. No net-new feature code.

**Tech Stack:** Swift, UIKit, SnapKit, NSLocalizedString, theme tokens from `Soulverse/Shared/Theme/`, `ViewComponentConstants` from `Soulverse/Shared/`, `xcodebuild` (Debug + Release), `fastlane ios development` / `fastlane ios release`, Xcode Accessibility Inspector, iOS Simulator, real iPhone via TestFlight.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md` (especially §10 UI conventions, §11 testing strategy, §12 pre-launch infrastructure checklist, §13 implementation risks)

---

## File structure

After this plan, the repo's Quest tree is unchanged in shape. Audit fixes touch existing files; polish patches touch existing files. Two new artefacts are created:

```
docs/superpowers/qa/
  2026-05-06-quest-mvp-manual-qa-checklist.md   # NEW — checklist + sign-off
  2026-05-06-quest-mvp-prelaunch-checklist.md   # NEW — D21 items 4-11 sign-off

Soulverse/Features/Quest/
  Views/
    PendingSurveyDeck/
      PendingSurveyDeckView.swift               # MODIFIED — animation polish (Task 8)
    HabitCheckerSection/
      HabitIncrementButton.swift                # MODIFIED — accessibility labels (Task 10)
      HabitCard.swift                           # MODIFIED — accessibility labels (Task 10)
    EightDimensionsCard/
      QuestRadarChartView.swift                 # MODIFIED — accessibility labels (Task 10)
    ProgressSection/
      QuestProgressSectionView.swift            # MODIFIED — accessibility labels (Task 10)
  (any file caught by audits 1-5 is patched in place)

en.lproj/Localizable.strings                    # MODIFIED — any strings caught by audit 4
```

The rest of the codebase is untouched in this plan.

---

## Pre-launch operational items (NOT TDD tasks)

These are infrastructure items completed by humans (admins, ops). Track them as gates, not as engineering tasks. Plan 1 already gated items 1–3; Plan 7 gates items 4–11 from spec §12.

- [ ] **Pre-launch 4:** Firebase Cloud Logging quota and retention configured (default 30-day retention is acceptable for MVP; confirm in console). Owner: ops/admin.
- [ ] **Pre-launch 5:** Cloud Monitoring alert configured: `cloudfunctions.googleapis.com/function/execution_count` filtered by `status != "ok"` divided by total executions, alert when >5% over a 1-hour rolling window. Email channel = `dev@soulverse.life`. Owner: ops/admin.
- [ ] **Pre-launch 6:** `firestore.indexes.json` deployed (Plan 1 Task 21 deploy). Verify in Firebase Console → Firestore → Indexes that the single-field index on `quest_state.notificationHour` shows status **Ready** (not "Building"). Owner: iOS dev.
- [ ] **Pre-launch 7:** `firestore.rules` deployed (Plan 1 Task 21 deploy). Re-run the rules-emulator test suite from Plan 1 Task 19 against the deployed rules to confirm they match what was tested locally. Owner: iOS dev.
- [ ] **Pre-launch 8:** `en.lproj/Localizable.strings` is the only launch-blocking localization. Verified by Task 4 of this plan (~322 keys). Owner: iOS dev.
- [ ] **Pre-launch 9:** Notification permission UX confirmed via Plan 6 deliverable: system iOS dialog requested at registration completion. No custom soft pre-prompt. Smoke test on a real device that the dialog appears for a fresh install. Owner: iOS dev.
- [ ] **Pre-launch 10:** APNs production entitlement confirmed in `Soulverse.entitlements` for the Soulverse (production) target. Re-confirm `aps-environment = production` is signed into the Release build. Owner: iOS dev.
- [ ] **Pre-launch 11:** App Store screenshots and metadata (Quest tab screens for Day 1, Day 7-pending-Importance, Day 14, Day 21-completed). **Out of scope of this plan's code work** but flag to product so it does not block submission day. Owner: product.

Items 4–10 are required before TestFlight Release-build deploy in Task 14. Item 11 is required before App Store submission (which is itself out of scope).

---

## Task 1: Theme-compliance audit on Quest UI surfaces

**Purpose:** Spec §10.1 mandates every Quest visual element use a theme token. This audit catches any leftover hardcoded `UIColor.black`, `.white`, `.darkGray`, `.lightGray`, `UIColor(red:green:blue:alpha:)`, hex literals, or any `.systemGray*` reference. Per the user's global CLAUDE.md, hardcoded colors are forbidden.

**Files:**
- Audit-only (no new files); fixes patch the offending files in `Soulverse/Features/Quest/`

- [ ] **Step 1: Run the audit grep**

From repo root:

```bash
grep -rnE "UIColor\.(black|white|darkGray|lightGray|gray|red|green|blue|orange|yellow|purple|brown|cyan|magenta|systemGray[0-9]?|systemBlue|systemRed|systemGreen|systemOrange|systemYellow|systemPurple)|UIColor\(red:|UIColor\(white:|UIColor\(hex:|#[0-9A-Fa-f]{6}|#[0-9A-Fa-f]{3}\b" Soulverse/Features/Quest/ \
  | grep -v "// theme-allowed:" \
  > /tmp/quest-color-audit.txt

cat /tmp/quest-color-audit.txt
```

Expected if compliant: file is empty.

The `// theme-allowed:` escape hatch is reserved for cases where a literal is intentional (e.g., a debug overlay) — none should appear in production Quest code.

- [ ] **Step 2: Triage results**

For each line in `/tmp/quest-color-audit.txt`:

- If the literal sets a UI element's color, replace with the corresponding token from §10.1 of the spec:
  - card backgrounds → `applyGlassCardEffect()` (audit task 3 catches these separately)
  - title text → `.themeTextPrimary`
  - secondary text → `.themeTextSecondary`
  - increment button bg → `.themeButtonSecondary`
  - primary CTA bg → `.themeButtonPrimary`
  - lock icon tint → `.themeIconMuted`
  - locked-card overlay → `.themeOverlayDimmed`
  - progress bar fill → `.themeAccent`
  - progress bar track → `.themeBackgroundSecondary`
  - radar axis lines → `.themeChartAxis`
  - radar focus dot (highlighted) → `.themeAccent`
  - radar non-focus dot → `.themeAccent` at 0.6 alpha
  - SoC inactive dot → `.themeIconMuted`
  - SoC active dot → `.themeAccent`
- If the token does not yet exist, add it to `Soulverse/Shared/Theme/UIColor+Theme.swift` (per spec §10.1 final paragraph: "If any token doesn't exist in `Soulverse/Shared/Theme/`, add it during implementation; do not fall back to hardcoded values").

- [ ] **Step 3: Re-run the audit**

```bash
grep -rnE "UIColor\.(black|white|darkGray|lightGray|gray|red|green|blue|orange|yellow|purple|brown|cyan|magenta|systemGray[0-9]?|systemBlue|systemRed|systemGreen|systemOrange|systemYellow|systemPurple)|UIColor\(red:|UIColor\(white:|UIColor\(hex:|#[0-9A-Fa-f]{6}|#[0-9A-Fa-f]{3}\b" Soulverse/Features/Quest/ \
  | grep -v "// theme-allowed:"
```

Expected: no output.

- [ ] **Step 4: Build verification**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 5: Commit (only if changes were made)**

```bash
git add Soulverse/Features/Quest/ Soulverse/Shared/Theme/
git commit -m "fix(quest): replace hardcoded colors with theme tokens across Quest UI"
```

If the audit found nothing, skip the commit and record "Audit passed — no changes" in the QA checklist (created in Task 12).

---

## Task 2: Layout-constants audit (no hardcoded numbers in `snp.makeConstraints`)

**Purpose:** Per `CLAUDE.md` (project) and spec §10.2, every constraint value must come from a named constant — either a file-local `private enum Layout` or a global like `ViewComponentConstants` / `MoodCheckInLayout`. Hardcoded numbers (e.g., `.height.equalTo(48)`) are a recurrence-hazard.

**Files:**
- Audit-only; fixes patch the offending files

- [ ] **Step 1: Run the audit grep**

From repo root:

```bash
# Look for snp.makeConstraints / snp.remakeConstraints / snp.updateConstraints calls
# whose body contains an integer or float literal not preceded by '.' (which would
# indicate a multiplier like .multipliedBy(0.5)).
grep -rnE "\.equalTo\(\s*-?[0-9]+(\.[0-9]+)?\s*\)|\.equalToSuperview\(\)\.offset\(\s*-?[0-9]+|\.inset\(\s*-?[0-9]+|\.offset\(\s*-?[0-9]+|\.height\.equalTo\(\s*-?[0-9]+|\.width\.equalTo\(\s*-?[0-9]+" Soulverse/Features/Quest/ \
  | grep -v "// layout-allowed:" \
  > /tmp/quest-layout-audit.txt

cat /tmp/quest-layout-audit.txt
```

The `// layout-allowed:` escape hatch is reserved for genuine zero or one-off priorities (e.g., `.priority(.required)` does not match this regex anyway). The audit is a hint; some matches will be false positives like `0` for "no offset" — review case-by-case.

- [ ] **Step 2: Triage and fix**

For each genuine hardcoded number:

1. If the value is shared across files (e.g., 48pt button height, 56pt nav bar): use the matching constant in `ViewComponentConstants` (`actionButtonHeight`, `navigationBarHeight`, `navigationButtonSize`, `colorDisplaySize`).
2. If view-specific: add to a `private enum Layout` at the top of the file with a descriptive name (`Layout.deckCardOffset`, `Layout.habitButtonSpacing`, `Layout.radarChartCenterIconSize`, etc.).
3. Never use a magic number — the value must have a name.

- [ ] **Step 3: Re-run the audit**

```bash
grep -rnE "\.equalTo\(\s*-?[0-9]+(\.[0-9]+)?\s*\)|\.equalToSuperview\(\)\.offset\(\s*-?[0-9]+|\.inset\(\s*-?[0-9]+|\.offset\(\s*-?[0-9]+|\.height\.equalTo\(\s*-?[0-9]+|\.width\.equalTo\(\s*-?[0-9]+" Soulverse/Features/Quest/ \
  | grep -v "// layout-allowed:"
```

Expected: only intentional false positives (e.g., `.offset(0)` to mean "no offset"); each surviving match must be reviewed by the engineer and either marked `// layout-allowed:` with reason or fixed.

- [ ] **Step 4: Build verification**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds, layout visually unchanged.

- [ ] **Step 5: Commit (only if changes were made)**

```bash
git add Soulverse/Features/Quest/
git commit -m "refactor(quest): extract hardcoded constraint values into Layout enums"
```

---

## Task 3: Component-reuse audit — every card uses `applyGlassCardEffect()`

**Purpose:** Spec §10.3 requires all Quest cards use `ViewComponentConstants.applyGlassCardEffect()`. No custom card backgrounds (gradients, solid colors, ad-hoc CALayer shadows). This keeps glass-effect rendering consistent and centralizes future changes.

**Files:**
- Audit-only; fixes patch the offending files

- [ ] **Step 1: Enumerate every card-class file**

From repo root:

```bash
find Soulverse/Features/Quest -type f -name "*.swift" \
  | xargs grep -l "Card\|CardView\|Section\|Deck" \
  > /tmp/quest-card-files.txt

cat /tmp/quest-card-files.txt
```

Each entry is a file that hosts one or more "card" surfaces.

- [ ] **Step 2: Verify each card calls `applyGlassCardEffect`**

For each file in `/tmp/quest-card-files.txt`:

```bash
grep -n "applyGlassCardEffect\|backgroundColor\s*=\|layer\.cornerRadius\|layer\.shadow\|CAGradientLayer" "<file>"
```

For each card-shaped subview (i.e., a `UIView` that is a discrete tappable rectangle in the Quest screen), confirm:

- It calls `ViewComponentConstants.applyGlassCardEffect(on: <view>)` (or the equivalent extension form), AND
- It does NOT additionally set `backgroundColor`, `layer.cornerRadius`, `layer.shadow*`, or insert a `CAGradientLayer`.

If a card sets its own background and shadow → remove that code, call `applyGlassCardEffect` instead.

- [ ] **Step 3: Build verification**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 4: Visual smoke check on simulator**

Launch the Quest tab on iPhone 16 Pro Max simulator. Visually confirm:

- ProgressSection card has glass effect.
- EightDimensionsCard has glass effect.
- Each habit card (Exercise, Water, Meditation, custom if present) has glass effect.
- PendingSurveyDeck front card has glass effect.
- Each RecentResultCard has glass effect.

All cards should look visually consistent (same backdrop blur, same border, same shadow). Inconsistency = a card is bypassing `applyGlassCardEffect`.

- [ ] **Step 5: Commit (only if changes were made)**

```bash
git add Soulverse/Features/Quest/
git commit -m "refactor(quest): route all card backgrounds through applyGlassCardEffect"
```

---

## Task 4: Localization sweep — every user-facing string uses `NSLocalizedString`

**Purpose:** Spec §9 mandates `NSLocalizedString` for all user-facing strings. ~322 keys are expected (en only for MVP). This task verifies coverage and tone.

**Files:**
- Audit-only; fixes patch the offending files and `en.lproj/Localizable.strings`

- [ ] **Step 1: Audit `.text =` and `setTitle(...)` usages**

From repo root:

```bash
# Catch literal strings being assigned to .text, .placeholder, or passed to setTitle / setAttributedText
grep -rnE "\.(text|placeholder|attributedText)\s*=\s*\"[^\"]+\"|setTitle\(\s*\"[^\"]+\"|setAttributedTitle\(.*string:\s*\"[^\"]+\"" Soulverse/Features/Quest/ \
  | grep -v "NSLocalizedString" \
  | grep -v "// non-localized:" \
  > /tmp/quest-l10n-audit.txt

cat /tmp/quest-l10n-audit.txt
```

The `// non-localized:` escape hatch is reserved for things like SF Symbols names, accessibility identifier strings, or analytics-event names. Each surviving line must be either localized or escape-marked.

- [ ] **Step 2: Fix each violation**

For each violation in `/tmp/quest-l10n-audit.txt`:

1. Replace the literal with `NSLocalizedString("quest_<feature>_<element>", comment: "<one-line context>")` per spec §9.1 namespace scheme.
2. Add the key + en value to `en.lproj/Localizable.strings`.
3. Do NOT add to `zh-TW.lproj/Localizable.strings` — zh-TW is deferred to v1.1 per spec §2.2.

- [ ] **Step 3: Verify the en bundle is complete**

Count keys in `en.lproj/Localizable.strings`:

```bash
grep -cE '^\s*"quest_' Soulverse/en.lproj/Localizable.strings
```

Expected: ≥ 322 quest-namespaced keys (per spec §9.2 budget). The number may be slightly higher if engineering added detail keys; lower means a gap.

- [ ] **Step 4: Spot-check tone consistency on en strings**

Pick 20 random keys from across the files. For each, the engineer reads the en value aloud and confirms:

- Sentences read naturally; no awkward placeholders left in (e.g., "TODO" / "[name]" / "FILLME").
- Tone is consistent with existing app strings (warm, encouraging, second-person).
- Capitalization matches: Quest UI strings use Sentence case; button titles use Title Case where the existing app does.

If 3+ keys read awkwardly, raise to product before submission.

- [ ] **Step 5: Build with the en bundle and run on simulator**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Set simulator language to English (Settings → General → Language & Region → English). Smoke-test the Quest tab with a Day 7 user fixture; confirm no `quest_<key>` strings appear unrendered (which would indicate a missing key).

- [ ] **Step 6: Commit (only if changes were made)**

```bash
git add Soulverse/Features/Quest/ Soulverse/en.lproj/
git commit -m "fix(quest): localize remaining hardcoded user-facing strings"
```

---

## Task 5: Out-of-tree string scan

**Purpose:** Some Quest-related strings may live outside `Soulverse/Features/Quest/` (e.g., notification handler in `AppDelegate`, Quest-related entries in `MainViewController`'s tab bar setup, deep-link constants). Catch them.

**Files:**
- Audit-only; fixes patch the offending files

- [ ] **Step 1: Run the broader scan**

From repo root:

```bash
# Find files that reference Quest-related identifiers but live outside the Quest folder.
grep -rnE "[Qq]uest|[Ss]urvey|[Hh]abit[A-Z]|[Ff]ocusDimension|[Dd]istinctCheckInDays" Soulverse \
  --include="*.swift" \
  | grep -v "Soulverse/Features/Quest/" \
  | grep -v "Soulverse/SoulverseTests" \
  | grep -v "Soulverse/SoulverseUITests" \
  > /tmp/quest-out-of-tree.txt

wc -l /tmp/quest-out-of-tree.txt
```

The result includes legitimate references (e.g., `MainViewController` instantiating `QuestViewController`) and the things we want to inspect (string literals).

- [ ] **Step 2: Filter to suspect literals**

```bash
grep -E "\"[^\"]*[Qq]uest[^\"]*\"|\"[^\"]*[Ss]urvey[^\"]*\"|\"[^\"]*[Hh]abit[^\"]*\"" /tmp/quest-out-of-tree.txt \
  | grep -v "NSLocalizedString" \
  | grep -v "// non-localized:" \
  | grep -v "AnalyticsEvent\|kAnalytics\|kEvent\|kRoute\|kIdentifier\|kKey"
```

Each output line is a candidate. Triage:

- Analytics event names (`"quest_habit_increment"`, etc.) → leave as-is; mark `// non-localized: analytics`.
- Deep-link routes (`"soulverse://quest"`) → leave; mark `// non-localized: route`.
- Anything else (push notification fallback bodies, alert titles, log messages displayed to user) → wrap in `NSLocalizedString` and add to `en.lproj/Localizable.strings`.

- [ ] **Step 3: Build verification**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 4: Commit (only if changes were made)**

```bash
git add Soulverse/ Soulverse/en.lproj/
git commit -m "fix(quest): localize Quest-related strings outside Features/Quest tree"
```

---

## Task 6: Manual QA — happy paths (Day 7, Day 14, Day 21)

**Purpose:** Spec §11 lists three milestone happy paths. This task executes each end-to-end against real Firestore + deployed Cloud Functions (not the emulator) on the iPhone 16 Pro Max simulator, then a real device.

**Files:**
- New: `docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md` (created in Task 12; this task adds the first three checkbox entries)

This task does NOT use TDD. Each scenario specifies **Setup / Action / Expected**. Verify each on simulator first, then on a TestFlight build on a real device. Tick the corresponding checkbox in the checklist file (Task 12) when the actual matches the expected.

- [ ] **Step 1: Scenario 6.1 — Day 7 → Importance Check-In → 8-Dim flow**

**Setup:**
- Fresh user account on dev environment (`https://summit-dev.thekono.com/api`).
- In Firestore (Firebase console), seed `users/{uid}/quest_state` with `distinctCheckInDays = 6`, `lastDistinctDayKey = "<yesterday>"`, all other fields default.
- Open the app on iPhone 16 Pro Max simulator, sign in, navigate to Quest tab.

**Action:**
1. Navigate to Mood Check-In and complete one. The trigger `onMoodCheckInCreated` runs server-side.
2. Pull-to-refresh on Quest tab (or wait for the Firestore listener to fire).

**Expected:**
- Top progress section shows "Day 7 of 21".
- Survey section becomes visible (was hidden when count < 7).
- PendingSurveyDeck shows Importance Check-In as the only pending card.
- 8-Dim card stays locked with hint "Just 1 more check-in!" or similar (8-Dim unlocks after Importance submission, not at Day 7).
- Tap Importance card → SurveyViewController opens with 32 questions.
- Submit. SurveyResultViewController appears with first-time message naming the focus dimension.
- Tap Done → returns to Quest tab.
- Quest tab now shows: Importance card removed from deck, 8-Dim card now in deck, RecentResultCardList shows Importance result. Radar chart shows the focus axis with 5 outline dots.

- [ ] **Step 2: Scenario 6.2 — Day 14 milestone + custom habit unlock**

**Setup:**
- User from 6.1, advance `distinctCheckInDays` to 13 (via 6 more mood check-ins on 6 distinct days).

**Action:**
1. Submit the 14th mood check-in.
2. Wait for Firestore listener.

**Expected:**
- Progress section shows "Day 14 of 21".
- HabitCheckerSection's [Add Custom Habit] button transitions from Locked to Available.
- Push notification arrives at the next 9 a.m. local with the Day 14 milestone copy (`quest_notification_milestone_day14_*`). Verify by leaving the simulator overnight, or set the notification cron's hour query to current UTC hour for testing.
- Tap [Add Custom Habit] → CustomHabitFormViewController opens.
- Submit a habit named "Stretch", unit "min", increments [5, 10, 15]. Returns to Quest.
- Custom habit card appears in HabitCheckerSection. [Add Custom Habit] button hides (slot full).

- [ ] **Step 3: Scenario 6.3 — Day 21 → State-of-Change pending; progress bar hides**

**Setup:**
- Same user, advance `distinctCheckInDays` to 20.

**Action:**
1. Submit the 21st mood check-in.
2. Wait for Firestore listener.

**Expected:**
- Top progress section becomes hidden (per spec §5: "Day ≥ 21: hidden").
- PendingSurveyDeck shows State-of-Change as a new pending card.
- `quest_state.questCompletedAt` is non-null in Firestore.
- No celebratory modal (per spec §13.9 — Day-21 celebration UI is out of MVP scope).
- Tap State-of-Change → 15 questions → submit.
- Returns to Quest tab. RecentResultCardList shows SoC result. Radar chart's focus axis now has the SoC stage solid dot at the user's reported stage.

- [ ] **Step 4: Record outcomes**

In the Task 12 checklist file, tick each scenario as Pass/Fail with date and the device used. If any step fails, file a bug, fix, and re-run before continuing.

- [ ] **Step 5: Commit the checklist update**

```bash
git add docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md
git commit -m "qa(quest): record Day-7/14/21 happy-path manual QA results"
```

---

## Task 7: Manual QA — edge scenarios

**Purpose:** Spec §11 and §13 call out cross-timezone, DND, day-counter, and survey re-take edge cases. Each is a scenario the design must withstand.

**Files:**
- Modify: `docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md`

For each scenario below: setup → action → expected. Tick in the checklist on completion.

- [ ] **Step 1: Scenario 7.1 — Cross-timezone day-counter (UTC+8 night → next-day morning)**

**Setup:** Test user at `distinctCheckInDays = 5`, `lastDistinctDayKey = "2026-05-02"`. Device set to Asia/Taipei (UTC+8).

**Action:**
1. At 23:55 local, submit a mood check-in. `dayKey = "2026-05-02"` (still same day), no increment.
2. At 00:01 local (next day), submit another. `dayKey = "2026-05-03"`, increments to 6.

**Expected:** Habit cards' "Yesterday: {N}" line for May 2 reflects May-2 totals. May-3 column starts fresh. Day counter = 6.

- [ ] **Step 2: Scenario 7.2 — Cross-timezone travel (UTC+8 → UTC-5 mid-day)**

**Setup:** Device starts in Taipei. User at `distinctCheckInDays = 8`, focus assigned, custom habit "Stretch" exists.

**Action:**
1. At 10:00 Taipei local, log "Stretch +10 min". Habit write hits dayKey based on Taipei = "2026-05-03".
2. Submit a mood check-in. `mood_checkins.timezoneOffsetMinutes = 480` (UTC+8). Server-side dayKey = "2026-05-03". No increment (same day).
3. Travel: change device timezone to America/New_York (UTC-5). It is now 22:00 May 2 local.
4. Log "Stretch +5 min". Habit write hits dayKey based on US/Eastern = "2026-05-02".
5. Submit another mood check-in. `mood_checkins.timezoneOffsetMinutes = -300` (UTC-5). Server dayKey = "2026-05-02". distinctCheckInDays increments to 9.

**Expected:**
- Habit data: May 2 has +5 min Stretch; May 3 has +10 min Stretch (per spec §6.2 asymmetry: habit uses *current* device tz at write time).
- Day counter: 9, with `lastDistinctDayKey = "2026-05-02"`.
- Analytics event `quest_habit_timezone_shift_detected` fired (verify in Firebase Analytics DebugView). Per spec §6.2 telemetry rule.

- [ ] **Step 3: Scenario 7.3 — DST autumn fallback**

**Setup:** Device set to America/New_York. Manually advance the simulator clock to 2026-11-01 01:30 local (the "ambiguous hour" before fall-back to 01:00).

**Action:** Log a mood check-in at 01:30, then change clock to 2026-11-01 01:30 (after fall-back). Log another. Both records share UTC date 2026-11-01 since DST only affects local rendering.

**Expected:**
- `mood_checkins.timezoneOffsetMinutes` for the first = -240 (EDT); for the second = -300 (EST).
- Both records bucket to dayKey "2026-11-01" via spec §6.2 (each uses its stored offset). distinctCheckInDays increments at most by 1 across the pair.

- [ ] **Step 4: Scenario 7.4 — Notifications disabled system-wide**

**Setup:** Settings → Soulverse → Notifications → off. Test user at `distinctCheckInDays = 6`.

**Action:**
1. Submit mood check-in #7. Quest tab updates.
2. Wait through the next 9 a.m. local. Push **does not** arrive (OS suppresses).

**Expected:**
- PendingSurveyDeck still shows Importance Check-In (per spec §3.1.4: "OS-level notifications-disabled users still see all available content in-app").
- The Quest tab persistent banner (per design §5) reminds the user to take Importance.
- Re-enable notifications. Wait for next cron tick at 9 a.m. local. Push now arrives.

- [ ] **Step 5: Scenario 7.5 — Day-counter same-day multiple check-ins**

**Setup:** distinctCheckInDays = 0.

**Action:** Submit 4 mood check-ins on Apr 1 (00:01, 06:00, 14:00, 22:00). Submit 1 on Apr 3, 1 on Apr 5.

**Expected:** distinctCheckInDays = 3, lastDistinctDayKey = "2026-04-05". Per spec §11.

- [ ] **Step 6: Scenario 7.6 — 8-Dim re-take (30 days post-Quest)**

**Setup:** Test user with `questCompletedAt` set, `lastEightDimSubmittedAt` 31 days ago.

**Action:** Wait for next cron tick. Open Quest tab.

**Expected:** PendingSurveyDeck shows 8-Dim re-take. Push notification fires using `quest_notification_8dim_*` keys. Submit. Result card visible 7 days (per spec §8 `recentResultWindowDays`).

- [ ] **Step 7: Scenario 7.7 — State-of-Change re-take (90 days post-submission)**

**Setup:** `lastStateOfChangeSubmittedAt` 91 days ago.

**Action:** Open Quest tab.

**Expected:** SoC pending. Submit. Verify the radar chart's solid dot moves to the new stage (re-takes update the dot per spec §5.2 "Re-takes move the solid dot to the new stage").

- [ ] **Step 8: Scenario 7.8 — Satisfaction Check-In first available (180 days post-Quest)**

**Setup:** `questCompletedAt` 91 days ago. (Per spec §8: Satisfaction `firstAvailable` = `daysSinceQuestComplete` 90.)

**Action:** Open Quest tab.

**Expected:** PendingSurveyDeck shows Satisfaction. Submit. 32-question flow. Result shows top + lowest categories per spec §4.3.

- [ ] **Step 9: Scenario 7.9 — Importance re-take (210 days post-submission, focus may shift)**

**Setup:** `importanceCheckInSubmittedAt` 211 days ago, current focus = "emotional".

**Action:** Open Quest tab. Submit re-take with answers favoring "social".

**Expected:** Per spec §13 acknowledged Phase 4: focus dimension may change. `quest_state.focusDimension` updates to "social". Radar chart's previously-focus dim ("emotional") becomes a single dim dot at its last SoC stage; new focus axis ("social") gets 5 outline dots (no solid dot until next SoC submission).

Note: spec §5.2 calls out that the multi-dot rendering branch is unreachable in MVP without dimension switching; this Phase-4 re-take **is** the MVP path that makes it reachable. Verify rendering matches §5.2 table.

- [ ] **Step 10: Record outcomes and commit**

Tick each scenario in the checklist. Commit:

```bash
git add docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md
git commit -m "qa(quest): record edge-case manual QA results (timezone, DND, re-takes)"
```

---

## Task 8: Deck-of-cards animation polish

**Purpose:** Spec §13.11 calls out the deck-of-cards animation as a "notable UI investment". Plan 5 (or wherever the deck is built) shipped functional animation; Plan 7 polishes timing and feedback.

**Files:**
- Modify: `Soulverse/Features/Quest/Views/PendingSurveyDeck/PendingSurveyDeckView.swift`

This task uses TDD-lite: each polish item has an observable expected behaviour the engineer verifies on simulator. No unit tests (animation timing is integration-level).

- [ ] **Step 1: Frame-timing for offset cards entering / leaving**

**Acceptance:** When a new survey enters pendingSurveys (e.g., after Day-7 mood check-in), the new card slides into the back of the deck over 350 ms with `UIView.AnimationOptions.curveEaseOut`. When the front card is submitted and leaves, it rotates 8 degrees and slides up + fades out over 400 ms with `curveEaseIn`; the next card simultaneously moves forward over 300 ms.

**Implementation:** Wrap the existing additions/removals in `UIView.animate(withDuration:delay:options:animations:completion:)` blocks. Extract durations into `private enum Animation` constants:

```swift
private enum Animation {
    static let cardEnterDuration: TimeInterval = 0.35
    static let cardExitDuration: TimeInterval  = 0.40
    static let cardPromoteDuration: TimeInterval = 0.30
    static let cardExitRotation: CGFloat = 8.0  // degrees
}
```

**Verification:** Simulator → trigger Day-7 transition; observe card slide-in. Submit Importance → observe rotate-out + promote. No visible jitter, no 1-frame pop.

- [ ] **Step 2: Tap-response feedback on the front card**

**Acceptance:** On `touchesBegan`, the front card scales to 0.97 over 100 ms. On `touchesEnded`, it scales back to 1.0 over 150 ms and the survey opens. On `touchesCancelled`, it scales back without opening.

**Implementation:** Override `touchesBegan/Ended/Cancelled` on the front-card view (or add a `UIGestureRecognizer` with `delaysTouchesBegan = false`). Use `UIView.animate` with the durations above.

**Verification:** Simulator → tap-and-hold the front card; observe the scale-down and the spring-back if the touch moves out before lift.

- [ ] **Step 3: Smooth rotation on submission**

**Acceptance:** When the user submits a survey and the next-pending rotates forward, the rotation transform interpolates linearly over 300 ms, not stepwise.

**Implementation:** Use `UIView.animate` with `[.curveEaseInOut, .beginFromCurrentState]` on the offset cards. Avoid setting the transform multiple times in a single run loop; coalesce.

**Verification:** Simulator with a 3-survey deck (Day 22+ user with all three pending). Submit the front card; the back two cards smoothly slide forward by their offset delta.

- [ ] **Step 4: Build + visual smoke**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Run the app; verify all three behaviours.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/PendingSurveyDeck/PendingSurveyDeckView.swift
git commit -m "polish(quest): tune deck-of-cards animation timing and tap feedback"
```

---

## Task 9: Locked-card hint copy proximity verification

**Purpose:** Spec §5.3 defines exact hint copy for locked-card states based on distance to the unlock threshold. Plan 2 implemented the strings; Plan 7 verifies the rendering at each boundary.

**Files:**
- Audit-only (no code changes expected); fixes patch `QuestViewModel` if found

This is a manual verification task. For each test case, set `quest_state.distinctCheckInDays` in Firestore via console, open the Quest tab, and confirm the hint copy matches.

- [ ] **Step 1: Test cases (locked 8-Dimensions card)**

| `distinctCheckInDays` | Expected hint |
|---|---|
| 1 | "On Day 7, you'll see your 8 wellness dimensions." (or per the actual l10n key) |
| 4 | "On Day 7, you'll see your 8 wellness dimensions." |
| 5 | "Just 2 more check-ins!" |
| 6 | "Just 1 more check-in!" |

(Mapping: distance > 3 → first variant; distance ≤ 2 → "Just N more"; distance == 1 → "Just 1 more".)

- [ ] **Step 2: Test cases (locked custom habit slot)**

| `distinctCheckInDays` | Expected hint |
|---|---|
| 1 | "On Day 14, you'll be able to add your own habit." |
| 10 | "On Day 14, you'll be able to add your own habit." |
| 12 | "Just 2 more check-ins!" |
| 13 | "Just 1 more check-in!" |

- [ ] **Step 3: Verify and record**

Tick in checklist. If a value renders incorrectly, file a bug pointing to `QuestViewModel.lockedHintCopy(for:)` (or equivalent), fix the proximity logic, add a unit test in `QuestViewModelTests`, and re-run.

- [ ] **Step 4: Commit (only if a bug was found)**

```bash
git add Soulverse/Features/Quest/ docs/superpowers/qa/
git commit -m "fix(quest): correct locked-card hint copy at boundary days"
```

---

## Task 10: Accessibility (VoiceOver) basic pass

**Purpose:** Spec §11 calls for a "Manual QA checklist" that includes accessibility. Plan 7 ensures VoiceOver reads each Quest surface meaningfully.

**Files:**
- Modify: `Soulverse/Features/Quest/Views/ProgressSection/QuestProgressSectionView.swift`
- Modify: `Soulverse/Features/Quest/Views/EightDimensionsCard/QuestRadarChartView.swift`
- Modify: `Soulverse/Features/Quest/Views/HabitCheckerSection/HabitCard.swift`
- Modify: `Soulverse/Features/Quest/Views/HabitCheckerSection/HabitIncrementButton.swift`
- Modify: `Soulverse/Features/Quest/Views/PendingSurveyDeck/PendingSurveyDeckView.swift`

- [ ] **Step 1: ProgressSection — accessibility label**

**Acceptance:** With VoiceOver on, focusing the progress section announces "Day 7 of 21. Stage 2."

**Implementation:**

```swift
// In QuestProgressSectionView.update(state:)
self.isAccessibilityElement = true
self.accessibilityLabel = String(
    format: NSLocalizedString("quest_progress_a11y_label",
                              comment: "VoiceOver label for top progress section"),
    state.distinctCheckInDays, 21, state.stage
)
self.accessibilityTraits = .header
```

Add `quest_progress_a11y_label` = `"Day %d of %d. Stage %d."` to en strings.

- [ ] **Step 2: Radar chart — accessibility label**

**Acceptance:** Focusing the radar chart announces the focus dimension and the current SoC stage if assigned. Locked state announces "Locked. Unlocks at Day 7."

**Implementation:** Set `isAccessibilityElement = true` on `QuestRadarChartView`, treat it as a single element (do not expose individual dots). Compose `accessibilityLabel` from focus + stage + locked-state.

Add the corresponding l10n keys.

- [ ] **Step 3: Habit increment buttons — accessibility labels**

**Acceptance:** Each button announces e.g. "Add 5 minutes to Exercise. Today: 30 minutes."

**Implementation:** In `HabitIncrementButton`, set:

```swift
self.accessibilityLabel = String(
    format: NSLocalizedString("quest_habit_increment_a11y_label",
                              comment: "VoiceOver label for habit + amount + unit + today total"),
    amount, unitDisplay, habitName, todayTotal, unitDisplay
)
```

- [ ] **Step 4: Locked-card hint copy — readable by VoiceOver**

**Acceptance:** Focusing a locked card announces title + the proximity hint (e.g., "8 Dimensions card, locked. Just 1 more check-in!").

**Implementation:** Compose `accessibilityLabel` on the card view to concatenate title + locked-status + hint.

- [ ] **Step 5: Deck-of-cards — navigable**

**Acceptance:** With VoiceOver on, the user can:
1. Focus the front card, hear "Importance Check-In, due today, double-tap to take".
2. Swipe right to focus the "+N more" badge if present, hear "2 more surveys pending".

**Implementation:** Front card is an accessibility element with `accessibilityTraits = .button`. Offset cards behind it are `accessibilityElementsHidden = true`. The "+N more" badge is its own accessibility element with a meaningful label.

- [ ] **Step 6: Run the VoiceOver pass on simulator**

Settings → Accessibility → VoiceOver → On (or Cmd+F5 on simulator with VoiceOver enabled in Mac System Settings → Accessibility for the simulator). Tab through every Quest surface in order.

Record outcomes in the checklist file (created in Task 12).

- [ ] **Step 7: Commit**

```bash
git add Soulverse/Features/Quest/ Soulverse/en.lproj/Localizable.strings
git commit -m "a11y(quest): add VoiceOver labels for progress, radar, habits, deck"
```

---

## Task 11: Pre-launch infrastructure checklist (D21 items 4–11)

**Purpose:** Spec §12 lists 11 pre-launch items. Plan 1 covered items 1–3 (Blaze, APNs key, key uploaded). Plan 6 covered items related to FCM token registration and notification permission UX. Plan 7 verifies the remaining items 4–11 are in place.

**Files:**
- New: `docs/superpowers/qa/2026-05-06-quest-mvp-prelaunch-checklist.md` (created in this task)

- [ ] **Step 1: Create the checklist file**

Create `docs/superpowers/qa/2026-05-06-quest-mvp-prelaunch-checklist.md`:

```markdown
# Onboarding Quest MVP — Pre-launch Infrastructure Checklist (Plan 7 Task 11)

Ticking each item: include date, who verified, and the URL/screenshot/console-output that confirms it.

## D21 items 1–3 (covered by Plan 1; re-verify here)
- [ ] D21-1: Firebase project on Blaze plan. Verified: ____________ (date, name)
- [ ] D21-2: APNs auth key generated. Verified: ____________
- [ ] D21-3: APNs key uploaded to Firebase. Verified: ____________

## D21 items 4–11 (Plan 7 scope)
- [ ] D21-4: Firebase Cloud Logging quota / retention configured. Verified: ____________
- [ ] D21-5: Cloud Monitoring alert on function error rate >5% over 1-hour rolling window. Verified: ____________
- [ ] D21-6: `firestore.indexes.json` deployed; index for `quest_state.notificationHour` status = Ready. Verified: ____________
- [ ] D21-7: `firestore.rules` deployed; rules-emulator tests pass against deployed rules. Verified: ____________
- [ ] D21-8: `en.lproj/Localizable.strings` complete (~322 keys). Verified by Plan 7 Task 4: ____________
- [ ] D21-9: Notification permission UX requested at registration completion (no soft pre-prompt). Verified by Plan 6 + Plan 7 Task 13 smoke test: ____________
- [ ] D21-10: APNs production entitlement signed into Release build. Verified: ____________
- [ ] D21-11 (FLAG TO PRODUCT, not engineering): App Store screenshots and metadata. Status: ____________

## Sign-off
- Engineering lead: ____________ (date)
- QA lead:          ____________ (date)
- Product lead:     ____________ (date)
```

- [ ] **Step 2: Verify D21-4 (Cloud Logging quota / retention)**

In Google Cloud Console for the Firebase project:
- Navigate to Logging → Logs Storage.
- Confirm default 30-day retention (or product-defined value) is enabled.
- Tick D21-4 with the Cloud Console URL.

- [ ] **Step 3: Verify D21-5 (Cloud Monitoring alert)**

Cloud Monitoring → Alerting → Create Policy:
- Metric: `cloudfunctions.googleapis.com/function/execution_count`
- Filter: `status != "ok"` divided by total executions
- Threshold: > 5% over 1-hour rolling window
- Notification channel: email `dev@soulverse.life`
Tick D21-5 with the policy ID.

- [ ] **Step 4: Verify D21-6 (Firestore indexes deployed)**

Firebase Console → Firestore → Indexes. Confirm the single-field index on `quest_state.notificationHour (ascending)` is in **Ready** state. Tick D21-6 with screenshot.

- [ ] **Step 5: Verify D21-7 (Security Rules deployed and tested against prod)**

Re-run Plan 1's rules-emulator suite, but configure it to point at the deployed rules:

```bash
cd functions
# Confirm rules in firestore.rules match what's deployed (firebase deploy --only firestore:rules will report drift)
firebase deploy --only firestore:rules --dry-run
# Run the rules tests
npm test -- test/rules/firestoreRules.test.ts
```

Expected: dry-run reports "no changes"; rules tests all pass. Tick D21-7.

- [ ] **Step 6: Verify D21-8 (en strings complete)**

Already done by Task 4. Reference Task 4's output. Tick D21-8.

- [ ] **Step 7: Verify D21-10 (APNs production entitlement)**

Open `Soulverse.entitlements` (or the production target's entitlements file). Confirm `aps-environment = production`. Open Build Settings for the Soulverse (Release) target → Code Signing Identity → confirm a production-signed certificate. Tick D21-10.

- [ ] **Step 8: D21-11 — FLAG TO PRODUCT**

This item is product-owned. The plan logs it for visibility, not execution. In the checklist, set status to "Pending product".

- [ ] **Step 9: Commit the checklist**

```bash
git add docs/superpowers/qa/2026-05-06-quest-mvp-prelaunch-checklist.md
git commit -m "qa(quest): add pre-launch infrastructure checklist (D21 items 4-11)"
```

---

## Task 12: Manual-QA checklist file (consolidated)

**Purpose:** Tasks 6, 7, 9, 10 reference a shared checklist. This task creates the file up-front so each prior task can append entries.

**Files:**
- New: `docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md`

This task is execution-order-independent of Tasks 6–10 — execute it BEFORE Tasks 6–10 if running sequentially, or skip ahead if it's already been created.

- [ ] **Step 1: Create the file**

Create `docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md`:

```markdown
# Onboarding Quest MVP — Manual QA Checklist (Plan 7)

Each row: device (sim / real), iOS version, date, tester initials, Pass/Fail, notes.

## Happy paths (Plan 7 Task 6)
- [ ] 6.1 Day 7 → Importance → 8-Dim flow. ____________
- [ ] 6.2 Day 14 milestone + custom habit unlock. ____________
- [ ] 6.3 Day 21 → State-of-Change pending; progress bar hides. ____________

## Edge scenarios (Plan 7 Task 7)
- [ ] 7.1 Cross-timezone day-counter (UTC+8 night → next morning). ____________
- [ ] 7.2 Cross-timezone travel (UTC+8 → UTC-5 mid-day) + telemetry event. ____________
- [ ] 7.3 DST autumn fallback. ____________
- [ ] 7.4 Notifications disabled system-wide; in-app surfaces still work. ____________
- [ ] 7.5 Day-counter same-day multiple check-ins → counts as 1. ____________
- [ ] 7.6 8-Dim re-take 30 days post-Quest. ____________
- [ ] 7.7 State-of-Change re-take 90 days post-submission. ____________
- [ ] 7.8 Satisfaction Check-In first available 90 days post-Quest. ____________
- [ ] 7.9 Importance re-take 210 days; focus dim may shift (Phase 4 reachable). ____________

## Locked-card hint copy proximity (Plan 7 Task 9)
- [ ] 9.1 8-Dim card hints at days 1, 4, 5, 6. ____________
- [ ] 9.2 Custom habit slot hints at days 1, 10, 12, 13. ____________

## Accessibility / VoiceOver (Plan 7 Task 10)
- [ ] 10.1 ProgressSection reads "Day N of 21. Stage S." ____________
- [ ] 10.2 Radar chart reads focus + SoC stage; locked state reads "Unlocks at Day 7". ____________
- [ ] 10.3 Habit increment buttons read "Add N {unit} to {habit}. Today: M {unit}." ____________
- [ ] 10.4 Locked-card hint copy is announced. ____________
- [ ] 10.5 Deck-of-cards: front card announces survey type + "double-tap to take"; "+N more" badge announces count. ____________

## Sign-off
- QA lead: ____________ (date)
- Engineering lead: ____________ (date)
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md
git commit -m "qa(quest): create manual QA checklist for Plan 7 execution"
```

---

## Task 13: Final Debug + Release builds on simulator

**Purpose:** The build verification command from `CLAUDE.md` runs Debug. Plan 7 also runs a Release build to surface any optimizer-only bugs (e.g., missing `final` on a class breaking Whole Module Optimization, or a test-only dependency leaking into Release).

**Files:**
- (No code changes expected; Debug and Release configurations should both compile)

- [ ] **Step 1: Debug build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 2: Release build**

```bash
xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" \
  -configuration Release \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: BUILD SUCCEEDED. If Release fails where Debug passed, common culprits:

- Test-only types referenced by production code (e.g., `XCTAssert` leaked).
- `#if DEBUG` block missing a non-DEBUG fallback.
- Strict-concurrency warnings promoted to errors at `-O`.

Fix as needed, re-run.

- [ ] **Step 3: Smoke-test the Release simulator binary**

After Release build, install on simulator:

```bash
xcrun simctl install booted "$(xcodebuild -workspace Soulverse.xcworkspace -scheme Soulverse -configuration Release -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' -showBuildSettings build 2>/dev/null | grep -m1 BUILT_PRODUCTS_DIR | awk '{print $3}')/Soulverse.app"
xcrun simctl launch booted life.soulverse.app
```

(Bundle ID may differ; consult `Info.plist`.)

Open Quest tab; confirm it loads without crashing.

- [ ] **Step 4: Commit (only if a Release-only fix was needed)**

```bash
git add Soulverse/
git commit -m "fix(quest): resolve Release-build issue uncovered in final QA"
```

If no fix needed, no commit — just record "Release build green" in the QA checklist.

---

## Task 14: Final TestFlight builds via fastlane

**Purpose:** Ensure existing fastlane lanes (`fastlane ios development` and `fastlane ios release`) still work post-Quest changes. The lanes upload to TestFlight; this is the final validation before App Store submission.

**Files:**
- (No code changes expected; fastlane lanes are unchanged)

This task is gated by Pre-launch items 4–10. Do NOT run if any infrastructure item is incomplete.

- [ ] **Step 1: Verify all checklists complete**

Open `docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md`. All checkboxes ticked.
Open `docs/superpowers/qa/2026-05-06-quest-mvp-prelaunch-checklist.md`. D21 items 1–10 ticked. D21-11 (App Store screenshots) flagged to product but not blocking the TestFlight build.

- [ ] **Step 2: Development TestFlight build**

```bash
fastlane ios development
```

Expected: build uploaded to App Store Connect under the "Soulverse Dev" app. TestFlight notifies internal testers. Verify the build appears in App Store Connect within ~15 minutes.

- [ ] **Step 3: Real-device smoke test on the development build**

Install the dev TestFlight build on a real iPhone. Sign in with a fresh account. Run through:
- Day-1 Mood Check-In CTA → submit a check-in.
- Quest tab loads with "Day 1 of 21".
- Habit increments persist across app relaunches.
- Notification permission dialog appears at registration completion (Pre-launch 9 verification).

- [ ] **Step 4: Production TestFlight build**

```bash
fastlane ios release
```

Expected: build uploaded to App Store Connect under the "Soulverse" (production) app. Verify build appears.

- [ ] **Step 5: Real-device smoke test on the production build**

Same flow as Step 3, on the production TestFlight build.

- [ ] **Step 6: Tag the release**

```bash
git tag -a quest-mvp-v1.0 -m "Plan 7 complete: Quest MVP feature-complete and on TestFlight"
git push origin quest-mvp-v1.0
```

- [ ] **Step 7: Final sign-off entry in checklist**

In `docs/superpowers/qa/2026-05-06-quest-mvp-manual-qa-checklist.md`, fill in the "Sign-off" section: QA lead initials + date, Engineering lead initials + date.

```bash
git add docs/superpowers/qa/
git commit -m "qa(quest): final sign-off — Quest MVP on TestFlight"
```

---

## Plan summary & next steps

**This plan delivers:**
- Audited and patched theme, layout, component-reuse, and localization compliance across `Soulverse/Features/Quest/`.
- Polished deck-of-cards animation with named timing constants.
- Verified locked-card hint copy at all proximity boundaries.
- Added VoiceOver labels to every Quest surface.
- Completed manual QA checklist covering happy paths, cross-timezone edges, DND, day-counter edges, and survey re-takes.
- Completed pre-launch infrastructure checklist (D21 items 4–11).
- Final Debug and Release builds green on simulator.
- TestFlight builds (development + release) via existing fastlane lanes.

**Out of scope of this plan:**
- App Store submission itself (product runs after this plan).
- App Store screenshots and metadata (D21-11, flagged to product).
- Any net-new code (covered in Plans 2–6).
- Marketing copy.

**The Onboarding Quest MVP is feature-complete after this plan.** Submission-day work consists of (1) product attaching screenshots/metadata in App Store Connect and (2) clicking Submit for Review.

**Watch items carried into v1.1** (per spec §13):
- zh-TW localization (~322 strings).
- Focus-dimension switching UI (currently the multi-dot radar branch is reachable only via Importance re-take per Task 7.9).
- Day-21 completion celebration UI.
- Cron sharding via Pub/Sub fan-out if user count exceeds ~10k matched per cron tick.
- Cross-timezone habit-bucket asymmetry (per spec §13.7) — capture per-write timezone in a parallel `habit_logs` collection if user research surfaces confusion.
