//
//  MoodCheckinActivityViewModel.swift
//  Soulverse
//

import Foundation

struct MoodCheckinActivityViewModel {
    let title: String
    let totalCheckins: Int
    let currentStreak: Int          // consecutive days with at least 1 check-in
    let averagePerWeek: Double
}

// MARK: - Factory from Firestore Data

extension MoodCheckinActivityViewModel {
    static func from(checkIns: [MoodCheckInModel]) -> MoodCheckinActivityViewModel {
        let totalCheckins = checkIns.count

        // Compute current streak: consecutive days from today going backwards
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get unique check-in days
        var checkInDays = Set<Date>()
        for checkIn in checkIns {
            if let createdAt = checkIn.createdAt {
                checkInDays.insert(calendar.startOfDay(for: createdAt))
            }
        }

        var streak = 0
        var currentDate = today
        while checkInDays.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = previousDay
        }

        // Average per week
        let averagePerWeek: Double
        if let earliest = checkIns.compactMap({ $0.createdAt }).min() {
            let daysBetween = max(1, calendar.dateComponents([.day], from: earliest, to: today).day ?? 1)
            let weeks = max(1.0, Double(daysBetween) / 7.0)
            averagePerWeek = Double(totalCheckins) / weeks
        } else {
            averagePerWeek = 0.0
        }

        return MoodCheckinActivityViewModel(
            title: NSLocalizedString("insight_mood_checkin_activity_title", comment: ""),
            totalCheckins: totalCheckins,
            currentStreak: streak,
            averagePerWeek: averagePerWeek
        )
    }
}
