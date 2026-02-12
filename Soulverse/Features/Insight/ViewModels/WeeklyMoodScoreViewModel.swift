import Foundation

struct DailyMoodScore {
    let date: Date
    let score: Double        // -1.0 to 1.0
    let colorHex: String     // dot color from mood entry
}

struct WeeklyMoodScoreViewModel {
    let title: String
    let sentimentLabel: String
    let description: String
    let trendValue: Double
    let trendDirection: TrendDirection
    let dailyScores: [DailyMoodScore]

    enum TrendDirection {
        case up, down, neutral

        var symbol: String {
            switch self {
            case .up: return "↑"
            case .down: return "↓"
            case .neutral: return "→"
            }
        }
    }
}

// MARK: - Mock Data

extension WeeklyMoodScoreViewModel {
    static func mockData() -> WeeklyMoodScoreViewModel {
        let calendar = Calendar.current
        let today = Date()

        let mockScores: [(dayOffset: Int, score: Double, colorHex: String)] = [
            (-6, 0.3, "FFD700"),
            (-5, -0.2, "6495ED"),
            (-4, 0.7, "FF6347"),
            (-3, 0.5, "32CD32"),
            (-2, -0.4, "9370DB"),
            (-1, 0.8, "FF69B4"),
            (0, 0.6, "FFA500")
        ]

        let dailyScores = mockScores.compactMap { entry -> DailyMoodScore? in
            guard let date = calendar.date(byAdding: .day, value: entry.dayOffset, to: today) else {
                return nil
            }
            return DailyMoodScore(date: date, score: entry.score, colorHex: entry.colorHex)
        }

        return WeeklyMoodScoreViewModel(
            title: NSLocalizedString("insight_weekly_mood_score_title", comment: ""),
            sentimentLabel: NSLocalizedString("insight_sentiment_positive", comment: ""),
            description: NSLocalizedString("insight_weekly_mood_score_description", comment: ""),
            trendValue: 0.45,
            trendDirection: .up,
            dailyScores: dailyScores
        )
    }
}
