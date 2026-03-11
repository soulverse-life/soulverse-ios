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
}