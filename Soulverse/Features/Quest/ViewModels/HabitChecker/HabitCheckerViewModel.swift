//
//  HabitCheckerViewModel.swift
//  Soulverse
//
//  Composes today/yesterday view state for the Habit Checker section.
//

import Foundation

struct HabitCardModel: Equatable {
    let habitId: String
    let titleKey: String
    let unit: String
    let increments: [Int]
    let todayTotal: Int
    let yesterdayTotal: Int

    var shouldShowYesterday: Bool { yesterdayTotal > 0 }
}

enum AddCustomHabitButtonState: Equatable {
    case locked(daysRemaining: Int)
    case available
    case hidden
}

struct HabitCheckerViewModel {
    let state: HabitState
    let todayKey: String
    let distinctCheckInDays: Int

    init(state: HabitState, todayKey: String, distinctCheckInDays: Int = 0) {
        self.state = state
        self.todayKey = todayKey
        self.distinctCheckInDays = distinctCheckInDays
    }

    func cardModel(for habitId: String, titleKey: String, unit: String, increments: [Int]) -> HabitCardModel {
        let yKey = HabitDateKey.yesterdayKey(of: todayKey)
        return HabitCardModel(
            habitId: habitId,
            titleKey: titleKey,
            unit: unit,
            increments: increments,
            todayTotal: state.daily[todayKey]?[habitId] ?? 0,
            yesterdayTotal: state.daily[yKey]?[habitId] ?? 0
        )
    }

    var activeCustomHabit: CustomHabit? {
        state.customHabits.values.first(where: { $0.isActive })
    }

    var addButtonState: AddCustomHabitButtonState {
        let kUnlockDay = 14
        if distinctCheckInDays < kUnlockDay {
            return .locked(daysRemaining: kUnlockDay - distinctCheckInDays)
        }
        if activeCustomHabit != nil {
            return .hidden
        }
        return .available
    }
}
