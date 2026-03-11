//
//  ReflectionCreationViewModel.swift
//

import Foundation

struct ReflectionCreationViewModel {
    let journalCount: Int
    let drawingCount: Int
}

// MARK: - Factory from Firestore Data

extension ReflectionCreationViewModel {
    /// Journal count = check-ins where journal is non-nil and non-empty
    /// Drawing count = total drawings
    static func from(checkIns: [MoodCheckInModel], drawings: [DrawingModel]) -> ReflectionCreationViewModel {
        let journalCount = checkIns.filter { checkIn in
            guard let journal = checkIn.journal else { return false }
            return !journal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count

        return ReflectionCreationViewModel(
            journalCount: journalCount,
            drawingCount: drawings.count
        )
    }
}
