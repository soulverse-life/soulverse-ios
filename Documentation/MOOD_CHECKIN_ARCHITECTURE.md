# Mood Check-In Architecture

## Design Philosophy

The MoodCheckIn feature is designed to be **fully self-contained and flexible**, with no tight coupling to any specific view controller. This allows it to be presented from anywhere in the app.

## Key Design Principles

### 1. Self-Managing Lifecycle
The `MoodCheckInCoordinator` manages its own lifecycle using a self-retention pattern:
- Retains itself when started
- Releases itself when completed or cancelled
- No external reference management needed

### 2. Closure-Based Callbacks
Uses closures instead of delegates for maximum flexibility:
```swift
AppCoordinator.presentMoodCheckIn(from: self) { completed, data in
    if completed {
        // Handle successful completion
    } else {
        // Handle cancellation
    }
}
```

### 3. No View Controller Coupling
- Any view controller can present the mood check-in flow
- No need to conform to protocols or implement delegate methods
- Simple, one-line call with optional completion handler

## Architecture

### AppCoordinator
**Role**: Entry point for presenting the mood check-in flow

```swift
static func presentMoodCheckIn(
    from sourceVC: UIViewController, 
    completion: ((Bool, MoodCheckInData?) -> Void)? = nil
)
```

**Features**:
- Creates and configures the coordinator
- Sets up completion callbacks
- Presents the navigation controller
- Handles dismissal automatically

### MoodCheckInCoordinator
**Role**: Manages the entire mood check-in flow

**Lifecycle Management**:
```swift
private var strongSelf: MoodCheckInCoordinator?  // Self-retention

init(navigationController: UINavigationController) {
    self.strongSelf = self  // Retain self
}

private func handleCompletion() {
    onComplete?(moodCheckInData)
    strongSelf = nil  // Release self
}
```

**Responsibilities**:
- Navigate between 7 view controllers
- Collect and manage mood check-in data
- Handle UserDefaults (Pet screen visibility)
- Submit data to API
- Trigger completion/cancellation callbacks
- Clean up after completion

## Usage Examples

### Basic Usage (No Callback)
```swift
// From anywhere in the app
AppCoordinator.presentMoodCheckIn(from: self)
```

### With Completion Handler
```swift
AppCoordinator.presentMoodCheckIn(from: self) { completed, data in
    if completed {
        print("User completed check-in!")
        print("Emotion: \(data?.emotion?.displayName ?? "N/A")")
        // Show success message, update UI, etc.
    } else {
        print("User cancelled")
    }
}
```

### From App Launch (Daily Check-In)
```swift
// In AppDelegate or SceneDelegate
func checkDailyMoodCheckIn() {
    guard let rootVC = window?.rootViewController else { return }
    
    if shouldShowDailyMoodCheckIn() {
        AppCoordinator.presentMoodCheckIn(from: rootVC) { completed, data in
            if completed {
                // Update daily check-in status
                UserDefaults.standard.set(Date(), forKey: "lastMoodCheckIn")
            }
        }
    }
}
```

### From Push Notification
```swift
func handleMoodCheckInNotification() {
    guard let topVC = UIViewController.getLastPresentedViewController() else { return }
    
    AppCoordinator.presentMoodCheckIn(from: topVC) { completed, data in
        if completed {
            // Track notification conversion
            Analytics.track("mood_checkin_from_notification_completed")
        }
    }
}
```

## Benefits

### ✅ Flexibility
- Can be presented from any view controller
- No protocol conformance required
- Works with any navigation structure

### ✅ Clean Separation
- Coordinator manages its own lifecycle
- No memory leaks or retain cycles
- AppCoordinator doesn't need to track coordinator references

### ✅ Testability
- Easy to test in isolation
- Can mock completion callbacks
- No complex delegate setup needed

### ✅ Maintainability
- Single responsibility principle
- Clear ownership of resources
- Easy to understand flow

## Flow Diagram

```
User Action
    ↓
AppCoordinator.presentMoodCheckIn()
    ↓
Creates MoodCheckInCoordinator
    ↓
Coordinator retains itself
    ↓
Starts 7-step flow
    ↓
User completes/cancels
    ↓
Calls completion callback
    ↓
Dismisses UI
    ↓
Coordinator releases itself
    ↓
Deallocated ✓
```

## Memory Management

The self-retention pattern ensures:
1. Coordinator stays alive during the entire flow
2. Automatically deallocates when flow ends
3. No lingering references in AppCoordinator
4. No manual cleanup needed

```swift
// Retain
init(navigationController: UINavigationController) {
    self.strongSelf = self  // ← Prevents deallocation
}

// Release
private func handleCompletion() {
    onComplete?(moodCheckInData)
    strongSelf = nil  // ← Allows deallocation
}
```

## Future Enhancements

This architecture makes it easy to add:
- Daily reminder notifications
- App launch check-in prompts
- Context-specific check-ins (after specific events)
- Multiple check-in types with different flows
- A/B testing different onboarding flows

All without modifying existing view controllers!
