# Onboarding Quest MVP — Pre-launch Infrastructure Checklist

**Spec:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md` §12
**Plan:** `docs/superpowers/plans/2026-05-06-quest-plan-7-polish-qa.md`

Items 1–3 were gated by Plan 1 (Cloud Functions); items 4–11 are gated here.

## Plan 1 (already gated)

- [x] **1.** Firebase project on Blaze plan (`soulverse-35106`)
- [x] **2.** Cloud Build Service Account has `roles/cloudbuild.builds.builder`
- [x] **3.** Cloud Functions deployed (4 functions live)

## Plan 7 gates

- [ ] **4.** Firebase Cloud Logging quota and retention configured (default 30-day OK for MVP). Owner: ops/admin.
- [ ] **5.** Cloud Monitoring alert: `cloudfunctions.googleapis.com/function/execution_count` filtered by `status != "ok"` / total > 5% over 1-hour rolling. Email channel = `dev@soulverse.life`. Owner: ops/admin.
- [ ] **6.** `firestore.indexes.json` deployed; verify single-field index on `quest_state.notificationHour` shows status **Ready**. Owner: iOS dev.
- [ ] **7.** `firestore.rules` deployed; re-run rules-emulator suite from Plan 1 Task 19 against deployed rules. Owner: iOS dev.
- [ ] **8.** `en.lproj/Localizable.strings` is the only launch-blocking localization. Verified by Plan 7 Task 4 (≥ 322 keys). Owner: iOS dev.
- [ ] **9.** Notification permission UX: system iOS dialog requested at registration. No custom soft pre-prompt. Smoke test fresh install on real device. Owner: iOS dev.
- [ ] **10.** APNs production entitlement: `aps-environment = production` signed into the Release build of Soulverse target. Owner: iOS dev.
- [ ] **11.** App Store screenshots + metadata: Quest tab screens for Day 1, Day 7-pending-Importance, Day 14, Day 21-completed. Owner: product. (Out of scope for engineering plan; flag to product so it does not block submission day.)

Items 4–10 are required before TestFlight Release-build deploy. Item 11 is required before App Store submission.

## Sign-off

- [ ] Engineering sign-off: __________
- [ ] Product sign-off: __________
- [ ] Date pushed to TestFlight: __________
- [ ] Date submitted to App Store: __________
