//
//  HabitData.swift
//  Soulverse
//
//  Habit data models for the Quest tab Habit Checker.
//

import UIKit

/// Three reserved default habit ids. These keys are NEVER used for custom habits
/// (custom habit ids are prefixed `h_<uuid>`).
enum DefaultHabitId: String, CaseIterable {
    case exercise   = "exercise"
    case water      = "water"
    case meditation = "meditation"

    /// Display unit (post-localized; units are short identifiers).
    var unit: String {
        switch self {
        case .exercise:   return "min"
        case .water:      return "ml"
        case .meditation: return "min"
        }
    }

    /// Increment values shown as buttons.
    var increments: [Int] {
        switch self {
        case .exercise:   return [5, 10, 15, 30]
        case .water:      return [100, 200, 300]
        case .meditation: return [5, 10, 20]
        }
    }

    var titleKey: String {
        switch self {
        case .exercise:   return "quest_habit_exercise_title"
        case .water:      return "quest_habit_water_title"
        case .meditation: return "quest_habit_meditation_title"
        }
    }

    /// Per-habit accent color used by `DefaultHabitCard` for the icon,
    /// today-total label, and increment-button tints.
    var accentColor: UIColor {
        switch self {
        case .exercise:   return UIColor(hex: "#4CC38A") ?? .systemGreen
        case .water:      return UIColor(hex: "#4DABF7") ?? .systemBlue
        case .meditation: return UIColor(hex: "#9775FA") ?? .systemPurple
        }
    }

    /// SF Symbol name shown next to the habit title.
    var iconName: String {
        switch self {
        case .exercise:   return "figure.run"
        case .water:      return "drop.fill"
        case .meditation: return "sun.max.fill"
        }
    }
}

/// User-defined custom habit. Soft-deleted by setting `deletedAt`.
/// Soft-deletion preserves historical totals in the daily map.
struct CustomHabit: Equatable {
    let id: String              // "h_<uuid>"
    let name: String
    let unit: String
    let increments: [Int]
    let createdAt: Date
    let deletedAt: Date?

    var isActive: Bool { deletedAt == nil }
}

extension CustomHabit {
    /// Deterministically pick an accent slot for this habit based on its id.
    /// Same id → same slot across app launches (Swift's `String.hashValue` is
    /// per-run randomised, so we hash the unicode scalars ourselves).
    private var paletteIndex: Int {
        let sum = id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return sum % CustomHabitPalette.slots.count
    }

    var accentColor: UIColor { CustomHabitPalette.slots[paletteIndex].color }
    var iconName: String     { CustomHabitPalette.slots[paletteIndex].iconName }
}

/// Pre-defined (colour, icon) slots for user-created custom habits.
/// Chosen to avoid visual collision with the three default-habit accents
/// (exercise=green, water=blue, meditation=purple).
enum CustomHabitPalette {
    struct Slot {
        let color: UIColor
        let iconName: String
    }

    static let slots: [Slot] = [
        Slot(color: UIColor(hex: "#FF6B6B") ?? .systemRed,    iconName: "flame.fill"),    // intensity
        Slot(color: UIColor(hex: "#FFA94D") ?? .systemOrange, iconName: "heart.fill"),    // self-care
        Slot(color: UIColor(hex: "#FFD43B") ?? .systemYellow, iconName: "book.fill"),     // learning
        Slot(color: UIColor(hex: "#63E6BE") ?? .systemTeal,   iconName: "leaf.fill"),     // calm/nature
        Slot(color: UIColor(hex: "#E599F7") ?? .systemPink,   iconName: "sparkles")       // joy
    ]
}

enum HabitData {
    /// True if `key` is one of the three reserved default-habit ids.
    static func isReservedDefaultKey(_ key: String) -> Bool {
        DefaultHabitId.allCases.contains(where: { $0.rawValue == key })
    }

    /// Generate a new custom-habit id with the `h_` prefix to avoid colliding
    /// with reserved default keys. Uses UUID for uniqueness.
    static func generateCustomHabitId() -> String {
        "h_" + UUID().uuidString.lowercased().replacingOccurrences(of: "-", with: "")
    }
}
