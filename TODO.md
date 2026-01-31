# Soulverse TODO

## Backlog

### 9. Integrate login/signin function
**Priority**: P0 (Critical)
**Complexity**: M (4-8 hours)
**Status**: Pending

Integrate login and sign-in functionality using Firebase Authentication.

**Scope**:
- Apple Sign-In
- Google Sign-In
- ~~Facebook Sign-In~~ (not needed)

**Current State**:
- Login UI is already implemented
- Need to wire up authentication logic

**Key Requirements**:
1. Integrate Firebase Authentication SDK
2. Implement Apple Sign-In flow
3. Implement Google Sign-In flow
4. **User flow distinction**: Detect if user is first-time or returning
   - First-time user → Route to onboarding flow
   - Returning user → Route to main app (skip onboarding)
5. Store/retrieve user auth state

**Technical Considerations**:
- Use existing Firebase setup (already in project for Analytics/Crashlytics)
- Check Firebase user creation timestamp vs last sign-in to detect new users
- Alternatively, use a backend flag or local storage to track onboarding completion
- Handle auth token refresh
- Add error handling for auth failures
- Localize error messages (en/zh-TW)

---

### 4. Implement half-screen modal for state-of-change questionnaire
**Priority**: P1
**Complexity**: M
**Status**: Pending

Create a half-screen modal view that prompts users to complete a state-of-change questionnaire.

**Technical Considerations**:
- Implement custom UIPresentationController for half-screen modal
- Design questionnaire flow (multi-step or single page?)
- Determine trigger conditions for showing modal
- Add analytics tracking for questionnaire start/completion
- Ensure proper keyboard handling with IQKeyboardManager
- Use theme-aware styling
- Localize all questionnaire content

---

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

---

### 5. Implement horizontal scroll view for user-created pictures
**Priority**: P2
**Complexity**: M
**Status**: Pending

Add horizontal scroll view in InnerCosmos page to display pictures that the user has previously created.

**Technical Considerations**:
- Design horizontal UIScrollView/UICollectionView layout
- Implement image loading with Kingfisher for performance
- Add empty state for users with no pictures
- Consider pagination if user has many pictures
- Add tap interaction to view full-size image
- Ensure proper memory management for image caching
- Use SnapKit for layout constraints

---

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
**Blocked by**: PRD to be provided

Implement emotion-to-score mapping function and create a weekly mood score visualization view. Awaiting detailed PRD for scoring algorithm and visualization requirements.

**Technical Considerations**:
- Design emotion-score mapping algorithm
- Create data model for mood tracking over time
- Implement weekly aggregation logic
- Design visualization (chart/graph using custom drawing or library)
- Add API integration for persisting mood data
- Consider using Core Data for local caching
- Add analytics for mood tracking engagement

---

## In Progress

### 2. Make emo pet image tappable in InnerCosmos
**Priority**: P2
**Complexity**: S
**Status**: In Progress

Add tap gesture recognizer to the emo pet image in InnerCosmos page. When tapped, display an affirmation quote reaction with TTS.

**Implementation Progress**:
- ✅ Added `CentralPlanetViewDelegate` protocol for tap events
- ✅ Added tap gesture to `CentralPlanetView` with bounce animation
- ✅ Created `AffirmationQuote` model loading from JSON (`AffirmationQuotes.json`)
- ✅ Created `AffirmationBubbleView` speech bubble UI (positioned right of pet)
- ✅ Created `SpeechService` for TTS (reusable across app)
- ✅ Integrated TTS - bubble dismisses after speech finishes + 0.2s
- ✅ Quotes localized in both en/zh-TW (10 quotes)

**Files Created**:
- `Soulverse/Resources/AffirmationQuotes.json`
- `Soulverse/Features/InnerCosmo/ViewModels/AffirmationQuote.swift`
- `Soulverse/Features/InnerCosmo/Views/Components/AffirmationBubbleView.swift`
- `Soulverse/Shared/Service/SpeechService.swift`

**Files Modified**:
- `CentralPlanetView.swift` - Added tap gesture + delegate
- `InnerCosmoDailyView.swift` - Handles tap, shows bubble, integrates TTS

**Remaining**:
- Add files to Xcode project

**Sub-tasks**:
- [ ] Review implementation (test tap gesture, bubble, TTS, JSON loading, both locales)
- [ ] Change bubble background color
- [ ] Update affirmation quote data

---

## Done

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
