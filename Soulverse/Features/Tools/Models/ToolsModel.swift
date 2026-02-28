import Foundation

/// Defines the action to perform when a tool is selected
enum ToolAction {
    case emotionBundle
    case selfSoothingLabyrinth
    case cosmicDriftBottle
    case dailyQuote
    case timeCapsule
    case comingSoon  // For tools not yet implemented

    /// Debug description for logging
    var debugDescription: String {
        switch self {
        case .emotionBundle:
            return "Emotion Bundle (Proactive Safety Plan)"
        case .selfSoothingLabyrinth:
            return "Self-Soothing Labyrinth (Spiral Breathing)"
        case .cosmicDriftBottle:
            return "Cosmic Drift Bottle (Anonymous Messages)"
        case .dailyQuote:
            return "Daily Quote"
        case .timeCapsule:
            return "Time Capsule"
        case .comingSoon:
            return "Coming Soon"
        }
    }
}

/// Reason why a tool is locked
enum LockReason {
    case notSubscribed
    case notImplemented
}

/// Lock state for a tool cell
enum ToolLockState {
    case unlocked
    case locked(LockReason)

    var isLocked: Bool {
        if case .locked = self { return true }
        return false
    }

    var lockReason: LockReason? {
        if case .locked(let reason) = self { return reason }
        return nil
    }
}

struct ToolItem {
    let iconName: String
    let title: String
    let description: String
    let action: ToolAction
    let lockState: ToolLockState
}

struct ToolSection {
    let title: String
    let items: [ToolItem]
}
