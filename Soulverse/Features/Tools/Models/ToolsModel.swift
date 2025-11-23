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

struct ToolItem {
    let iconName: String
    let title: String
    let description: String
    let action: ToolAction
}

struct ToolSection {
    let title: String
    let items: [ToolItem]
}
