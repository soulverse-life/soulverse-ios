//
//  InsightGridCardViewModel.swift
//

import Foundation

struct InsightGridCardViewModel {
    let iconName: String     // SF Symbol name
    let name: String
    let value: String
}

// MARK: - Mappers

extension HabitActivityViewModel.HabitItem {
    func toGridCardViewModel() -> InsightGridCardViewModel {
        InsightGridCardViewModel(iconName: iconName, name: name, value: valueText)
    }
}

extension CheckinActivityViewModel {
    func toGridCardViewModels() -> [InsightGridCardViewModel] {
        [
            InsightGridCardViewModel(
                iconName: "doc.text.fill",
                name: NSLocalizedString("insight_journals", comment: ""),
                value: String(format: NSLocalizedString("insight_journal_entries", comment: ""), journalCount)
            ),
            InsightGridCardViewModel(
                iconName: "drop.fill",
                name: NSLocalizedString("insight_drawings", comment: ""),
                value: String(format: NSLocalizedString("insight_drawing_pieces", comment: ""), drawingCount)
            ),
        ]
    }
}
