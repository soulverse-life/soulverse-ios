//
//  QuestRadarChartView.swift
//

import UIKit
import DGCharts
import SnapKit

protocol QuestRadarChartViewDelegate: AnyObject {
    func radarChartDidUpdate(_ chartView: QuestRadarChartView)
}

class QuestRadarChartView: UIView {
    
    // MARK: - Properties
    weak var delegate: QuestRadarChartViewDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: 18, weight: .semibold)
        label.textColor = .primaryBlack
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var radarChartView: RadarChartView = {
        let chartView = RadarChartView()
        chartView.delegate = self
        
        // Chart configuration
        chartView.webLineWidth = 1.0
        chartView.innerWebLineWidth = 0.5
        chartView.webColor = UIColor.black.withAlphaComponent(0.3)
        chartView.innerWebColor = UIColor.black.withAlphaComponent(0.2)
        chartView.webAlpha = 1.0
        
        // Remove descriptions and legends
        chartView.chartDescription.enabled = false
        chartView.legend.enabled = false
        
        // Disable interactions for cleaner UI
        chartView.isUserInteractionEnabled = false
        
        // Y-axis configuration - 5 grid levels (0,1,2,3,4,5)
        let yAxis = chartView.yAxis
        yAxis.labelCount = 6  // 6 labels for 5 intervals (0,1,2,3,4,5)
        yAxis.axisMinimum = 0.0
        yAxis.axisMaximum = 5.0
        yAxis.drawLabelsEnabled = true
        yAxis.labelTextColor = UIColor.primaryBlack.withAlphaComponent(0.7)
        yAxis.labelFont = UIFont.projectFont(ofSize: 10, weight: .medium)
        yAxis.drawAxisLineEnabled = false
        yAxis.drawGridLinesEnabled = true
        yAxis.gridColor = UIColor.black.withAlphaComponent(0.3)
        yAxis.granularity = 1.0
        
        // X-axis configuration
        let xAxis = chartView.xAxis
        xAxis.labelFont = UIFont.projectFont(ofSize: 12, weight: .medium)
        xAxis.labelTextColor = .primaryBlack
        xAxis.drawAxisLineEnabled = false
        xAxis.drawGridLinesEnabled = false
        
        return chartView
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        
        addSubview(titleLabel)
        addSubview(radarChartView)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(24)
        }
        
        radarChartView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(16)
            make.height.equalTo(radarChartView.snp.width)
        }
    }
    
    // MARK: - Public Methods
    func configure(with data: QuestRadarData) {
        titleLabel.text = data.title
        updateChartData(data)
    }
    
    private func updateChartData(_ data: QuestRadarData) {
        let entries = data.metrics.enumerated().map { (index, metric) in
            // Convert to 0-5 scale instead of normalized 0-1
            RadarChartDataEntry(value: metric.value / metric.maxValue * 5.0)
        }
        
        let dataSet = RadarChartDataSet(entries: entries, label: "")
        
        // Styling the radar chart
        dataSet.colors = [UIColor.systemBlue.withAlphaComponent(0.8)]
        dataSet.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
        dataSet.drawFilledEnabled = true
        dataSet.fillAlpha = 0.3
        dataSet.lineWidth = 2.0
        dataSet.drawHighlightCircleEnabled = true
        dataSet.highlightEnabled = false
        dataSet.drawValuesEnabled = false
        
        // Create initial dataset with all values at 0 (center)
        let initialEntries = data.metrics.enumerated().map { (index, metric) in
            RadarChartDataEntry(value: 0.0) // Start from center
        }
        let initialDataSet = RadarChartDataSet(entries: initialEntries, label: "")
        
        // Apply same styling to initial dataset
        initialDataSet.colors = [UIColor.systemBlue.withAlphaComponent(0.8)]
        initialDataSet.fillColor = UIColor.systemBlue.withAlphaComponent(0.3)
        initialDataSet.drawFilledEnabled = true
        initialDataSet.fillAlpha = 0.3
        initialDataSet.lineWidth = 2.0
        initialDataSet.drawHighlightCircleEnabled = true
        initialDataSet.highlightEnabled = false
        initialDataSet.drawValuesEnabled = false
        
        // Set initial data (all at center)
        let initialChartData = RadarChartData(dataSets: [initialDataSet])
        radarChartView.data = initialChartData
        
        // Set x-axis labels
        let labels = data.metrics.map { $0.label }
        radarChartView.xAxis.valueFormatter = RadarAxisValueFormatter(labels: labels)
        
        // Update to final values with animation - spreads from center outward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            let finalChartData = RadarChartData(dataSets: [dataSet])
            self?.radarChartView.data = finalChartData
            
            // Animate the spread from center to final values
            self?.radarChartView.animate(yAxisDuration: 1.0, easingOption: .easeOutQuint)
        }
        
        radarChartView.notifyDataSetChanged()
        delegate?.radarChartDidUpdate(self)
    }
}

// MARK: - ChartViewDelegate
extension QuestRadarChartView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        // Handle selection if needed
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        // Handle deselection if needed
    }
}

// MARK: - Custom Axis Value Formatter
private class RadarAxisValueFormatter: NSObject, AxisValueFormatter {
    private let labels: [String]
    
    init(labels: [String]) {
        self.labels = labels
        super.init()
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let index = Int(value)
        if index >= 0 && index < labels.count {
            return labels[index]
        }
        return ""
    }
}
