//
//  CustomHabitDeletionConfirmation.swift
//  Soulverse
//

import UIKit

enum CustomHabitDeletionConfirmation {
    /// Build the deletion confirmation alert per spec §D7.
    static func make(habitName: String, onConfirm: @escaping () -> Void) -> UIAlertController {
        let title = NSLocalizedString("quest_habit_delete_alert_title", comment: "")
        let message = String(
            format: NSLocalizedString("quest_habit_delete_alert_body_format", comment: ""),
            habitName
        )
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("quest_habit_delete_alert_cancel", comment: ""),
            style: .cancel,
            handler: nil
        ))
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("quest_habit_delete_alert_confirm", comment: ""),
            style: .destructive,
            handler: { _ in onConfirm() }
        ))
        return alert
    }
}
