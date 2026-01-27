# Soulverse TODO

## Backlog

### 1. Make topics as reusable model object
**Priority**: P1
**Complexity**: M
**Status**: Pending

Create a reusable Topic model object that can be shared across different views instead of duplicating topic logic. This should standardize how topics are represented and handled throughout the app.

**Technical Considerations**:
- Define Topic model with properties (id, title, description, icon/image)
- Ensure model is localization-ready (NSLocalizedString support)
- Consider adding to shared Models folder
- Update existing views to use the new model

---

### 2. Make emo pet image tappable in InnerCosmos
**Priority**: P2
**Complexity**: S
**Status**: Pending

Add tap gesture recognizer to the emo pet image in InnerCosmos page. When tapped, display an affirmation quote reaction.

**Technical Considerations**:
- Add UITapGestureRecognizer to pet image view
- Create/reuse affirmation quote data source
- Design tap feedback animation (consider using Lottie)
- Ensure quotes are localized in both en/zh-TW
- Use theme-aware colors for quote display

---

### 3. Implement text-color focus game
**Priority**: P2
**Complexity**: L
**Status**: Pending
**Blocked by**: PRD to be provided

A new cognitive focus game tool. Awaiting detailed PRD for requirements and specifications.

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

### 6. Modify moodCheckInAttributing page layout
**Priority**: P2
**Complexity**: M
**Status**: Pending

Update the moodCheckInAttributing page to use a similar layout as the onboarding topic selection screen.

**Technical Considerations**:
- Review existing onboarding topic layout implementation
- Refactor moodCheckInAttributing views to match design pattern
- Ensure consistent spacing using ViewComponentConstants
- Maintain theme-aware colors
- Update localization strings if needed
- Test flow with both languages

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

### 8. Redesign QuestRadarChartView with colored axis dots & center progress dot
**Priority**: P1
**Complexity**: M
**Status**: Pending
**Blocked by**: #1 (Topics model)

Redesign the radar chart to show uniquely colored dots on each of the 8 axes and a center dot for overall progress. Replace the current blue-fill polygon with a clean web grid + colored dots style.

**Key Changes**:
- Each axis vertex gets a colored dot matching its topic color (reuse `TopicOption.cardColor`)
- Selected/active topic dot shown as hollow ring (border only)
- Center progress dot uses selected topic's color
- Update dimensions to 8 wellness domains: Physical, Emotional, Social, Intellectual, Environment, Occupational, Spiritual, Financial
- Data set becomes transparent (no fill, no line) — only web grid + dots visible

**Files to Modify**:
- `QuestViewModel.swift` — Add `color: UIColor` to `RadarChartMetric`, add `selectedIndex` and `progressValue` to `QuestRadarData`
- `QuestRadarChartView.swift` — Overlay colored dot UIViews at axis vertices via trigonometry, add center progress dot, make data set transparent
- `QuestViewPresenter.swift` — Update mock data with 8 wellness topics and their colors from `TopicOption`
- `Localizable.strings` (en + zh-TW) — Localization strings already exist (`onboarding_topics_*`), reuse those

**Acceptance Criteria**:
- Colored solid dots at each axis vertex
- Active topic dot is hollow ring
- Center dot uses active topic color
- Labels match 8 wellness domains
- Animation preserved
- Theme-aware colors

---

## In Progress

_No tasks currently in progress_

---

## Done

_No completed tasks yet_

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
