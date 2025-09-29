//
//  QuestViewModel.swift
//

import Foundation

// MARK: - Radar Chart Data Models
struct RadarChartMetric {
    let label: String
    let value: Double
    let maxValue: Double
    
    var normalizedValue: Double {
        return min(value / maxValue, 1.0)
    }
}

struct QuestRadarData {
    let metrics: [RadarChartMetric]
    let title: String
    
    init(title: String, metrics: [RadarChartMetric]) {
        self.title = title
        self.metrics = metrics
    }
}

// MARK: - Line Chart Data Models  
struct StageProgressPoint {
    let stage: Int
    let value: Double
    let date: Date
}

struct QuestLineData {
    let points: [StageProgressPoint]
    let title: String
    let maxStage: Int
    
    init(title: String, points: [StageProgressPoint]) {
        self.title = title
        self.points = points.sorted { $0.stage < $1.stage }
        self.maxStage = points.map { $0.stage }.max() ?? 0
    }
}

// MARK: - Main ViewModel
struct QuestViewModel {
    var isLoading: Bool
    var radarChartData: QuestRadarData?
    var lineChartData: QuestLineData?
    
    init(isLoading: Bool = false, radarChartData: QuestRadarData? = nil, lineChartData: QuestLineData? = nil) {
        self.isLoading = isLoading
        self.radarChartData = radarChartData
        self.lineChartData = lineChartData
    }
} 