//
//  QuestViewPresenter.swift
//

import Foundation

protocol QuestViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: QuestViewModel)
    func didUpdateSection(at index: IndexSet)
}

protocol QuestViewPresenterType: AnyObject {
    var delegate: QuestViewPresenterDelegate? { get set }
    func fetchData(isUpdate: Bool)
    func numberOfSectionsOnTableView() -> Int
}

class QuestViewPresenter: QuestViewPresenterType {
    weak var delegate: QuestViewPresenterDelegate?
    var loadedModel: QuestViewModel = QuestViewModel(isLoading: false) {
        didSet {
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }
    private var isFetchingData: Bool = false
    private var dataAccessQueue = DispatchQueue(label: "wall_data", attributes: .concurrent)
    init() {}
    public func fetchData(isUpdate: Bool = false) {
        if isFetchingData { return }
        if !isUpdate { loadedModel.isLoading = true }
        isFetchingData = true
        
        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.loadMockData()
        }
    }
    
    private func loadMockData() {
        // Mock radar chart data - 8 metrics for octagonal chart with 5-point scale
        let radarMetrics = [
            RadarChartMetric(label: NSLocalizedString("Energy", comment: ""), value: 3.8, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Focus", comment: ""), value: 3.4, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Creativity", comment: ""), value: 4.1, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Balance", comment: ""), value: 3.6, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Growth", comment: ""), value: 4.5, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Connection", comment: ""), value: 3.2, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Peace", comment: ""), value: 3.9, maxValue: 5.0),
            RadarChartMetric(label: NSLocalizedString("Purpose", comment: ""), value: 4.2, maxValue: 5.0)
        ]
        let radarData = QuestRadarData(title: NSLocalizedString("Wellness Radar Chart", comment: ""), metrics: radarMetrics)
        
        // Mock line chart data - Life stages progression
        // User is currently at Teenager stage (stage 2, 0-indexed)
        let linePoints = [
            StageProgressPoint(stage: 0, value: 100, date: Date().addingTimeInterval(-4*24*60*60)), // Baby - Completed
            StageProgressPoint(stage: 1, value: 100, date: Date().addingTimeInterval(-3*24*60*60)), // Child - Completed
            StageProgressPoint(stage: 2, value: 65, date: Date().addingTimeInterval(-2*24*60*60)),  // Teenager - Current (65% progress)
            StageProgressPoint(stage: 3, value: 0, date: Date().addingTimeInterval(-1*24*60*60)),   // Adult - Future
            StageProgressPoint(stage: 4, value: 0, date: Date())                                    // Elder - Future
        ]
        let lineData = QuestLineData(title: NSLocalizedString("Journey Progress Timeline", comment: ""), points: linePoints)
        
        // Update loaded model
        dataAccessQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            self.loadedModel = QuestViewModel(
                isLoading: false,
                radarChartData: radarData,
                lineChartData: lineData
            )
            self.isFetchingData = false
        }
    }
    public func numberOfSectionsOnTableView() -> Int {
        return 2 // One section for radar chart, one for line chart
    }
} 