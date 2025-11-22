# Spiral Breathing Feature Architecture

## Overview
The Spiral Breathing feature is an interactive mindfulness exercise where users trace a spiral path to guide their breathing. It involves complex visual animations, haptic feedback, and strict touch tracking.

## Components

### 1. SpiralView (`SpiralView.swift`)
**Responsibility**: Rendering the spiral, handling animations, and calculating path progress.
- **Layers**:
    - `spiralPathLayer`: The dimmed background track.
    - `gradientLayer` + `progressLayer` (Mask): The colorful filled line that follows the user's progress.
    - `headGlowLayer`: The glowing orb at the tip of the filled line.
- **Coordinate System**:
    - **Path Generation**: Archimedean spiral generated via points.
    - **Progress Calculation**: Uses **Physical Length** (`cumulativeLengths`) rather than point index to ensure consistent drawing speed and touch tracking.
    - **Offset Logic**: The filled color leads the finger by a fixed distance (`colorDistanceOffset`) during Inhale and Exhale to guide the user.

### 2. SpiralBreathingViewController (`SpiralBreathingViewController.swift`)
**Responsibility**: Managing the application state, user interaction, and coordinating feedback.
- **State Machine**: `BreathingState` (Idle -> Inhale -> Hold -> Exhale -> Completed).
- **Touch Handling**:
    - Tracks touch location relative to the `headGlowLayer`.
    - Enforces strict proximity (user must follow the path).
    - Manages the interactive "Hold" state (pause/resume on touch/lift).
- **Feedback**:
    - **Haptics**: `UIImpactFeedbackGenerator` for tracing and heartbeat simulation.
    - **Visuals**: Triggers pulse animations and text updates.

### 3. Configuration (`SpiralConfig.swift`)
**Responsibility**: Centralizing tunable parameters for easy adjustment.
- **`SpiralVisualConfig`**:
    - `headSize`: Size of the glowing orb.
    - `lineWidth`: Thickness of the spiral path.
    - `colorDistanceOffset`: How far ahead the color leads the finger.
    - `startRadius`, `spacing`, `rotations`: Spiral geometry parameters.
- **`SpiralActionConfig`**:
    - `holdDuration`: Total time for the Hold state (default 24s).
    - `holdCycleDuration`: Duration of one breath/heartbeat cycle (default 6s).
    - `holdCycleUpDuration` / `Pause` / `Down`: Timing for the pulse animation.
    - `hapticFeedbackDistance`: Minimum physical distance to trigger haptic feedback (throttling).
    - `hapticBeatInterval`: Time between haptic beats in the Hold state sequence.

## Key Mechanisms

### Progress Calculation (Length-Based & Optimized)
To solve the issue of uneven point density in the spiral, we calculate the cumulative length of the path at every point.
- **Optimization**: `closestProgress(to point)` uses a **local search** (checking +/- 50 points around the last known position) to ensure high performance (60fps) during drag gestures, falling back to a full scan only if tracking is lost.
- `setProgress(progress)`: Finds the point where `cumulativeLength >= totalLength * progress`.

### Interactive Hold State
- **Requirement**: User must hold their finger on the spot.
- **Implementation**:
    - `holdTimer`: Decrements `holdRemainingTime` only while touching.
    - `visualPulse`: `CAKeyframeAnimation` (Scale 1->3->3->1) synced with haptics.
    - **Haptics**: A custom pattern (10 rapid beats) triggered every `holdCycleDuration`.

## Localization
All user-facing strings are wrapped in `NSLocalizedString` to support future translation.
