//
//  HabitActivityViewModel.swift
//

import Foundation

struct HabitActivityViewModel {
    let title: String
    let subtitle: String
    let habits: [HabitItem]

    struct HabitItem {
        let name: String
        let iconName: String     // SF Symbol name
        let valueText: String    // e.g. "45 min", "1600 ml"
        let isBuiltIn: Bool
    }
}

// MARK: - Mock Data

extension HabitActivityViewModel {
    static func mockData() -> HabitActivityViewModel {
        let habits = [
            HabitItem(name: NSLocalizedString("insight_habit_exercise", comment: ""),
                      iconName: "figure.run", valueText: "45 min", isBuiltIn: true),
            HabitItem(name: NSLocalizedString("insight_habit_water", comment: ""),
                      iconName: "drop.fill", valueText: "1600 ml", isBuiltIn: true),
            HabitItem(name: NSLocalizedString("insight_habit_meditation", comment: ""),
                      iconName: "brain.head.profile", valueText: "30 min", isBuiltIn: true),
            HabitItem(name: NSLocalizedString("insight_habit_custom", comment: ""),
                      iconName: "lock.fill", valueText: NSLocalizedString("insight_habit_locked", comment: ""), isBuiltIn: false),
        ]

        let totalCompleted = habits.filter { $0.isBuiltIn }.count * 6 // mock total
        let title = String(format: NSLocalizedString("insight_habit_completed", comment: ""), totalCompleted)
        let subtitle = NSLocalizedString("insight_habit_subtitle", comment: "")

        return HabitActivityViewModel(
            title: title,
            subtitle: subtitle,
            habits: habits
        )
    }
}
