# Soulverse TODO

## Backlog

### 8. Redesign QuestRadarChartView with colored axis dots & center progress dot
**Priority**: P1
**Complexity**: M
**Status**: Pending

Redesign the radar chart to show uniquely colored dots on each of the 8 axes and a center dot for overall progress. Replace the current blue-fill polygon with a clean web grid + colored dots style.

**Key Changes**:
- Each axis vertex gets a colored dot matching its topic color (reuse `Topic.mainColor`)
- Selected/active topic dot shown as hollow ring (border only)
- Center progress dot uses selected topic's color
- Update dimensions to 8 wellness domains: Physical, Emotional, Social, Intellectual, Environment, Occupational, Spiritual, Financial
- Data set becomes transparent (no fill, no line) — only web grid + dots visible

**Files to Modify**:
- `QuestViewModel.swift` — Add `color: UIColor` to `RadarChartMetric`, add `selectedIndex` and `progressValue` to `QuestRadarData`
- `QuestRadarChartView.swift` — Overlay colored dot UIViews at axis vertices via trigonometry, add center progress dot, make data set transparent
- `QuestViewPresenter.swift` — Update mock data with 8 wellness topics and their colors from `Topic`
- `Localizable.strings` (en + zh-TW) — Localization strings now use `topic_*` keys

**Acceptance Criteria**:
- Colored solid dots at each axis vertex
- Active topic dot is hollow ring
- Center dot uses active topic color
- Labels match 8 wellness domains
- Animation preserved
- Theme-aware colors

---

### 3. Implement text-color focus game
**Priority**: P2
**Complexity**: L
**Status**: Pending
**Blocked by**: PRD to be provided

A new cognitive focus game tool. Awaiting detailed PRD for requirements and specifications.

---

### 7. Create emotion-score mapping and weekly mood view
**Priority**: P1
**Complexity**: XL
**Status**: Pending

Implement emotion-to-score mapping function and create a weekly mood score visualization view.

**Technical Considerations**:
- Design emotion-score mapping algorithm
- Create data model for mood tracking over time
- Implement weekly aggregation logic
- Design visualization (chart/graph using custom drawing or library)
- Add API integration for persisting mood data
- Consider using Core Data for local caching
- Add analytics for mood tracking engagement

---

### 16. Refine emo pet affirmation interaction
**Priority**: P2
**Complexity**: M
**Status**: Pending

Make the emo pet interaction feel more human and natural. Improve implementation clarity and interaction quality.

**Goals**:
- Make the emo pet respond more like a companion, not a static quote machine
- Improve bubble appearance and positioning
- Refine TTS delivery (pacing, tone)
- Expand and improve affirmation quote content for both locales

**Potential Improvements**:
- Contextual responses based on user's recent mood check-in data
- Varied response patterns (not always the same bubble format)
- Natural typing/appear animation for bubble text
- Adjust TTS speech rate and voice selection for warmth
- Update `AffirmationQuotes.json` with more empathetic, conversational quotes
- Consider adding pet reaction animations (happy, encouraging, etc.)

**Related Files**:
- `Soulverse/Resources/AffirmationQuotes.json`
- `Soulverse/Features/InnerCosmo/ViewModels/AffirmationQuote.swift`
- `Soulverse/Features/InnerCosmo/Views/Components/AffirmationBubbleView.swift`
- `Soulverse/Shared/Service/SpeechService.swift`
- `CentralPlanetView.swift`
- `InnerCosmoDailyView.swift`

---

### 19. Remove the random feature in Canvas
**Priority**: P2
**Complexity**: S
**Status**: Pending

Remove the "random" feature from the Canvas section of the app. This feature is no longer needed and should be cleaned up.

**Tasks**:
- Identify all random-feature-related code in Canvas
- Remove UI elements (buttons, views) related to random feature
- Remove associated logic/models
- Ensure no orphaned references or dead code remain
- Verify Canvas still builds and functions correctly after removal

---

### 15. Simplify MoodCheckInData by removing isXXXComplete properties
**Priority**: P3
**Complexity**: S
**Status**: Pending

Remove the `isXXXComplete` computed properties from `MoodCheckInData.swift` as they are no longer needed.

**Properties to remove**:
- `isNamingComplete`
- `isShapingComplete` (already returns `true` - step is optional)
- `isAttributingComplete`
- `isEvaluatingComplete`
- `isActingComplete`

**Rationale**:
- These validation properties are not used for flow control
- The coordinator handles navigation directly
- Steps like Shaping are now optional, making these checks misleading

**Files to modify**:
- `Soulverse/MoodCheckIn/Models/MoodCheckInData.swift`

---

## In Progress

### 21. Replace LoadingView spinner with Lottie bounce animation
**Priority**: P1
**Complexity**: S
**Status**: Completed
**Branch**: feat/lottie-loading-view
**Worktree**: ../soulverse-feature/
**Created**: 2026-02-28
**Completed**: 2026-02-28
**PR**: #41

Swap the UIActivityIndicatorView inside LoadingView.swift with a LottieAnimationView using stage1_bounce_lottie.json. Same public API, zero caller changes.

---

### 20. Add locked state for Tools
**Priority**: P1
**Complexity**: S
**Status**: Completed
**Branch**: feat/tool-locked-state
**Worktree**: ../soulverse-feature/
**Created**: 2026-02-28
**Completed**: 2026-02-28
**PR**: #39

Add a locked state to tool cells with blur overlay + centered lock icon. Lock state is driven by `ToolLockState` enum with `LockReason` (.notSubscribed, .notImplemented). Tapping locked cells triggers reason-specific behavior instead of the tool action.

**Files to Modify**:
- `Soulverse/Features/Tools/Models/ToolsModel.swift` — Add `ToolLockState`, `LockReason` enums
- `Soulverse/Features/Tools/ViewModels/ToolsCellViewModel.swift` — Add `lockState` property
- `Soulverse/Features/Tools/Views/ToolsCollectionViewCell.swift` — Add blur overlay + lock icon
- `Soulverse/Features/Tools/Presenter/ToolsViewPresenter.swift` — Set lock states on mock data
- `Soulverse/Features/Tools/Views/ToolsViewController.swift` — Route locked taps
- `Localizable.strings` (en + zh-TW) — Lock-related strings

---

## Done

### 9. Integrate login/signin function
**Priority**: P0 (Critical)
**Complexity**: M (4-8 hours)
**Status**: Completed

Integrated Firebase Auth + Firestore as the sole backend for user management, replacing the defunct REST API.

**Implementation Summary**:
- Created `FirestoreUserService.swift` — Firestore CRUD for user profiles and onboarding data
- Wired Apple/Google Sign-In through Firebase Auth credential relay
- Added `isNewUser` flag to `AuthResult` for new vs returning user routing
- Updated `OnboardingCoordinator` — new users go through onboarding, returning users skip to main
- Added Firebase sign-out to `User.logout()`
- FCM token updates now go through Firestore
- Renamed `SummitUserModel` → `UserModel` with Firestore-aligned fields
- Stubbed legacy `UserService` REST methods (kept compiling, no longer functional)
- Added Google OAuth redirect URL scheme to `Info.plist`

**Files Created**:
- `Soulverse/Shared/Service/FirestoreUserService.swift`

**Files Modified**:
- `Info.plist` — URL schemes
- `AppleUserAuthService.swift` — Firebase Auth relay
- `GoogleUserAuthService.swift` — Firebase Auth relay
- `AuthService.swift` — `AuthResult.AuthSuccess(isNewUser:)`
- `OnboardingCoordinator.swift` — Routing + Firestore submission
- `User.swift` — Firebase sign-out + Firestore FCM
- `UserModel.swift` (renamed from `SummitUserModel.swift`)
- `UserService.swift` — Stubbed legacy methods

---

### 2. Make emo pet image tappable in InnerCosmos
**Priority**: P2
**Complexity**: S
**Status**: Completed

Added tap gesture to emo pet image in InnerCosmos. When tapped, displays an affirmation quote in a speech bubble with TTS.

**Implementation Summary**:
- Added `CentralPlanetViewDelegate` protocol for tap events
- Added tap gesture to `CentralPlanetView` with bounce animation
- Created `AffirmationQuote` model loading from JSON (`AffirmationQuotes.json`)
- Created `AffirmationBubbleView` speech bubble UI (positioned right of pet)
- Created `SpeechService` for TTS (reusable across app)
- Integrated TTS - bubble dismisses after speech finishes + 0.2s
- Quotes localized in both en/zh-TW (10 quotes)

**Files Created**:
- `Soulverse/Resources/AffirmationQuotes.json`
- `Soulverse/Features/InnerCosmo/ViewModels/AffirmationQuote.swift`
- `Soulverse/Features/InnerCosmo/Views/Components/AffirmationBubbleView.swift`
- `Soulverse/Shared/Service/SpeechService.swift`

**Files Modified**:
- `CentralPlanetView.swift` - Added tap gesture + delegate
- `InnerCosmoDailyView.swift` - Handles tap, shows bubble, integrates TTS

---

### 10. Add progress bar to mood check-in flow
**Priority**: P2
**Complexity**: S (< 4 hours)
**Status**: Completed

Add a progress bar component to the mood check-in flow to show users their progress through the steps.

**Implementation Summary**:
- All 6 regular steps have `SoulverseProgressBar(totalSteps: 6)` with correct step progression
- PetView excluded (one-time intro screen, not a regular step)
- Uses theme-aware colors (`.themeProgressBarActive`, `.themeProgressBarInactive`)
- Consistent placement centered in navigation bar area
- Fixed width constraint using `ViewComponentConstants.onboardingProgressViewWidth`

**Files with Progress Bar**:
- `MoodCheckInSensingViewController.swift` - Step 1
- `MoodCheckInNamingViewController.swift` - Step 2
- `MoodCheckInShapingViewController.swift` - Step 3
- `MoodCheckInAttributingViewController.swift` - Step 4
- `MoodCheckInEvaluatingViewController.swift` - Step 5
- `MoodCheckInActingViewController.swift` - Step 6

---

### 11. Create shared MoodCheckIn layout constants
**Priority**: P2
**Complexity**: S
**Status**: Completed

Created `Constants+MoodCheckIn.swift` to centralize layout constants for all MoodCheckIn ViewControllers.

**Implementation Summary**:
- Created `MoodCheckInLayout` enum with shared constants
- Migrated all 6 MoodCheckIn ViewControllers to use shared constants
- Removed duplicate `private enum Layout` from each ViewController

**Constants Defined**:
- `totalSteps: 6`
- `navigationTopOffset: 16`
- `navigationLeftOffset: 16`
- `horizontalPadding: 40`
- `sectionSpacing: 24`
- `titleToSubtitleSpacing: 12`
- `titleTopOffset: 80`
- `bottomPadding: 40`
- `textFieldHeight: 120`
- `colorSliderHeight: 28`
- `intensityCirclesHeight: 60`

**Files Created**:
- `Soulverse/MoodCheckIn/Constants+MoodCheckIn.swift`

**Files Modified**:
- All 6 MoodCheckIn ViewControllers

---

### 18. Fix onboarding back button size to match MoodCheckIn
**Priority**: P1
**Complexity**: S
**Status**: Completed

Fixed onboarding back buttons using wrong `UIButton()` (custom type) instead of `UIButton(type: .system)` with iOS 26 image handling, causing incorrect button sizing.

**Implementation Summary**:
- Changed all 5 onboarding back buttons from `UIButton()` to `UIButton(type: .system)`
- Added iOS 26 availability check: `naviconBack` with `.alwaysOriginal` + `contentMode = .center` + `clipsToBounds = false`
- Pre-iOS 26 fallback: `chevron.left` SF Symbol with `.themeTextPrimary` tint
- Preserved existing `accessibilityLabel`

**Files Modified**:
- `OnboardingSignInViewController.swift`
- `OnboardingNamingViewController.swift`
- `OnboardingTopicViewController.swift`
- `OnboardingGenderViewController.swift`
- `OnboardingBirthdayViewController.swift`

**PR**: #25

---

### 12. Fix iOS 26 naviconBack button rendering
**Priority**: P1
**Complexity**: S
**Status**: Completed

Fixed the back button image rendering for iOS 26 Liquid Glass style in MoodCheckIn flow.

**Implementation Summary**:
- Used `.withRenderingMode(.alwaysOriginal)` to preserve original image colors
- Set `imageView?.contentMode = .center` to display at natural size
- Set `clipsToBounds = false` on both button and imageView to allow shadow overflow
- Applied tintColor only for pre-iOS 26 fallback

**Files Modified**:
- `MoodCheckInSensingViewController.swift`
- `MoodCheckInNamingViewController.swift`
- `MoodCheckInShapingViewController.swift`
- `MoodCheckInAttributingViewController.swift`
- `MoodCheckInEvaluatingViewController.swift`
- `MoodCheckInActingViewController.swift`

---

### 6. Modify moodCheckInAttributing page layout
**Priority**: P2
**Complexity**: M
**Status**: Completed

Created reusable `SoulverseTopicList` component and unified naming from "life area" to "topic".

**Implementation Summary**:
- Created `SoulverseTopicList.swift` - Reusable grid component with `targetSelectedCount` for flexible selection modes
- Updated `MoodCheckInAttributingViewController` to use `SoulverseTopicList` instead of `SoulverseTagsView`
- Updated `OnboardingTopicViewController` to use `SoulverseTopicList` (code reuse)
- Renamed `lifeArea` → `selectedTopic` in `MoodCheckInData`
- Updated delegate method `didSelectLifeArea` → `didSelectTopic` in coordinator
- Deleted `LifeAreaOption.swift` (replaced by shared `Topic` model)

**Files Created**:
- `Soulverse/Shared/ViewComponent/SoulverseTopicList.swift`

**Files Modified**:
- `OnboardingTopicViewController.swift` - Uses SoulverseTopicList
- `MoodCheckInAttributingViewController.swift` - Uses SoulverseTopicList + Topic
- `MoodCheckInCoordinator.swift` - Updated delegate protocol
- `MoodCheckInData.swift` - lifeArea → selectedTopic
- `MoodCheckInAPIService.swift` - API param life_area → topic

**Files Deleted**:
- `LifeAreaOption.swift`

---

### 1. Make topics as reusable model object
**Priority**: P1
**Complexity**: M
**Status**: Completed

Created a reusable `Topic` enum in `Shared/Models/Topic.swift` with:
- 8 wellness domains (Physical, Emotional, Social, Intellectual, Spiritual, Occupational, Environment, Financial)
- `localizedTitle` - Using `topic_*` localization keys
- `iconImage: UIImage` - Returns SF Symbol images directly
- `mainColor: UIColor` - Brand colors for each topic

**Files Modified**:
- Created `Soulverse/Shared/Models/Topic.swift`
- Updated `OnboardingTopicViewController.swift` - Removed inline enum
- Updated `TopicCardView.swift` - Uses `Topic`, `mainColor`, `iconImage`
- Updated `OnboardingUserData.swift` - Type changed to `Topic?`
- Updated `OnboardingCoordinator.swift` - Updated delegate signature
- Updated `en.lproj/Localizable.strings` - Renamed keys to `topic_*`
- Updated `zh-TW.lproj/Localizable.strings` - Renamed keys to `topic_*`

---

### 13. Redesign emotion data structure with uni-key approach
**Priority**: P1
**Complexity**: M
**Status**: Completed

Redesigned the emotion data structure in mood check-in flow to use a uni-key approach based on Plutchik's Wheel of Emotions. The key insight is that intensity is encoded IN the emotion name (e.g., Joy+low = Serenity), not stored separately.

**Implementation Summary**:
- Unified 52 emotions into single `RecordedEmotion` enum (24 intensity-based + 28 combined)
- Changed from tuple array `[(EmotionType, intensity)]` to single `RecordedEmotion`
- API now sends single `emotion` key (e.g., "serenity", "pride") instead of array
- Added `sourceEmotions` property for displaying "Joy + Anger = Pride" format
- Merged `EmotionType.intensityLabels` to use same localization keys (single source of truth)
- Cleaned up duplicate localization keys

**Files Created/Deleted**:
- Deleted `EmotionCombination.swift` (merged into RecordedEmotion)

**Files Modified**:
- `RecordedEmotion.swift` - Added `sourceEmotions`, `isCombinedEmotion` properties
- `MoodCheckInData.swift` - `emotions` → `recordedEmotion`
- `MoodCheckInNamingViewController.swift` - ViewState uses `resolvedEmotion`
- `MoodCheckInShapingViewController.swift` - Uses `RecordedEmotion`
- `ColorEmotionSummaryView.swift` - Displays combined emotion format
- `MoodCheckInActingViewController.swift` - Displays `recordedEmotion.displayName`
- `MoodCheckInCoordinator.swift` - Updated delegate protocols
- `MoodCheckInAPIService.swift` - Uni-key API format
- `EmotionType.swift` - Merged intensity labels to use direct emotion keys
- `en.lproj/Localizable.strings` - Added 44 new keys, removed 52 duplicates
- `zh-TW.lproj/Localizable.strings` - Added 44 new keys, removed 52 duplicates

**Note**: User must manually remove `EmotionCombination.swift` reference from Xcode project.

---

### 17. Add in-app account deletion
**Priority**: P1
**Complexity**: M (4-8 hours)
**Status**: Completed

Apple requires apps with account creation to offer account deletion (App Store Review Guideline 5.1.1). Implemented full account deletion flow.

**Requirements**:
1. Add "Delete Account" button in settings/profile
2. Show confirmation dialog before deletion
3. On confirm, delete in this order:
   - Firestore `users/{uid}` document (and any subcollections)
   - Firebase Auth account (`Auth.auth().currentUser?.delete()`)
   - Clear local `UserDefaults` via `User.shared.resetAllUserData()`
4. After deletion, route user back to onboarding landing screen
5. User should be able to sign up again as a completely fresh new user

**Files to Create/Modify**:
- Settings/Profile view — add delete button
- `FirestoreUserService.swift` — add `deleteUser(uid:)` method
- `User.swift` — add `deleteAccount()` orchestrating the full flow
- `SceneDelegate.swift` — handle routing back to onboarding after deletion

---

### 4. Implement half-screen modal for state-of-change questionnaire
**Priority**: P1
**Complexity**: M
**Status**: Completed

Created half-screen modal view using `SoulverseActionModal` for state-of-change questionnaire.

---

### 5. Implement horizontal scroll view for user-created pictures
**Priority**: P2
**Complexity**: M
**Status**: Completed

Added horizontal scroll view in InnerCosmos page to display pictures that the user has previously created.

---

### 14. Refine emotion display in Naming → Shaping flow
**Priority**: P2
**Complexity**: S
**Status**: Completed

Adjusted how emotions are displayed across MoodCheckIn Naming and Shaping steps.

**Requirements**:
1. **MoodCheckInNamingViewController.swift**:
   - Single emotion selected → Show intensity slider
   - Two primary emotions selected → Show combined formula text: "Joy + Trust = Love"
   - Use the `combinedEmotionLabel` that already exists

2. **MoodCheckInShapingViewController.swift / ColorEmotionSummaryView**:
   - Show only the resolved `recordedEmotion` name directly (e.g., "Love")
   - No formula repeat since it was already shown in Naming step

**Implementation Summary**:
- Added constraints for `combinedEmotionLabel` in NamingVC
- Updated `updateIntensitySection()` to toggle between intensity slider (1 emotion) and formula label (2 emotions)
- `ColorEmotionSummaryView` already simplified to show only `emotion.displayName`

**Files Modified**:
- `MoodCheckInNamingViewController.swift` - Added combinedEmotionLabel constraints, updated updateIntensitySection()

---

## Notes

**Priority Levels**:
- P0: Critical/Blocking
- P1: High priority
- P2: Medium priority
- P3: Low priority/Nice to have

**Complexity Estimates**:
- S: Small (< 4 hours)
- M: Medium (4-8 hours)
- L: Large (1-2 days)
- XL: Extra Large (2+ days)

**Completion Rules**:
- When completing a task with complexity **L or XL**, run an Xcode build (`xcodebuild -workspace Soulverse.xcworkspace -scheme "Soulverse" -configuration Debug build`) to verify the project compiles successfully before marking it as done.
