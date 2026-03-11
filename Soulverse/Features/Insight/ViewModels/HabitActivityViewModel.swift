//
//  HabitActivityViewModel.swift
//

import Foundation

struct HabitActivityViewModel {
    let title: String
    let habits: [HabitItem]

    struct HabitItem {
        let name: String
        let iconName: String     // SF Symbol name
        let currentStreak: Int
        let totalCount: Int
        let isBuiltIn: Bool
    }
}

// MARK: - Mock Data

extension HabitActivityViewModel {
    static func mockData() -> HabitActivityViewModel {
        return HabitActivityViewModel(
            title: NSLocalizedString("insight_habit_activity_title", comment: ""),
            habits: [
                HabitItem(name: NSLocalizedString("insight_habit_exercise", comment: ""),
                          iconName: "figure.run", currentStreak: 3, totalCount: 12, isBuiltIn: true),
                HabitItem(name: NSLocalizedString("insight_habit_water", comment: ""),
                          iconName: "drop.fill", currentStreak: 5, totalCount: 20, isBuiltIn: true),
                HabitItem(name: NSLocalizedString("insight_habit_meditation", comment: ""),
                          iconName: "brain.head.profile", currentStreak: 2, totalCount: 8, isBuiltIn: true),
                HabitItem(name: NSLocalizedString("insight_habit_custom", comment: ""),
                          iconName: "star.fill", currentStreak: 1, totalCount: 4, isBuiltIn: false),
            ]
        )
    }
}
