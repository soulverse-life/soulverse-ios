import Foundation

struct MoodCheckInEntry {
    let time: Date
    let score: Double       // -1.0 to 1.0
    let colorHex: String    // dot color from mood entry
}

struct DailyMoodScore {
    let date: Date
    let entries: [MoodCheckInEntry]
}

struct WeeklyMoodScoreViewModel {
    let title: String
    let dailyScores: [DailyMoodScore]
    let weekStartDates: [Date]
    let currentPageIndex: Int
    let isSwipeEnabled: Bool
}

// MARK: - Factory from Firestore Data

extension WeeklyMoodScoreViewModel {

    /// Build from real mood check-in data.
    /// Displays 7 days ending at `referenceDate` (defaults to today).
    /// - Parameters:
    ///   - checkIns: Array of MoodCheckInModel from Firestore
    ///   - referenceDate: The end date of the week to display (defaults to today)
    ///   - weekStartDates: Pre-computed array of page start dates
    ///   - currentPageIndex: Index of the currently visible page
    ///   - isSwipeEnabled: Whether week swiping is allowed
    /// - Returns: Populated ViewModel for the scatter chart
    static func from(
        checkIns: [MoodCheckInModel],
        referenceDate: Date = Date(),
        weekStartDates: [Date],
        currentPageIndex: Int,
        isSwipeEnabled: Bool
    ) -> WeeklyMoodScoreViewModel {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: referenceDate)

        var dailyScores: [DailyMoodScore] = []

        for dayOffset in (-6...0) {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { continue }

            let dayCheckIns = checkIns.filter { checkIn in
                guard let createdAt = checkIn.createdAt else { return false }
                return createdAt >= date && createdAt < nextDate
            }

            let entries = dayCheckIns.compactMap { checkIn -> MoodCheckInEntry? in
                guard let createdAt = checkIn.createdAt else { return nil }
                let emotionScore = RecordedEmotion(rawValue: checkIn.emotion)?.score ?? 0.0
                return MoodCheckInEntry(time: createdAt, score: emotionScore, colorHex: checkIn.colorHex)
            }

            dailyScores.append(DailyMoodScore(date: date, entries: entries))
        }

        return WeeklyMoodScoreViewModel(
            title: NSLocalizedString("insight_weekly_mood_score_title", comment: ""),
            dailyScores: dailyScores,
            weekStartDates: weekStartDates,
            currentPageIndex: currentPageIndex,
            isSwipeEnabled: isSwipeEnabled
        )
    }
}
