# Mood Check-In Flow Implementation Plan

## Overview
Implement a 7-step mood check-in flow using a presented navigation controller, following the OnboardingCoordinator pattern.

## Flow Structure
1. **Pet** (conditional, first-time only) → Introduction to EmoPet
2. **Sensing** → Color gradient slider + 5 intensity circles
3. **Naming** → 8 emotion tags + dynamic intensity slider
4. **Shaping** → 6 prompts + text field with dynamic placeholder
5. **Attributing** → 8 life area options
6. **Evaluating** → 5 radio button options
7. **Acting** → Summary + actions (Write journal, Make art, Complete check-in)

## Requirements Summary

### Navigation Behavior
- **First screen (Pet)**: Only shows close button (←), no X button on top-right
- **Other screens**: Show back button (←) to previous step + X button (top-right) with confirmation dialog
- **X button**: Shows confirmation dialog "Are you sure you want to exit?"
- **Progress indicator**: Show on all screens except Pet

### Data Flow
- **Sensing**: Slider updates 5 circles automatically (slider controls circles)
- **Naming**: Each emotion has dynamic intensity labels (e.g., Joy: Serenity→Joy→Ecstasy)
- **Shaping**: Text field placeholder changes based on selected prompt
- **Acting**: After API call completes, show success message then dismiss

### Integration Points
- Test button in InnerCosmoViewController
- "Make art" links to DrawingCanvasViewController
- "Write a journal" and "Complete check-in" both call API then dismiss
- UserDefaults key: `"hasSeenMoodCheckInPet"` to skip Pet screen after first time

---

## Implementation Checklist

### Phase 1: Models & Data Foundation
- [ ] Create `Features/MoodCheckIn/Models/` directory
- [ ] Create `EmotionType.swift`
  - [ ] Define 8 emotion cases (Joy, Sadness, Anger, Fear, Trust, Disgust, Anticipation, Surprise)
  - [ ] Add dynamic intensity labels for each emotion (leftLabel, centerLabel, rightLabel)
- [ ] Create `PromptOption.swift`
  - [ ] Define 6 prompt options ("It feels like", "It reminds me of", "I sense", "The emotion is like", "In my body, it's", "The texture is")
  - [ ] Add placeholder text for each prompt
- [ ] Create `LifeAreaOption.swift`
  - [ ] Define 8 life areas (Physical, Emotional, Social, Intellectual, Spiritual, Occupational, Environment, Financial)
- [ ] Create `EvaluationOption.swift`
  - [ ] Define 5 evaluation options from screenshot
- [ ] Create `MoodCheckInData.swift`
  - [ ] Add properties: selectedColor, colorIntensity, emotion, emotionIntensity, selectedPrompt, promptResponse, lifeArea, evaluation
  - [ ] Add validation/completion checks
- [ ] Create `Features/MoodCheckIn/ViewModels/` directory
- [ ] Create `MoodCheckInViewModel.swift` (if needed for presentation logic)

### Phase 2: API Service
- [ ] Create `Shared/Service/APIService/MoodCheckInAPIService.swift`
  - [ ] Follow UserAPIService pattern with Moya
  - [ ] Define `case submitMoodCheckIn(MoodCheckInData)`
  - [ ] Implement TargetType protocol (baseURL, path, method, task, headers)
  - [ ] Create MoyaProvider instance

### Phase 3: Coordinator (Navigation)
- [ ] Create `Features/MoodCheckIn/Presenter/` directory
- [ ] Create `MoodCheckInCoordinator.swift`
  - [ ] Add delegate protocol `MoodCheckInCoordinatorDelegate`
  - [ ] Initialize with UINavigationController
  - [ ] Store MoodCheckInData instance
  - [ ] Implement `start()` method - check UserDefaults to skip/show Pet
  - [ ] Implement navigation methods for all 7 steps
  - [ ] Implement back button logic (first screen = close, others = previous)
  - [ ] Implement X button confirmation dialog
  - [ ] Implement API submission with success message
  - [ ] Implement "Make art" navigation to DrawingCanvasViewController
  - [ ] Handle completion and dismissal

### Phase 4: Custom UI Components
- [ ] Create `Features/MoodCheckIn/Components/` directory
- [ ] Create `ColorGradientSliderView.swift`
  - [ ] Rainbow gradient background
  - [ ] Slider control
  - [ ] Return selected color and position (0-1)
  - [ ] Delegate callback when color changes
- [ ] Create `IntensityCircleSelectorView.swift`
  - [ ] Display 5 circles with varying opacity
  - [ ] Auto-update based on slider value
  - [ ] Visual feedback for current selection
- [ ] Create `RadioOptionView.swift`
  - [ ] Display 5 radio button options
  - [ ] Single selection behavior
  - [ ] Delegate callback for selection

### Phase 5: View Controllers (7 screens)
- [ ] Create `Features/MoodCheckIn/Views/` directory

#### 5.1 MoodCheckInPetViewController
- [ ] Create `MoodCheckInPetViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add title "This is your EmoPet"
  - [ ] Add EmoPet image (droplet shape)
  - [ ] Add description text
  - [ ] Add "Begin" button (SoulverseButton)
  - [ ] Add close button (←) only, no X button
  - [ ] NO progress bar on this screen
  - [ ] Handle button tap → delegate callback

#### 5.2 MoodCheckInSensingViewController
- [ ] Create `MoodCheckInSensingViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add progress bar (step 1/6)
  - [ ] Add back + X buttons
  - [ ] Add title "Sensing"
  - [ ] Add subtitle text
  - [ ] Add ColorGradientSliderView
  - [ ] Add "How strong the feeling?" label
  - [ ] Add IntensityCircleSelectorView (5 circles)
  - [ ] Connect slider to circles (auto-update)
  - [ ] Add "Continue" button
  - [ ] Store selected color + intensity
  - [ ] Handle navigation callbacks

#### 5.3 MoodCheckInNamingViewController
- [ ] Create `MoodCheckInNamingViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add progress bar (step 2/6)
  - [ ] Add back + X buttons
  - [ ] Add title "Naming"
  - [ ] Add color display with "You choose [color]" label
  - [ ] Add prompt "What emotion does this color bring to your mind?"
  - [ ] Add SoulverseTagsView for 8 emotions
  - [ ] Add "[Emotion] Intensity" label
  - [ ] Add intensity slider with dynamic labels (leftLabel, centerLabel, rightLabel based on selected emotion)
  - [ ] Add "Continue" button
  - [ ] Handle emotion selection → update intensity labels
  - [ ] Store selected emotion + intensity
  - [ ] Handle navigation callbacks

#### 5.4 MoodCheckInShapingViewController
- [ ] Create `MoodCheckInShapingViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add progress bar (step 3/6)
  - [ ] Add back + X buttons
  - [ ] Add title "Shaping"
  - [ ] Add subtitle explanation
  - [ ] Add color + emotion display
  - [ ] Add "Choose a prompt" label
  - [ ] Add SoulverseTagsView for 6 prompts
  - [ ] Add selected prompt as header above text field
  - [ ] Add text field with dynamic placeholder (changes with prompt selection)
  - [ ] Add "Continue" button
  - [ ] Handle prompt selection → update placeholder
  - [ ] Store selected prompt + text response
  - [ ] Handle navigation callbacks

#### 5.5 MoodCheckInAttributingViewController
- [ ] Create `MoodCheckInAttributingViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add progress bar (step 4/6)
  - [ ] Add back + X buttons
  - [ ] Add title "Attributing"
  - [ ] Add subtitle explanation
  - [ ] Add SoulverseTagsView for 8 life areas (2 columns grid)
  - [ ] Add "Continue" button
  - [ ] Store selected life area
  - [ ] Handle navigation callbacks

#### 5.6 MoodCheckInEvaluatingViewController
- [ ] Create `MoodCheckInEvaluatingViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add progress bar (step 5/6)
  - [ ] Add back + X buttons
  - [ ] Add title "Evaluating"
  - [ ] Add prompt "How do you feel about this feeling?"
  - [ ] Add RadioOptionView for 5 options
  - [ ] Add "Continue" button
  - [ ] Store selected evaluation
  - [ ] Handle navigation callbacks

#### 5.7 MoodCheckInActingViewController
- [ ] Create `MoodCheckInActingViewController.swift`
  - [ ] Add delegate protocol
  - [ ] Add progress bar (step 6/6)
  - [ ] Add back + X buttons
  - [ ] Add title "Acting"
  - [ ] Add subtitle
  - [ ] Add "Your emotional journey" section header
  - [ ] Add summary display (Color, Emotions, Expression)
  - [ ] Add "Write a journal" button
  - [ ] Add "Make art" button
  - [ ] NO "Take a photo" button (removed)
  - [ ] Add "Complete check-in" button
  - [ ] Handle button taps → API call + success message + dismiss
  - [ ] Handle navigation callbacks

### Phase 6: Integration
- [ ] Update `AppCoordinator.swift`
  - [ ] Add `presentMoodCheckIn(from:)` method
  - [ ] Create navigation controller
  - [ ] Initialize MoodCheckInCoordinator
  - [ ] Present modally (fullScreen)
  - [ ] Handle coordinator delegate completion
- [ ] Update `InnerCosmoViewController.swift`
  - [ ] Add test button (in tableView header or section)
  - [ ] Call AppCoordinator.presentMoodCheckIn(from: self)

### Phase 7: Testing & Refinement
- [ ] Test complete flow from start to finish
- [ ] Test UserDefaults Pet screen skip functionality
- [ ] Test back button navigation through all steps
- [ ] Test X button confirmation dialog
- [ ] Test data persistence through navigation
- [ ] Test API submission with all collected data
- [ ] Test "Make art" navigation to DrawingCanvasViewController
- [ ] Test success message display after API call
- [ ] Verify all screens match design screenshots
- [ ] Fine-tune spacing, padding, fonts
- [ ] Add proper error handling
- [ ] Add accessibility labels

### Phase 8: Polish & Edge Cases
- [ ] Handle empty/invalid inputs with validation
- [ ] Add smooth animations between steps
- [ ] Test on different screen sizes
- [ ] Verify theme compatibility
- [ ] Add loading states during API calls
- [ ] Handle API errors gracefully
- [ ] Add proper localization strings
- [ ] Code review and cleanup

---

## Technical Architecture

### File Structure
```
Features/MoodCheckIn/
├── Models/
│   ├── EmotionType.swift
│   ├── PromptOption.swift
│   ├── LifeAreaOption.swift
│   ├── EvaluationOption.swift
│   └── MoodCheckInData.swift
├── ViewModels/
│   └── MoodCheckInViewModel.swift (optional)
├── Presenter/
│   └── MoodCheckInCoordinator.swift
├── Views/
│   ├── MoodCheckInPetViewController.swift
│   ├── MoodCheckInSensingViewController.swift
│   ├── MoodCheckInNamingViewController.swift
│   ├── MoodCheckInShapingViewController.swift
│   ├── MoodCheckInAttributingViewController.swift
│   ├── MoodCheckInEvaluatingViewController.swift
│   └── MoodCheckInActingViewController.swift
└── Components/
    ├── ColorGradientSliderView.swift
    ├── IntensityCircleSelectorView.swift
    └── RadioOptionView.swift

Shared/Service/APIService/
└── MoodCheckInAPIService.swift
```

### Reused Components
- `SoulverseButton` - All action buttons
- `SoulverseProgressBar` - Step progress indicator
- `SoulverseTagsView` - Emotion tags, Prompt selection, Life area selection
- `SummitSlider` - Intensity sliders
- `DrawingCanvasViewController` - For "Make art" action

### Data Flow
```
User Input → ViewController → Delegate → Coordinator → MoodCheckInData
                                                      ↓
                                              MoodCheckInAPIService
                                                      ↓
                                              Success Message → Dismiss
```

---

## Current Status: Core Implementation Complete ✅

**Completed Phases:**
1. ✅ Phase 1: Models directory and all data structures
2. ✅ Phase 2: MoodCheckInAPIService
3. ✅ Phase 3: MoodCheckInCoordinator with all navigation logic
4. ✅ Phase 4: Custom UI components (ColorGradientSlider, IntensityCircles, RadioOptions)
5. ✅ Phase 5: All 7 view controllers
6. ✅ Phase 6: Integration with AppCoordinator and test button in InnerCosmo

**Next Steps:**
- Build and test the complete flow
- Fix any compilation errors
- Fine-tune UI to match design screenshots
- Test navigation between all steps
- Test data persistence through the flow
- Polish animations and transitions

---

## Notes
- Follow existing OnboardingCoordinator pattern closely
- Reuse SoulverseTagsView wherever possible (Naming, Shaping, Attributing screens)
- Keep ViewModels directory for presentation logic only
- Put all data models in Models directory
- Follow domain-based API service pattern (MoodCheckInAPIService)
- Test button in InnerCosmo is temporary for development only
