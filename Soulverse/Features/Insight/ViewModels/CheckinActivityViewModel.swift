//
//  CheckinActivityViewModel.swift
//

import Foundation

struct CheckinActivityViewModel {
    let title: String
    let subtitle: String
    let journalCount: Int
    let drawingCount: Int
}

// MARK: - Factory from Firestore Data

extension CheckinActivityViewModel {
    static func from(checkIns: [MoodCheckInModel], drawings: [DrawingModel]) -> CheckinActivityViewModel {
        let journalCount = checkIns.filter { $0.journalId != nil }.count

        return CheckinActivityViewModel(
            title: NSLocalizedString("insight_checkin_activity_title", comment: ""),
            subtitle: NSLocalizedString("insight_checkin_activity_subtitle", comment: ""),
            journalCount: journalCount,
            drawingCount: drawings.count
        )
    }
}
