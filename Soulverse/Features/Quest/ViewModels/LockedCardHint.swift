//
//  LockedCardHint.swift
//  Soulverse
//
//  Proximity-aware hint copy for locked Quest cards (8-Dim, Custom Habit
//  slot, etc.). Pure function of (currentDay, unlockDay, featureName);
//  framework-agnostic.
//

import Foundation

enum LockedCardHint {

    /// Returns the hint text per spec §5.3:
    /// - remaining ≥ 3:  "On Day {unlockDay}, you'll {featureName}."
    /// - remaining == 2: "Just 2 more check-ins!"
    /// - remaining == 1: "Just 1 more check-in!"
    /// - remaining ≤ 0:  "" (caller should not show locked state)
    static func copy(currentDay: Int, unlockDay: Int, featureName: String) -> String {
        let remaining = unlockDay - currentDay
        guard remaining > 0 else { return "" }

        if remaining >= 3 {
            let format = NSLocalizedString(
                "quest_locked_hint_future_day",
                bundle: AppBundle.main,
                comment: "Locked-card hint when unlock is more than 2 days away"
            )
            return String(format: format, unlockDay, featureName)
        }

        if remaining == 1 {
            return NSLocalizedString(
                "quest_locked_hint_one_more",
                bundle: AppBundle.main,
                comment: "Locked-card hint when only 1 day remains"
            )
        }

        let format = NSLocalizedString(
            "quest_locked_hint_n_more",
            bundle: AppBundle.main,
            comment: "Locked-card hint when 2 days remain"
        )
        return String(format: format, remaining)
    }
}
