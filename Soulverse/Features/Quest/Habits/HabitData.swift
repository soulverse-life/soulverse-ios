//
//  HabitData.swift
//  Soulverse
//
//  Habit data models for the Quest tab Habit Checker.
//

import Foundation

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
