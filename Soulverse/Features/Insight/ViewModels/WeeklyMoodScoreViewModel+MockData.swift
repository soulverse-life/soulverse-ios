//
//  WeeklyMoodScoreViewModel+MockData.swift
//  Soulverse
//

import Foundation

// MARK: - Mock Data

extension WeeklyMoodScoreViewModel {

    /// Returns mock data for the week containing `referenceDate`.
    /// Uses the week number to pick from pre-defined datasets so each week looks different.
    static func mockData(referenceDate: Date = Date()) -> WeeklyMoodScoreViewModel {
        let calendar = Calendar.current
        let weekNumber = calendar.component(.weekOfYear, from: referenceDate)

        func dateWithHour(_ hour: Int, dayOffset: Int) -> Date? {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: referenceDate) else { return nil }
            return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)
        }

        let weekData: [[MoodCheckInEntry]]

        if weekNumber % 2 == 0 {
            // ── Week A: upbeat week, mostly positive scores ──
            weekData = [
                // Sat: 3 check-ins (busy day)
                [
                    MoodCheckInEntry(time: dateWithHour(9, dayOffset: -6)!, score: 0.7, colorHex: "A8E6CF"),
                    MoodCheckInEntry(time: dateWithHour(13, dayOffset: -6)!, score: 0.3, colorHex: "FDFD96"),
                    MoodCheckInEntry(time: dateWithHour(22, dayOffset: -6)!, score: -0.5, colorHex: "FFB7B2")
                ],
                // Sun: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(15, dayOffset: -5)!, score: -0.1, colorHex: "9370DB")
                ],
                // Mon: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(10, dayOffset: -4)!, score: 0.4, colorHex: "FFB347")
                ],
                // Tue: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(20, dayOffset: -3)!, score: -0.2, colorHex: "B39EB5")
                ],
                // Wed: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(12, dayOffset: -2)!, score: 0.05, colorHex: "FFDAB9")
                ],
                // Thu: 2 check-ins
                [
                    MoodCheckInEntry(time: dateWithHour(8, dayOffset: -1)!, score: 0.3, colorHex: "A9A9A9"),
                    MoodCheckInEntry(time: dateWithHour(19, dayOffset: -1)!, score: 0.35, colorHex: "A9A9A9")
                ],
                // Fri: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(11, dayOffset: 0)!, score: 0.5, colorHex: "C3B1E1")
                ]
            ]
        } else {
            // ── Week B: mixed week, more negative scores ──
            weekData = [
                // Sat: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(11, dayOffset: -6)!, score: -0.3, colorHex: "6495ED")
                ],
                // Sun: 2 check-ins
                [
                    MoodCheckInEntry(time: dateWithHour(10, dayOffset: -5)!, score: 0.6, colorHex: "77DD77"),
                    MoodCheckInEntry(time: dateWithHour(21, dayOffset: -5)!, score: -0.7, colorHex: "FF6961")
                ],
                // Mon: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(8, dayOffset: -4)!, score: -0.4, colorHex: "AEC6CF")
                ],
                // Tue: 3 check-ins (busy day)
                [
                    MoodCheckInEntry(time: dateWithHour(7, dayOffset: -3)!, score: 0.2, colorHex: "FDFD96"),
                    MoodCheckInEntry(time: dateWithHour(14, dayOffset: -3)!, score: -0.6, colorHex: "CB99C9"),
                    MoodCheckInEntry(time: dateWithHour(23, dayOffset: -3)!, score: -0.8, colorHex: "FF6961")
                ],
                // Wed: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(16, dayOffset: -2)!, score: 0.1, colorHex: "B19CD9")
                ],
                // Thu: 1 check-in
                [
                    MoodCheckInEntry(time: dateWithHour(9, dayOffset: -1)!, score: -0.5, colorHex: "FFB347")
                ],
                // Fri: 2 check-ins
                [
                    MoodCheckInEntry(time: dateWithHour(12, dayOffset: 0)!, score: 0.3, colorHex: "87CEEB"),
                    MoodCheckInEntry(time: dateWithHour(20, dayOffset: 0)!, score: 0.8, colorHex: "77DD77")
                ]
            ]
        }

        let dailyScores = weekData.enumerated().compactMap { (index, entries) -> DailyMoodScore? in
            guard let date = calendar.date(byAdding: .day, value: index - 6, to: referenceDate) else { return nil }
            return DailyMoodScore(date: date, entries: entries)
        }

        return WeeklyMoodScoreViewModel(
            title: NSLocalizedString("insight_weekly_mood_score_title", comment: ""),
            dailyScores: dailyScores
        )
    }
}
