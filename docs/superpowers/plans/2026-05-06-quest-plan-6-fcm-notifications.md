# Onboarding Quest — Plan 6 of 7: FCM Client Integration + Notification Permission UX

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire the iOS client to Firebase Cloud Messaging (FCM) so server-dispatched Quest push notifications can land on the device. After this plan, every signed-in user has an FCM token persisted at `users/{uid}/devices/{deviceId}`, the system iOS notification-permission dialog is requested at registration completion, denied users see a dismissable in-app reminder banner on the Quest tab, and tapping a Quest push deep-links into the Quest tab. No new services or singletons are introduced — the token write is a ~5-line helper inline in the `MessagingDelegate` extension on `AppDelegate`, per the Phase 5 lightweight-integration decision.

**Architecture:** All FCM integration lives in `AppDelegate.swift` extensions. Token persistence writes a single document at `users/{uid}/devices/{deviceId}` via `FirebaseFirestore`, where `deviceId` is `UIDevice.current.identifierForVendor`. Tokens that fail to persist (e.g., offline at receive time) are queued in `UserDefaults` and retried on next successful auth + token. Permission UX is the system dialog only — no custom soft pre-prompt — invoked exactly once from `OnboardingCoordinator.handleOnboardingCompletion()`. Routing of push taps reuses the existing `AppCoordinator.inAppRouting()` path with a new `quest` destination.

**Tech Stack:** Swift, UIKit, FirebaseMessaging (already in Podfile), FirebaseFirestore, UserNotifications, UIDevice, UserDefaults, SnapKit, NSLocalizedString.

**Spec reference:** `docs/superpowers/specs/2026-05-01-onboarding-quest-design.md` (§4.5, §6.3, §12)

---

## File structure

After this plan, the repo will have:

```
Soulverse/
  AppDelegate.swift                                       # MODIFIED — uncomment Messaging,
                                                          #   add MessagingDelegate, token writes,
                                                          #   APNs token forwarding, deep-link routing
  Onboarding/Presenter/OnboardingCoordinator.swift        # MODIFIED — request notification
                                                          #   permission at registration completion
  Shared/Manager/AppCoordinator.swift                     # MODIFIED — add Quest deep-link
                                                          #   destination, route via notificationKey
  Shared/Service/FirestoreDeviceTokenService.swift        # NEW — 1 file, ~30 lines, the token
                                                          #   persistence + retry-queue helper
                                                          #   (kept inline-style: a single static
                                                          #   func + UserDefaults retry queue)
  Features/Quest/Views/QuestViewController.swift          # MODIFIED — show notifications-off
                                                          #   banner if permission denied
  Features/Quest/Views/QuestNotificationsOffBanner.swift  # NEW — small dismissable banner view
  Features/Quest/ViewModels/QuestViewModel.swift          # MODIFIED — track banner dismissal state
  en.lproj/Localizable.strings                            # MODIFIED — add banner copy keys
SoulverseTests/Tests/Quest/
  QuestNotificationsOffBannerTests.swift                  # NEW — banner visibility logic
  FirestoreDeviceTokenServiceTests.swift                  # NEW — token write + retry queue
```

**Out of scope (handled in other plans):**
- Cloud Function dispatch of pushes (Plan 1, already shipped)
- Quest tab business logic / radar / surveys (Plans 2–5)
- Final QA pass + theme audit (Plan 7)

---

## Pre-launch operational items (NOT TDD tasks)

These are infrastructure setup that humans must complete before push delivery works end-to-end. Track them as gates, not as engineering tasks:

- [ ] **Pre-launch 1:** APNs auth key (`.p8`) generated in Apple Developer Portal. Capture key ID + team ID. Owner: iOS dev with Apple Developer access. (D21 #2)
- [ ] **Pre-launch 2:** APNs key uploaded to Firebase project: Project Settings → Cloud Messaging → Apple app configuration → APNs Authentication Key. (D21 #3)
- [ ] **Pre-launch 3:** Verify the **Push Notifications** capability is enabled on both `Soulverse` and `Soulverse Dev` targets in `Soulverse.xcodeproj`, and **Background Modes → Remote notifications** is checked. Confirm `Soulverse.entitlements` file contains `aps-environment` with the appropriate value (`development` for Dev target, `production` for App Store builds). (D21 #8)
- [ ] **Pre-launch 4:** Confirm `GoogleService-Info.plist` for both Dev and Prod schemes contains a `GCM_SENDER_ID` (FCM cannot operate without it).

These four must be in place before Task 11 (smoke test on device). Tasks 1–10 can proceed against the simulator.

---

## Task 1: Add `FirestoreDeviceTokenService` skeleton + tests

**Files:**
- Create: `Soulverse/Shared/Service/FirestoreDeviceTokenService.swift`
- Create: `SoulverseTests/Tests/Quest/FirestoreDeviceTokenServiceTests.swift`

This service owns the single Firestore write at `users/{uid}/devices/{deviceId}`. It is intentionally small — the spec calls for "~5 lines of code" and explicitly NO separate full-blown service. We expose two static funcs: `writeToken(uid:deviceId:token:appVersion:)` and `flushPendingWrites(uid:)`. A pending write is stashed in `UserDefaults` if the Firestore write fails.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/FirestoreDeviceTokenServiceTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class FirestoreDeviceTokenServiceTests: XCTestCase {

    private let pendingKey = "soulverse.fcm.pendingTokenWrite"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
        super.tearDown()
    }

    func test_enqueuePendingWrite_storesPayloadInUserDefaults() {
        FirestoreDeviceTokenService.enqueuePendingWrite(
            deviceId: "device-1",
            token: "fcm-abc",
            appVersion: "1.0.0"
        )

        let stored = UserDefaults.standard.dictionary(forKey: pendingKey)
        XCTAssertEqual(stored?["deviceId"] as? String, "device-1")
        XCTAssertEqual(stored?["token"] as? String, "fcm-abc")
        XCTAssertEqual(stored?["appVersion"] as? String, "1.0.0")
    }

    func test_consumePendingWrite_returnsAndClearsPayload() {
        FirestoreDeviceTokenService.enqueuePendingWrite(
            deviceId: "device-2",
            token: "fcm-xyz",
            appVersion: "1.0.0"
        )

        let payload = FirestoreDeviceTokenService.consumePendingWrite()

        XCTAssertEqual(payload?.deviceId, "device-2")
        XCTAssertEqual(payload?.token, "fcm-xyz")
        XCTAssertNil(UserDefaults.standard.dictionary(forKey: pendingKey))
    }

    func test_consumePendingWrite_returnsNilWhenNothingQueued() {
        XCTAssertNil(FirestoreDeviceTokenService.consumePendingWrite())
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/FirestoreDeviceTokenServiceTests
```

Expected: build failure ("Cannot find 'FirestoreDeviceTokenService' in scope").

- [ ] **Step 3: Implement the service**

Create `Soulverse/Shared/Service/FirestoreDeviceTokenService.swift`:

```swift
//
//  FirestoreDeviceTokenService.swift
//  Soulverse
//
//  Lightweight FCM device-token persistence helper.
//  Per Phase 5 design: NOT a full service — just two statics.
//  Writes to users/{uid}/devices/{deviceId} per spec §4.5.
//

import Foundation
import FirebaseFirestore

enum FirestoreDeviceTokenService {

    private static let db = Firestore.firestore()
    private static let pendingKey = "soulverse.fcm.pendingTokenWrite"

    struct PendingWrite {
        let deviceId: String
        let token: String
        let appVersion: String
    }

    /// Persist the FCM token to Firestore. On failure, queues for retry.
    static func writeToken(
        uid: String,
        deviceId: String,
        token: String,
        appVersion: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let payload: [String: Any] = [
            "fcmToken":   token,
            "platform":   "ios",
            "appVersion": appVersion,
            "lastSeenAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(uid)
            .collection("devices").document(deviceId)
            .setData(payload, merge: true) { error in
                if let error = error {
                    print("[FCM] Token write failed, queuing for retry: \(error.localizedDescription)")
                    enqueuePendingWrite(deviceId: deviceId, token: token, appVersion: appVersion)
                }
                completion?(error)
            }
    }

    /// Persist a failed write into UserDefaults so the next launch can retry.
    static func enqueuePendingWrite(deviceId: String, token: String, appVersion: String) {
        UserDefaults.standard.set(
            [
                "deviceId":   deviceId,
                "token":      token,
                "appVersion": appVersion
            ],
            forKey: pendingKey
        )
    }

    /// Pop and return any pending write. Returns nil if queue is empty.
    @discardableResult
    static func consumePendingWrite() -> PendingWrite? {
        guard
            let stored = UserDefaults.standard.dictionary(forKey: pendingKey),
            let deviceId   = stored["deviceId"]   as? String,
            let token      = stored["token"]      as? String,
            let appVersion = stored["appVersion"] as? String
        else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: pendingKey)
        return PendingWrite(deviceId: deviceId, token: token, appVersion: appVersion)
    }

    /// Retry any queued write for the current user. Safe to call on every app launch.
    static func flushPendingWrites(uid: String) {
        guard let pending = consumePendingWrite() else { return }
        writeToken(
            uid: uid,
            deviceId: pending.deviceId,
            token: pending.token,
            appVersion: pending.appVersion
        )
    }
}
```

Add the new file to the `Soulverse` target in `Soulverse.xcodeproj` (and to `SoulverseTests` if not already covered by `@testable import`).

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/FirestoreDeviceTokenServiceTests
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Shared/Service/FirestoreDeviceTokenService.swift \
        SoulverseTests/Tests/Quest/FirestoreDeviceTokenServiceTests.swift \
        Soulverse.xcodeproj
git commit -m "feat(quest): add FirestoreDeviceTokenService with retry queue"
```

---

## Task 2: Uncomment Messaging setup and adopt MessagingDelegate

**Files:**
- Modify: `Soulverse/AppDelegate.swift`

Activate FCM at app launch. The delegate plumbing is the entry point — token receipt comes in Task 3.

- [ ] **Step 1: Add the FirebaseMessaging import and `Messaging.messaging().delegate = self`**

In `Soulverse/AppDelegate.swift`, add `import FirebaseMessaging` near the other Firebase imports. Inside `application(_:didFinishLaunchingWithOptions:)`, replace the existing block:

```swift
UNUserNotificationCenter.current().delegate = self

//UIApplication.shared.registerForRemoteNotifications()
```

with:

```swift
UNUserNotificationCenter.current().delegate = self
Messaging.messaging().delegate = self

// If permission was previously granted, register at launch so the APNs
// token comes back. registerForRemoteNotifications is idempotent.
UNUserNotificationCenter.current().getNotificationSettings { settings in
    guard settings.authorizationStatus == .authorized else { return }
    DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
    }
}
```

- [ ] **Step 2: Forward APNs token to Messaging**

In the existing `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`, append:

```swift
Messaging.messaging().apnsToken = deviceToken
```

The full replaced func body becomes:

```swift
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    #if DEBUG
    let deviceTokenString = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
    print("[FCM] APNs deviceToken:", deviceTokenString)
    #endif

    Messaging.messaging().apnsToken = deviceToken
}
```

- [ ] **Step 3: Add an empty MessagingDelegate stub so the file compiles**

Append to the end of `AppDelegate.swift`:

```swift
// MARK: - MessagingDelegate

import FirebaseMessaging

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        // Implementation in Task 3.
    }
}
```

> Note: Swift requires the `import FirebaseMessaging` to live at file scope. Move the `import` to the top of the file alongside other imports if not already there; the duplicate is shown above only for clarity of the diff.

- [ ] **Step 4: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/AppDelegate.swift
git commit -m "feat(fcm): activate Messaging delegate and forward APNs token"
```

---

## Task 3: Wire token receipt to Firestore device-token write

**Files:**
- Modify: `Soulverse/AppDelegate.swift`

Implement the `MessagingDelegate` callback. Use `UIDevice.current.identifierForVendor` as the deterministic per-install `deviceId`. This is the actual ~5-line helper called out in the spec.

- [ ] **Step 1: Write the failing intent**

We have no XCTest harness for AppDelegate token-receive (it's a system callback). We rely on the `FirestoreDeviceTokenService` tests already covering the persistence behaviour. The "test" here is a manual verification after Step 4.

- [ ] **Step 2: Implement the delegate callback**

Replace the placeholder `messaging(_:didReceiveRegistrationToken:)` body with:

```swift
extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        guard
            let token = fcmToken,
            let uid   = User.shared.userId,
            let deviceId = UIDevice.current.identifierForVendor?.uuidString
        else {
            print("[FCM] Skipping token write — missing token, uid, or vendor id")
            return
        }

        let appVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

        FirestoreDeviceTokenService.writeToken(
            uid: uid,
            deviceId: deviceId,
            token: token,
            appVersion: appVersion
        )
    }
}
```

- [ ] **Step 3: Flush pending writes on launch (after auth is hydrated)**

Inside `application(_:didFinishLaunchingWithOptions:)`, immediately after the `setTrackingAgent()` call, add:

```swift
if let uid = User.shared.userId {
    FirestoreDeviceTokenService.flushPendingWrites(uid: uid)
}
```

This handles the "I queued a write last session because I was offline" case.

- [ ] **Step 4: Build + manual smoke**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds. (Manual smoke deferred to Task 11.)

- [ ] **Step 5: Commit**

```bash
git add Soulverse/AppDelegate.swift
git commit -m "feat(fcm): persist FCM tokens to users/{uid}/devices/{deviceId} on receive"
```

---

## Task 4: Request notification permission at registration completion

**Files:**
- Modify: `Soulverse/Onboarding/Presenter/OnboardingCoordinator.swift`

Per spec §12 (revised Phase 5): permission is requested at the registration-success terminal, using the system iOS dialog directly — no custom soft pre-prompt.

The registration success terminal in this codebase is `OnboardingCoordinator.handleOnboardingCompletion()` (called after `submitOnboardingData` succeeds, or after the `OnboardingNamingViewController` step finishes).

> Engineer note: confirm that `handleOnboardingCompletion()` runs exactly once per registration. If returning users (`isNewUser == false` branch in `handleAuthenticationSuccess`) reach it without going through naming, the dialog still fires once — which is fine, because `requestAuthorization` is a no-op after the first call.

- [ ] **Step 1: Add the permission-request helper**

Add this private method at the bottom of the `OnboardingCoordinator` class (above the closing brace, below `handleOnboardingCompletion`):

```swift
// MARK: - Notifications

private func requestNotificationPermissionAfterRegistration() {
    UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound]
    ) { granted, error in
        if let error = error {
            print("[FCM] requestAuthorization error: \(error.localizedDescription)")
        }
        guard granted else {
            print("[FCM] User denied notification permission")
            return
        }
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
```

- [ ] **Step 2: Call it from the completion handler**

Modify `handleOnboardingCompletion()`:

```swift
private func handleOnboardingCompletion() {
    requestNotificationPermissionAfterRegistration()
    delegate?.onboardingCoordinatorDidComplete(self, userData: userData)
}
```

The order matters subtly: we kick off the permission dialog *before* the delegate routes the user to the home screen. The dialog overlays whatever screen is in front, so users see it on the main app, not on the onboarding flow. Either order is acceptable, but firing first ensures the system doesn't suppress the dialog if the onboarding nav controller is mid-dismiss.

- [ ] **Step 3: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 4: Manual verification (recorded)**

On a fresh-install simulator:
1. Walk through onboarding (Apple/Google or Dev sign-in → birthday → gender → naming → submit).
2. Confirm the iOS system "Allow Soulverse to send notifications?" alert appears immediately on landing on the home screen.
3. Tap **Allow**. Observe the `[FCM] APNs deviceToken: …` log (from Task 2's debug print).

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Onboarding/Presenter/OnboardingCoordinator.swift
git commit -m "feat(onboarding): request notification permission at registration completion"
```

---

## Task 5: Handle notification taps — route to Quest tab via `notificationKey`

**Files:**
- Modify: `Soulverse/Shared/Manager/AppCoordinator.swift`
- Modify: `Soulverse/AppDelegate.swift`

Plan 1's Cloud Function attaches a `notificationKey` data field on every Quest push (e.g., `"importance_check_in_first"`, `"MilestoneDay14"`). When the user taps the notification, route them to the Quest tab (index 4 of `MainViewController`).

- [ ] **Step 1: Add a Quest destination to `RoutingDestination`**

In `Soulverse/Shared/Manager/AppCoordinator.swift`, extend the enum:

```swift
enum RoutingDestination: String {
    case TOC = "toc"
    case AudioPlayer = "track"
    case SummaryText = "article"
    case Profile = "profile"
    case MembershipPurchase = "purchase"
    case ExternalLink = "external_link"
    case Quest = "quest"
    case None

    var hasData: Bool {
        switch self {
        case .TOC, .AudioPlayer, .SummaryText, .ExternalLink:
            return true
        default:
            return false
        }
    }
}
```

- [ ] **Step 2: Extend `inAppRouting` to handle Quest pushes**

Modify `AppCoordinator.inAppRouting` to detect the FCM payload pattern (Plan 1 puts the rule key in a top-level `notificationKey` data field, not the `payload` field used by legacy in-app pushes). Add:

```swift
static func inAppRouting(_ params: [String: Any]?) {
    guard let params = params else { return }

    // Quest pushes from Cloud Functions carry `notificationKey`.
    // Treat any present value as a Quest tab deep-link.
    if let notificationKey = params["notificationKey"] as? String {
        print("[FCM] Routing Quest notification: \(notificationKey)")
        routeToQuestTab()
        return
    }

    guard let currentVC = UIViewController.getLastPresentedViewController() else { return }

    if let payload = params["payload"] as? String {
        let dest = RoutingDestination(rawValue: payload) ?? .None
        if dest.hasData {
            if let data = params["data"] as? String {
                switch dest {
                case .ExternalLink:
                    AppCoordinator.openWebBrowser(to: data)
                default:
                    break
                }
            }
        }
    }
}

private static func routeToQuestTab() {
    DispatchQueue.main.async {
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = scene.windows.first(where: { $0.isKeyWindow }),
            let tabBar = window.rootViewController as? UITabBarController
        else { return }

        // Quest tab is index 4 per MainViewController layout.
        tabBar.selectedIndex = 4
    }
}
```

> Note: the existing legacy `currentVC` guard remains for the older `payload` paths, but the Quest path returns early before that guard so it always succeeds from background.

- [ ] **Step 3: Confirm `AppDelegate` already routes through `inAppRouting`**

The existing `userNotificationCenter(_:didReceive:withCompletionHandler:)` already calls `AppCoordinator.inAppRouting(userInfo as? [String: Any])`. No change needed in `AppDelegate.swift` — verify the existing call site is intact.

- [ ] **Step 4: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Shared/Manager/AppCoordinator.swift
git commit -m "feat(fcm): deep-link Quest push notifications to the Quest tab"
```

---

## Task 6: Foreground push presentation — show banner for Quest pushes

**Files:**
- Modify: `Soulverse/AppDelegate.swift`

Currently the `willPresent` callback shows `[.banner]` for all foregrounded pushes. Quest pushes should also play a sound so the user notices them — but only if the user has sound enabled. Keep behaviour consistent for non-Quest pushes.

- [ ] **Step 1: Update the `willPresent` handler**

Replace the existing implementation:

```swift
func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
) {
    let userInfo = notification.request.content.userInfo
    let isQuestPush = userInfo["notificationKey"] is String

    if isQuestPush {
        completionHandler([.banner, .sound])
    } else if #available(iOS 14.0, *) {
        completionHandler([.banner])
    } else {
        completionHandler([])
    }
}
```

- [ ] **Step 2: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/AppDelegate.swift
git commit -m "feat(fcm): play sound for foregrounded Quest push notifications"
```

---

## Task 7: Add Localizable strings for the notifications-off banner

**Files:**
- Modify: `Soulverse/en.lproj/Localizable.strings`

Per spec §9, all user-facing strings go through `NSLocalizedString`. en-only for MVP.

- [ ] **Step 1: Append the new keys**

Append to `Soulverse/en.lproj/Localizable.strings`:

```
/* MARK: - Quest notifications-off banner */
"quest_notifications_off_banner_title" = "Notifications off";
"quest_notifications_off_banner_body"  = "Turn on notifications in Settings to get milestone reminders.";
"quest_notifications_off_banner_cta"   = "Open Settings";
"quest_notifications_off_banner_dismiss" = "Dismiss";
```

- [ ] **Step 2: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 3: Commit**

```bash
git add Soulverse/en.lproj/Localizable.strings
git commit -m "i18n(quest): add notifications-off banner copy (en)"
```

---

## Task 8: Build the `QuestNotificationsOffBanner` view + tests

**Files:**
- Create: `Soulverse/Features/Quest/Views/QuestNotificationsOffBanner.swift`
- Create: `SoulverseTests/Tests/Quest/QuestNotificationsOffBannerTests.swift`

A self-contained banner view with a "Dismiss" close button and an "Open Settings" CTA.

- [ ] **Step 1: Write the failing test**

Create `SoulverseTests/Tests/Quest/QuestNotificationsOffBannerTests.swift`:

```swift
import XCTest
@testable import Soulverse

final class QuestNotificationsOffBannerTests: XCTestCase {

    func test_init_setsLocalizedTitleAndBody() {
        let banner = QuestNotificationsOffBanner()

        XCTAssertEqual(
            banner.titleLabel.text,
            NSLocalizedString("quest_notifications_off_banner_title", comment: "")
        )
        XCTAssertEqual(
            banner.bodyLabel.text,
            NSLocalizedString("quest_notifications_off_banner_body", comment: "")
        )
    }

    func test_dismissTap_invokesDismissCallback() {
        let banner = QuestNotificationsOffBanner()
        let exp = expectation(description: "dismiss callback fires")
        banner.onDismiss = { exp.fulfill() }

        banner.dismissButton.sendActions(for: .touchUpInside)

        wait(for: [exp], timeout: 1.0)
    }

    func test_settingsTap_invokesSettingsCallback() {
        let banner = QuestNotificationsOffBanner()
        let exp = expectation(description: "settings callback fires")
        banner.onOpenSettings = { exp.fulfill() }

        banner.settingsButton.sendActions(for: .touchUpInside)

        wait(for: [exp], timeout: 1.0)
    }
}
```

- [ ] **Step 2: Run the test and verify it fails**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/QuestNotificationsOffBannerTests
```

Expected: build failure ("Cannot find 'QuestNotificationsOffBanner' in scope").

- [ ] **Step 3: Implement the banner**

Create `Soulverse/Features/Quest/Views/QuestNotificationsOffBanner.swift`:

```swift
//
//  QuestNotificationsOffBanner.swift
//  Soulverse
//
//  Persistent in-app reminder shown on the Quest tab when the user has
//  denied notification permission. Dismissable but not permanent.
//

import UIKit
import SnapKit

final class QuestNotificationsOffBanner: UIView {

    private enum Layout {
        static let containerInset: CGFloat = 16
        static let stackSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let dismissSize: CGFloat = 24
        static let ctaHeight: CGFloat = 32
    }

    let titleLabel = UILabel()
    let bodyLabel = UILabel()
    let dismissButton = UIButton(type: .system)
    let settingsButton = UIButton(type: .system)

    var onDismiss: (() -> Void)?
    var onOpenSettings: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupActions()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not supported") }

    private func setupView() {
        backgroundColor = .themeBackgroundSecondary
        layer.cornerRadius = Layout.cornerRadius
        ViewComponentConstants.applyGlassCardEffect(to: self)

        titleLabel.text = NSLocalizedString("quest_notifications_off_banner_title", comment: "")
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .themeTextPrimary

        bodyLabel.text = NSLocalizedString("quest_notifications_off_banner_body", comment: "")
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .themeTextSecondary
        bodyLabel.numberOfLines = 0

        dismissButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismissButton.tintColor = .themeIconMuted

        settingsButton.setTitle(
            NSLocalizedString("quest_notifications_off_banner_cta", comment: ""),
            for: .normal
        )
        settingsButton.setTitleColor(.themeAccent, for: .normal)
        settingsButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)

        addSubview(titleLabel)
        addSubview(bodyLabel)
        addSubview(dismissButton)
        addSubview(settingsButton)

        dismissButton.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.containerInset)
            make.right.equalToSuperview().inset(Layout.containerInset)
            make.size.equalTo(Layout.dismissSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.containerInset)
            make.left.equalToSuperview().inset(Layout.containerInset)
            make.right.lessThanOrEqualTo(dismissButton.snp.left).offset(-Layout.stackSpacing)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.stackSpacing)
            make.left.right.equalToSuperview().inset(Layout.containerInset)
        }
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(bodyLabel.snp.bottom).offset(Layout.stackSpacing)
            make.left.equalToSuperview().inset(Layout.containerInset)
            make.bottom.equalToSuperview().inset(Layout.containerInset)
            make.height.equalTo(Layout.ctaHeight)
        }
    }

    private func setupActions() {
        dismissButton.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        settingsButton.addTarget(self, action: #selector(handleSettings), for: .touchUpInside)
    }

    @objc private func handleDismiss() { onDismiss?() }
    @objc private func handleSettings() { onOpenSettings?() }
}
```

> If any theme tokens (`.themeIconMuted`, `.themeAccent`, etc.) are not yet defined in `Soulverse/Shared/Theme/`, add them now per spec §10.1 — do not fall back to hardcoded values.

- [ ] **Step 4: Run the test and verify it passes**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  test -only-testing:SoulverseTests/QuestNotificationsOffBannerTests
```

Expected: 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestNotificationsOffBanner.swift \
        SoulverseTests/Tests/Quest/QuestNotificationsOffBannerTests.swift \
        Soulverse.xcodeproj
git commit -m "feat(quest): add dismissable notifications-off banner view"
```

---

## Task 9: Track banner-dismissed state in `QuestViewModel`

**Files:**
- Modify: `Soulverse/Features/Quest/ViewModels/QuestViewModel.swift`

The banner is dismissable but not permanent. We persist dismissal in `UserDefaults` keyed per-session — the banner returns next launch. The view model exposes `shouldShowNotificationsOffBanner`.

- [ ] **Step 1: Add the property + the dismiss method**

Add to `QuestViewModel`:

```swift
// MARK: - Notifications-off banner

private let bannerDismissedKey = "soulverse.quest.notificationsOffBanner.dismissedThisSession"

/// `true` when push permission is not authorized AND user has not dismissed this session.
var shouldShowNotificationsOffBanner: Bool {
    get {
        guard !UserDefaults.standard.bool(forKey: bannerDismissedKey) else { return false }
        return notificationAuthorizationStatus != .authorized
    }
}

/// The latest known authorization status. Set by the presenter at viewWillAppear.
var notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined

func dismissNotificationsOffBanner() {
    UserDefaults.standard.set(true, forKey: bannerDismissedKey)
}

/// Reset the dismissed flag — call once per app launch from `QuestViewPresenter`.
static func resetBannerDismissalForNewSession() {
    UserDefaults.standard.removeObject(forKey: "soulverse.quest.notificationsOffBanner.dismissedThisSession")
}
```

> The "session" boundary is intentional: dismissing the banner suppresses it until the next cold launch. The user gets one nudge per session; the design avoids a permanent banner that becomes wallpaper.

- [ ] **Step 2: Reset the dismissal flag at app launch**

In `Soulverse/AppDelegate.swift` `application(_:didFinishLaunchingWithOptions:)`, near `setTrackingAgent()`, add:

```swift
QuestViewModel.resetBannerDismissalForNewSession()
```

- [ ] **Step 3: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 4: (no new test — `shouldShowNotificationsOffBanner` is exercised in Task 10)**

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/ViewModels/QuestViewModel.swift Soulverse/AppDelegate.swift
git commit -m "feat(quest): track notifications-off banner dismissal per session"
```

---

## Task 10: Render the banner on the Quest tab

**Files:**
- Modify: `Soulverse/Features/Quest/Views/QuestViewController.swift`

Show the banner at the top of the Quest scroll content when `viewModel.shouldShowNotificationsOffBanner` is true. Refresh on `viewWillAppear` so coming back from Settings (where the user may have toggled permission on) hides it.

- [ ] **Step 1: Add the banner subview**

In `QuestViewController`, add an instance property:

```swift
private let notificationsOffBanner = QuestNotificationsOffBanner()
```

In `setupView()` (or wherever subviews are added at the top of the scrollable content stack), insert:

```swift
notificationsOffBanner.isHidden = true
contentStackView.addArrangedSubview(notificationsOffBanner) // or equivalent
notificationsOffBanner.snp.makeConstraints { make in
    make.left.right.equalToSuperview().inset(QuestLayout.horizontalInset)
}
notificationsOffBanner.onDismiss = { [weak self] in
    self?.viewModel.dismissNotificationsOffBanner()
    self?.refreshNotificationsOffBanner()
}
notificationsOffBanner.onOpenSettings = {
    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
    UIApplication.shared.open(url)
}
```

> If the Quest layout doesn't yet have `contentStackView` (Plans 2-5 build it), add the banner directly to `view` with appropriate top constraint relative to the existing layout. Match the placement to "above the ProgressSection" per spec §5.

- [ ] **Step 2: Refresh on viewWillAppear**

Add to `QuestViewController`:

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshNotificationsOffBanner()
}

private func refreshNotificationsOffBanner() {
    UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
        DispatchQueue.main.async {
            guard let self = self else { return }
            self.viewModel.notificationAuthorizationStatus = settings.authorizationStatus
            self.notificationsOffBanner.isHidden = !self.viewModel.shouldShowNotificationsOffBanner
        }
    }
}
```

> Per `Soulverse/CLAUDE.md`: `isHidden = true` does NOT deactivate constraints. Since this banner is the topmost subview of the Quest content stack, its hidden state collapses to zero height in a `UIStackView` automatically. If you placed it outside a stack, also call `notificationsOffBanner.snp.remakeConstraints { _ in }` while hidden, or wrap it in a stack-view container.

- [ ] **Step 3: Build**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse" \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=26.0' \
  build -quiet
```

Expected: build succeeds.

- [ ] **Step 4: Manual verification**

1. Run on simulator. In Settings → Soulverse → Notifications, toggle **Allow Notifications** off.
2. Reopen the app. Navigate to the Quest tab.
3. Banner is visible.
4. Tap **Open Settings** → iOS Settings opens. Toggle notifications back on; return to app. Banner is gone.
5. Toggle off again. Reopen app. Banner returns. Tap **Dismiss**. Banner hides for the rest of the session.
6. Background and re-foreground the app (without killing it): banner stays hidden.
7. Cold-launch the app: banner returns.

- [ ] **Step 5: Commit**

```bash
git add Soulverse/Features/Quest/Views/QuestViewController.swift
git commit -m "feat(quest): show notifications-off banner on Quest tab when denied"
```

---

## Task 11: End-to-end smoke test on a real device

**Files:**
- (No code change — verification gate)

Tasks 1–10 can ship and pass tests against the simulator, but FCM push delivery cannot be exercised on the simulator (APNs is real-device only). This task is the gate that proves the full pipeline.

- [ ] **Step 1: Pre-launch checklist**

Confirm Pre-launch items 1, 2, 3, 4 from the top of this plan are complete.

- [ ] **Step 2: Install on a real device**

```bash
xcodebuild -workspace Soulverse.xcworkspace \
  -scheme "Soulverse Dev" \
  -configuration Debug \
  -destination 'generic/platform=iOS' \
  build
```

Sideload to a physical iPhone via Xcode (Window → Devices and Simulators).

- [ ] **Step 3: Walk through onboarding on the device**

1. Fresh-install the build on the device.
2. Sign in via Apple/Google/Dev.
3. Complete birthday/gender/naming.
4. Confirm system "Allow Soulverse to send notifications?" dialog appears.
5. Tap **Allow**.
6. In Xcode console, observe `[FCM] APNs deviceToken: …` and verify a Firestore write at `users/{your-uid}/devices/{vendorId}` with fields `fcmToken`, `platform: "ios"`, `appVersion`, `lastSeenAt`.

- [ ] **Step 4: Trigger a push from the Cloud Function**

Two options, in order of preference:

**Option A (preferred — exercises Plan 1 end-to-end):**
1. In Firestore (production or dev project), set the device's quest_state `notificationHour` to `currentUTCHour` and `pendingSurveys` to `["importance_check_in"]`.
2. Wait up to 60 minutes for `questNotificationCron` to fire (or invoke it manually via `firebase functions:shell`).
3. Confirm the push arrives on device.

**Option B (sanity check — bypasses the schedule engine):**
1. Use the FCM Composer in Firebase Console → Cloud Messaging → New campaign → Notifications.
2. Send to the device's FCM token directly with a custom data payload `notificationKey=importance_check_in_first`.
3. Confirm the push arrives.

- [ ] **Step 5: Verify deep-link routing**

1. Background the app (don't kill it).
2. Receive the push (steps above).
3. Tap the push.
4. App foregrounds and the Quest tab is selected.
5. Console logs `[FCM] Routing Quest notification: importance_check_in_first`.

- [ ] **Step 6: Verify foreground push behaviour**

1. With the app already in foreground, send another test push.
2. Verify the system banner appears with sound and the app stays on its current screen.

- [ ] **Step 7: Verify denied-permission path**

1. Settings → Soulverse → Notifications → toggle off.
2. Open the app, navigate to the Quest tab.
3. Banner appears with the localized title and body.
4. Tap **Open Settings**, toggle on, return — banner vanishes.

- [ ] **Step 8: Final commit (smoke-test marker)**

No code change, but record the smoke run:

```bash
git tag -a quest-fcm-client-v1 -m "Plan 6 complete: FCM client integration verified on device"
git push origin quest-fcm-client-v1
```

---

## Cross-plan dependencies

- **Plan 1 (Cloud Functions)** must have shipped, including `questNotificationCron`'s FCM dispatch and the `notificationKey` data field on outgoing pushes. Task 5 routing and Task 11 smoke test depend on it.
- **Plans 2–5** build the actual Quest tab UI. Task 10's banner placement assumes the Quest content layout — if Plan 2 has not yet defined `contentStackView`, the banner is added directly to `view` with a top constraint matching the eventual ProgressSection's anchor.
- **Plan 7 (final QA + theme audit)** picks up on Task 8's banner styling — verify the `.themeBackgroundSecondary` / `.themeAccent` / `.themeIconMuted` tokens exist by then.

---

**End of plan 6.**
