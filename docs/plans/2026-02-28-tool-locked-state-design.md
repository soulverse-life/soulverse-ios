# Design: Tool Locked State

## Problem
Tools in the grid have no visual distinction between available and unavailable items.
Users need clear feedback when a tool is locked (not subscribed or not yet implemented).

## Design

### Data Model
- `ToolLockState` enum: `.unlocked` | `.locked(LockReason)`
- `LockReason` enum: `.notSubscribed` | `.notImplemented` (extensible)
- Added as a property on `ToolsCellViewModel`

### Visual Treatment
- **Blur overlay**: `UIVisualEffectView` with system blur covers cell content
- **Lock icon**: Centered `lock.fill` SF Symbol on top of blur
- **Unlocked cells**: No change to existing appearance

### Tap Behavior
- **Unlocked**: Existing tool action (no change)
- **Locked (.notSubscribed)**: Show subscription prompt
- **Locked (.notImplemented)**: Show "coming soon" toast

### Architecture
- Lock state is determined by the Presenter (business logic)
- Cell only renders the visual state it's given
- ViewController routes taps based on lock state before checking tool action
