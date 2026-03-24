//
//  InsightViewModel.swift
//

import Foundation

struct InsightViewModel {
    var isLoading: Bool
    var timeRange: TimeRange = .last7Days
    var weeklyMoodScore: WeeklyMoodScoreViewModel?
    var topicDistribution: TopicDistributionViewModel?
    var habitActivity: HabitActivityViewModel?
    var checkinActivity: CheckinActivityViewModel?
}
