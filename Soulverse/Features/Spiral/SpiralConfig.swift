import Foundation
import UIKit

/// Configuration for the visual appearance of the Spiral View.
struct SpiralVisualConfig {
    /// Diameter of the glowing head in points.
    var headSize: CGFloat = 30.0

    /// Line width of the spiral path and filled progress in points.
    var lineWidth: CGFloat = 20.0

    /// Distance in points that the filled color leads the finger during inhale/exhale.
    var colorDistanceOffset: CGFloat = 40.0

    /// The starting radius of the spiral in points.
    var startRadius: CGFloat = 10.0

    /// The spacing between spiral loops in points.
    var spacing: CGFloat = 20.0

    /// The number of full rotations for the spiral.
    var rotations: CGFloat = 4.0
}

/// Configuration for the interactive behavior and timing of the Spiral Breathing session.
struct SpiralActionConfig {
    /// Total duration of the "Hold" state in seconds.
    var holdDuration: TimeInterval = 72.0

    /// Duration of the "Scale Up" phase within the hold cycle.
    var holdCycleUpDuration: TimeInterval = 6.0

    /// Duration of the "Pause" phase within the hold cycle.
    var holdCyclePauseDuration: TimeInterval = 4.0

    /// Duration of the "Scale Down" phase within the hold cycle.
    var holdCycleDownDuration: TimeInterval = 8.0

    /// Minimum physical distance (in points) to travel before triggering haptic feedback.
    var hapticFeedbackDistance: CGFloat = 10.0

    /// Time interval between haptic beats during the Hold state.
    var hapticBeatInterval: TimeInterval = 0.1

    /// Total duration of one complete breathing cycle (computed property).
    var holdCycleDuration: TimeInterval {
        return holdCycleUpDuration + holdCyclePauseDuration + holdCycleDownDuration
    }
}
