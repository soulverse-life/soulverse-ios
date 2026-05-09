# Onboarding Quest — End-to-End Testing Guide

**For:** Verifying Plans 1, 2, 6 (deployed Cloud Functions + iOS Quest tab shell + FCM client integration) work end-to-end.

**Branch:** `feat/onboarding-quest`
**Status:** Plans 1, 2, 6 implemented. Plans 3 (Habit Checker), 4 (Surveys), 5 (Radar chart), 7 (final QA) not yet implemented — Quest tab will show ProgressSection + locked 8-Dim card only.

---

## Prerequisites

Before testing, confirm these are set up:

### Firebase project (`soulverse-35106`)

- [x] **Blaze plan active** (verified — Cloud Functions deployed)
- [x] **Cloud Functions deployed** — `onUserCreated`, `onMoodCheckInCreated`, `onSurveySubmissionCreated`, `questNotificationCron` all in `us-central1`. Verify at https://console.firebase.google.com/project/soulverse-35106/functions
- [x] **Security Rules deployed** with the new `quest_state`, `survey_submissions`, `notification_state`, `devices` paths
- [x] **`notificationHour` index built** — wait until status reads "Ready" at https://console.firebase.google.com/project/soulverse-35106/firestore/indexes
- [x] **APNs auth key uploaded** to Firebase project (Cloud Messaging tab)

### iOS device / simulator

- [ ] iOS 16.6+ device or **iPhone 16 Pro Max simulator** running iOS 26.0
- [ ] Xcode 16+ installed
- [ ] Valid Apple Developer account if testing on physical device (push delivery requires APNs which needs a real device)
- [ ] `pod install` has been run in the repo

### Build the app

```bash
cd /Users/mingshing/Soulverse
open Soulverse.xcworkspace
```

Or via CLI:
```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse Dev" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

---

## Test 1 — Backend smoke (no app required)

**Goal:** Confirm Cloud Functions correctly initialize `quest_state` and respond to mood check-in writes.

### Setup

In Firebase Console → Authentication → Users, create a test user (e.g. `quest-test-1@example.com`). Note the UID from the Users tab.

### Steps

1. **Verify `quest_state` was auto-created**
   - Go to Firestore → `users/{uid}/quest_state/state`.
   - **Expected:** doc exists with default fields:
     - `distinctCheckInDays: 0`
     - `lastDistinctDayKey: null`
     - `focusDimension: null`
     - `pendingSurveys: []`
     - `notificationHour: 9` (or some 0–23 value)
     - `timezoneOffsetMinutes: 0`
     - `notification_state: {}`

2. **Write a mood check-in manually**
   - Firestore → `users/{uid}/mood_checkins` → Add document.
   - Doc ID: auto.
   - Fields:
     ```
     colorHex: "#FFAABB"      (string)
     colorIntensity: 0.5      (number)
     emotion: "happy"         (string)
     topic: "physical"        (string — must be one of the 8 dimensions)
     evaluation: "neutral"    (string)
     createdAt: <serverTimestamp>  (use the "Server timestamp" type — Firebase Console offers this)
     timezoneOffsetMinutes: 480  (number — UTC+8)
     ```
   - **Expected (within 2–5 seconds):** `quest_state` updates:
     - `distinctCheckInDays: 1`
     - `lastDistinctDayKey: "<today's local date in UTC+8>"`

3. **Write 6 more mood check-ins on different calendar days**
   - Repeat step 2 with different `createdAt` server-timestamps. The trick: server-timestamp can't be backdated via console, but you CAN use the Firebase CLI emulator OR temporarily set the `timezoneOffsetMinutes` to a value that buckets the date differently.
   - **Easier:** simulate from the iOS app (Test 3 below).

4. **Verify Day 7 milestone fires**
   - When `distinctCheckInDays` reaches 7:
     - **Expected:** `quest_state.pendingSurveys: ["importance_check_in"]`
     - **Expected:** `quest_state.surveyEligibleSinceMap: { "importance_check_in": <timestamp> }`

5. **Submit an Importance Check-In manually** (optional — exercises the survey path)
   - Firestore → `users/{uid}/survey_submissions` → Add document.
   - Doc ID: auto.
   - Fields:
     ```
     submissionId: "manual-test-1"
     surveyType: "importance_check_in"
     submittedAt: <serverTimestamp>
     appVersion: "1.0.0"
     submittedFromQuestDay: 7
     payload: {                     (map)
       responses: []                (array)
       computed: {                  (map)
         categoryMeans: {           (map of strings to numbers)
           physical: 3.0
           emotional: 4.5
           social: 3.5
           intellectual: 3.0
           spiritual: 2.5
           occupational: 4.0
           environmental: 3.0
           financial: 3.5
         }
         topCategory: "emotional"
         tieBreakerLevel: 1
       }
     }
     ```
   - **Expected (within 2–5 seconds):** `quest_state` updates:
     - `focusDimension: "emotional"`
     - `focusDimensionAssignedAt: <timestamp>`
     - `importanceCheckInSubmittedAt: <timestamp>`
     - `pendingSurveys: ["8dim"]` (was `["importance_check_in"]`)
     - `surveyEligibleSinceMap.8dim` populated.

6. **Cleanup**
   - Delete the test user from Authentication. This cascades and deletes their `users/{uid}/...` data.

### What this proves

- `onUserCreated` initializes state.
- `onMoodCheckInCreated` increments `distinctCheckInDays` correctly.
- `onSurveySubmissionCreated` writes `focusDimension` for Importance and updates `pendingSurveys`.
- The schedule engine correctly transitions from Importance pending → 8-Dim pending after submission.

---

## Test 2 — iOS app launch + timezone write

**Goal:** Confirm the iOS app writes `timezoneOffsetMinutes` and `notificationHour` to Firestore at app launch.

### Steps

1. Sign in to the app with an existing test user (or use Apple/Google sign-in to create one).
2. Wait ~3 seconds after the home screen appears.
3. Open Firebase Console → Firestore → `users/{your-uid}/quest_state/state`.
4. **Expected:** `timezoneOffsetMinutes` matches your device's local offset (e.g., `480` for UTC+8 / Asia/Taipei).
5. **Expected:** `notificationHour` is the UTC hour at which the user's local time is 9am. For UTC+8: `notificationHour: 1`. For UTC-7: `notificationHour: 16`.

### Switch device timezone test

1. Settings → General → Date & Time → toggle off "Set Automatically".
2. Tap Time Zone → pick a different one (e.g., America/Los_Angeles).
3. Background, then foreground the app.
4. **Expected (within 5 seconds):** `quest_state.timezoneOffsetMinutes` updates to the new offset; `notificationHour` updates to match.

### What this proves

- `FirestoreQuestService.writeCurrentTimezone(uid:)` correctly fires from `AppDelegate`.
- Security Rules accept the two-field write.

---

## Test 3 — Quest tab UI states (Plan 2)

**Goal:** Verify the Quest screen renders correctly across all stages.

### Stage 1 (Day 0–6)

1. Sign in as a fresh user (delete-and-recreate if needed).
2. Tap the **Quest tab** (5th tab in the tab bar).
3. **Expected:**
   - Top section shows "**Day 0 of 21**" pill.
   - 21-dot progress rail: all dots are inactive.
   - "**Do today's Mood Check-In →**" CTA button visible.
   - 8-Dimensions card host shows a **locked placeholder** with:
     - Lock icon at top
     - Title: "Your 8 Dimensions"
     - Hint: "On Day 7, you'll see your 8 Dimensions."
   - Survey section is **completely hidden** (no placeholder).

4. Tap the "**Do today's Mood Check-In →**" CTA.
5. **Expected:** Mood Check-In flow presents (existing feature).
6. Complete a mood check-in. Return to Quest tab.
7. **Expected:**
   - Day-N pill updates to "**Day 1 of 21**" (within ~1 second of returning, via `MoodCheckInCreated` notification + Firestore listener).
   - Daily CTA hides (already checked in today).
   - First dot is highlighted on the rail.

### Stage 1 → Stage 2 transition (Day 6 → 7)

If you want to fast-forward to Day 7, manually edit `quest_state.distinctCheckInDays = 7` in Firestore Console (this WILL be rejected by Security Rules in production — for testing, temporarily relax rules OR use the Firebase Emulator).

8. **Expected at Day 7:**
   - Pill: "Day 7 of 21".
   - 8-Dim card hint changes from "On Day 7..." → empty (Plan 2's locked card collapses).
   - Plan 5 will replace the locked card with the radar chart at this point — for now, the host is empty.
   - **Survey section appears** (but empty until Plan 4 ships).

### Stage 2 (Day 7–13) locked-card hint progression

Manually set `distinctCheckInDays` to various values:

| Days | 8-Dim hint copy | Custom Habit hint copy |
|---|---|---|
| 1 | "On Day 7, you'll see your 8 Dimensions." | "On Day 14, you'll add your own habit." |
| 4 | "On Day 7, you'll see your 8 Dimensions." | "On Day 14, you'll add your own habit." |
| 5 | "Just 2 more check-ins!" | "On Day 14, you'll add your own habit." |
| 6 | "Just 1 more check-in!" | "On Day 14, you'll add your own habit." |
| 7 | (empty — card unlocked) | "Just 7 more check-ins!" — **wait, no:** "On Day 14, you'll add your own habit." (still ≥3 days away) |
| 12 | (empty) | "Just 2 more check-ins!" |
| 13 | (empty) | "Just 1 more check-in!" |
| 14 | (empty) | (empty — card unlocked) |

### What this proves

- `QuestViewModel` derives all states correctly.
- `QuestProgressSectionView` renders the pill + dots + CTA.
- `QuestLockedCardView` renders proximity-aware hint copy.
- Firestore listener-driven UI updates work in real-time.
- Mood Check-In submission triggers re-composition via `MoodCheckInCreated` notification.

---

## Test 4 — FCM token persistence (Plan 6)

**Goal:** Confirm FCM tokens are written to Firestore for signed-in users.

⚠️ **Real device required.** APNs (and therefore FCM) doesn't work on iOS Simulator.

### Steps

1. Build and install on a physical iPhone (sideload via Xcode → Window → Devices and Simulators).
2. **Fresh-install** the app (uninstall any prior build first).
3. Walk through onboarding (sign in → birthday → gender → naming → submit).
4. **Expected immediately upon landing on home screen:**
   - System dialog: "**'Soulverse' Would Like to Send You Notifications**" with Allow / Don't Allow buttons.
5. Tap **Allow**.
6. Open Xcode console (View → Debug Area → Activate Console).
7. **Expected console logs:**
   ```
   [FCM] APNs deviceToken: <hex string>
   ```
8. Open Firebase Console → Firestore → `users/{your-uid}/devices/{deviceId}`.
9. **Expected** doc fields:
   - `fcmToken: "<some long string>"`
   - `platform: "ios"`
   - `appVersion: "1.0.0"` (or your bundle's version string)
   - `lastSeenAt: <recent timestamp>`

### What this proves

- `MessagingDelegate.messaging(_:didReceiveRegistrationToken:)` fires on device.
- `FirestoreDeviceTokenService.writeToken(...)` correctly persists to `users/{uid}/devices/{deviceId}`.
- Security Rules allow the user to write their own device tokens.

---

## Test 5 — Push notification delivery (Plan 1 + Plan 6 end-to-end)

**Goal:** Verify a Cloud Function-dispatched push lands on the device and deep-links to the Quest tab.

⚠️ **Real device + Test 4 prerequisites complete.**

### Option A: Trigger via the actual schedule engine (preferred)

1. In Firebase Console → Firestore → manually edit `users/{your-uid}/quest_state/state`:
   - `notificationHour: <currentUTCHour>` (e.g., if it's 14:30 UTC right now, set this to `14`)
   - `pendingSurveys: ["importance_check_in"]`
   - `distinctCheckInDays: 7`
   - Leave `notification_state.importance_check_in_first` empty (or unset).
2. Wait until the top of the next hour. The cron fires at `:00`.
3. **Expected:** push arrives on device:
   - Title: "Help us understand what matters to you 🌱"
   - Body: "Take the 5-minute Importance Check-In to discover your focus area."

### Option B: Send a test push via Firebase Console (faster, bypasses schedule)

1. Firebase Console → Cloud Messaging → "**Create your first campaign**" or "**New campaign**" → "**Notifications**".
2. **Notification title:** "Test Quest Push"
3. **Notification text:** "If you see this, FCM works"
4. **Target:** Single device → paste the FCM token from Test 4.
5. **Custom data** (under Additional options):
   - Key: `notificationKey`
   - Value: `importance_check_in_first`
6. Send.
7. **Expected:** push arrives within ~10 seconds.

### Verify deep-link routing

1. Background the app (don't kill it).
2. Tap the push notification on the lock screen or notification center.
3. **Expected:**
   - App foregrounds.
   - Quest tab is automatically selected (5th tab).
   - Console log: `[FCM] Routing Quest notification: importance_check_in_first`

### Verify foreground push behavior

1. With the app already in foreground (any tab), trigger another test push.
2. **Expected:**
   - Banner appears at the top of the screen with sound.
   - App stays on the current screen (doesn't auto-navigate when in foreground).

### What this proves

- Plan 1's `questNotificationCron` correctly identifies users by `notificationHour`.
- Plan 1's idempotency (`lastSentAt`) prevents duplicate sends.
- Plan 6's `MessagingDelegate` token registration works.
- Plan 6's `inAppRouting` correctly deep-links Quest pushes.
- Plan 6's foreground presentation rule fires sound for Quest pushes.

---

## Test 6 — Cross-timezone scenarios

**Goal:** Verify the timezone-aware day-bucketing rules behave correctly in adversarial conditions.

### Mood check-in same calendar day, two different timezones

1. Settings → set device tz to UTC+8 (e.g., Asia/Taipei).
2. Open the app, do a mood check-in.
3. Note the `createdAt` and `timezoneOffsetMinutes` of the new doc in Firestore.
4. Switch device tz to UTC-5 (e.g., America/New_York).
5. Open the app, do another mood check-in.
6. **Expected:** `distinctCheckInDays` = 2 (because the two check-ins bucket into different local days even though they were on the same UTC day in some range).
7. **OR Expected:** `distinctCheckInDays` = 1 (because the bucketing rule uses each record's STORED offset, and if both check-ins happened to bucket into the same date in their respective local times, it counts as 1).

The exact result depends on the time of day at write time, but the test confirms:
- Day-counter is computed from `createdAt + timezoneOffsetMinutes`, NOT from the current device time.

### Habit logging same calendar day, two different timezones

(Plan 3 not implemented yet — defer this test.)

---

## Test 7 — Permission edge cases

### "Don't Allow" path

1. Fresh-install the app.
2. Walk through onboarding.
3. When the system permission dialog appears, tap **Don't Allow**.
4. **Expected:** no FCM token is written to Firestore (verify by checking `users/{uid}/devices/{deviceId}` — it should not exist).
5. Manually toggle notifications on in Settings → Soulverse → Notifications.
6. Reopen the app.
7. **Expected:** within ~3 seconds, FCM token is written to Firestore (Messaging delegate fires automatically).

### Already authorized

1. After granting permission once, kill and re-open the app.
2. **Expected:** no permission dialog (system suppresses it). FCM token writes happen silently on launch.

---

## Test 8 — Real-time listener updates

**Goal:** Verify the Quest tab reflects backend changes within ~1 second.

### Steps

1. Open the app on Quest tab.
2. Open Firebase Console → Firestore in a browser.
3. Navigate to `users/{your-uid}/quest_state/state`.
4. Edit `distinctCheckInDays` to a different value (e.g., 5 → 12).
5. **Expected (within ~1 second):** the Quest tab pill updates to "Day 12 of 21" without any user interaction.
6. The dots redraw to highlight the new active dot.

### What this proves

- `FirestoreQuestService.listen(uid:onUpdate:)` works.
- `QuestViewPresenter` re-composes the view model on every snapshot.
- `QuestViewController` reloads the table on `didUpdate(viewModel:)`.

---

## Known limitations / not-yet-implemented

The following are documented but not yet implemented (Plans 3, 4, 5, 7):

- **Habit Checker section (Plan 3):** Quest tab will show no habit cards. The "Add Custom Habit" affordance won't render until Plan 3 ships.
- **Survey section (Plan 4):** When `distinctCheckInDays >= 7`, the survey section becomes visible but is empty (no PendingSurveyDeck or RecentResultCardList).
- **Radar chart (Plan 5):** The 8-Dimensions card host is just a locked placeholder; the actual radar chart with axis dots + EmoPet center isn't built yet.
- **Final QA pass (Plan 7):** Theme tokens like `.themeAccent`, `.themeBackgroundSecondary`, `.themeIconMuted` referenced in design spec §10 haven't been added to UIColor+Extensions yet — Plans 3-5 will need to substitute or add them.
- **Localization:** zh-TW translations are deferred to v1.1 per design spec.

---

## Quick smoke checklist (5-minute verification)

For a fast "is the basic stuff working" check:

- [ ] Build succeeds: `xcodebuild ... build -quiet` returns 0
- [ ] Firebase functions deployed: `firebase functions:list` shows 4 functions
- [ ] Sign in with a test user → home screen appears → tab to Quest
- [ ] Quest tab renders Day-N pill, dot rail, and CTA
- [ ] Tap CTA → Mood Check-In flow opens → submit → return to Quest tab → pill updates within 2 seconds
- [ ] In Firestore, manually bump `distinctCheckInDays` → Quest tab pill updates within 1 second
- [ ] (Real device only) Allow notifications → FCM token in Firestore within 5 seconds
- [ ] (Real device only) Send Firebase Console test push with `notificationKey` → arrives → tap → Quest tab opens

If all 8 checks pass, Plans 1, 2, 6 are working end-to-end.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Quest tab shows "Day 0" forever, doesn't update on Mood Check-In | Listener not firing | Check Firestore Console → user has `quest_state/state` doc. If missing, `onUserCreated` didn't fire (check Cloud Functions logs). |
| Push arrives but tapping doesn't open Quest tab | `notificationKey` missing from payload | Confirm Cloud Function logs show `[FCM] dispatching to user X with notificationKey=Y`. Check `inAppRouting`'s entry log `[FCM] Routing Quest notification: ...` |
| FCM token not written to Firestore | APNs setup incomplete | Verify steps 2-3 of pre-launch infrastructure (APNs key generated + uploaded to Firebase). Check device has Push Notifications capability enabled. |
| `requestAuthorization` doesn't show dialog | Already responded once before | iOS suppresses the dialog after first response. Delete and reinstall the app to reset. |
| `notificationHour: 0` for everyone | App launched without `User.shared.userId` set | Verify auth flow completed before `application(_:didFinishLaunchingWithOptions:)` returns. Sign in, then check the value. |
| Cloud Functions cron didn't fire at expected hour | `notificationHour` mismatch | Check `quest_state.notificationHour` matches the current UTC hour. Cron only matches users whose local 9am = current UTC hour. |

---

## Cleanup

After testing:

```bash
# Delete test users from Firebase Console → Authentication
# Their data is auto-cleaned via cascading deletes.

# If you want to fully reset the simulator state:
xcrun simctl erase all
```

---

**End of testing guide.**
