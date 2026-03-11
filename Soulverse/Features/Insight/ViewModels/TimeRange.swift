//
//  TimeRange.swift
//

import Foundation

enum TimeRange {
    case last7Days
    case all

    var displayTitle: String {
        switch self {
        case .last7Days:
            return NSLocalizedString("insight_last_7_days", comment: "")
        case .all:
            return NSLocalizedString("insight_all_time", comment: "")
        }
    }

    /// Returns the start date for Firestore queries (nil = no lower bound = "all")
    var startDate: Date? {
        switch self {
        case .last7Days:
            return Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .all:
            return nil
        }
    }
}
