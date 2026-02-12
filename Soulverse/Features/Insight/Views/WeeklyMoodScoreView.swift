import UIKit
import DGCharts
import SnapKit

class WeeklyMoodScoreView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let sentimentFontSize: CGFloat = 14
        static let descriptionFontSize: CGFloat = 14
        static let trendFontSize: CGFloat = 13
        static let axisLabelFontSize: CGFloat = 10
        static let headerBottomSpacing: CGFloat = 8
        static let descriptionBottomSpacing: CGFloat = 12
        static let trendBottomSpacing: CGFloat = 16
        static let chartHeight: CGFloat = 200
        static let scatterPointSize: CGFloat = 10
        static let axisLineWidth: CGFloat = 2
        static let zeroLineWidth: CGFloat = 2
        static let zeroLineAlpha: CGFloat = 0.4
    }

    // MARK: - Subviews

    private let baseView: UIView = {
        let view = UIView()
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var sentimentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.sentimentFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        return label
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.descriptionFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        return label
    }()

    private lazy var trendLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.trendFontSize, weight: .medium)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var scatterChartView: ScatterChartView = {
        let chartView = ScatterChartView()
        chartView.chartDescription.enabled = false
        chartView.legend.enabled = false
        chartView.isUserInteractionEnabled = false
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false

        // Right axis disabled
        chartView.rightAxis.enabled = false

        // Y-axis
        let yAxis = chartView.leftAxis
        yAxis.axisMinimum = -1.0
        yAxis.axisMaximum = 1.0
        yAxis.labelCount = 2
        yAxis.forceLabelsEnabled = true
        yAxis.labelTextColor = .themeTextSecondary
        yAxis.labelFont = UIFont.projectFont(ofSize: Layout.axisLabelFontSize, weight: .regular, scalable: false)
        yAxis.drawGridLinesEnabled = false
        yAxis.drawAxisLineEnabled = true
        yAxis.axisLineColor = UIColor.themeTextSecondary.withAlphaComponent(Layout.zeroLineAlpha)
        yAxis.axisLineWidth = Layout.axisLineWidth
        yAxis.valueFormatter = MoodScoreYAxisFormatter()

        // Zero line (solid)
        let zeroLine = ChartLimitLine(limit: 0)
        zeroLine.lineWidth = Layout.zeroLineWidth
        zeroLine.lineColor = UIColor.themeTextSecondary.withAlphaComponent(Layout.zeroLineAlpha)
        yAxis.addLimitLine(zeroLine)

        // X-axis (labels only, no axis line)
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.labelTextColor = .themeTextSecondary
        xAxis.labelFont = UIFont.projectFont(ofSize: Layout.axisLabelFontSize, weight: .regular, scalable: false)
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = 1

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
        baseView.addSubview(titleLabel)
        baseView.addSubview(sentimentLabel)
        baseView.addSubview(descriptionLabel)
        baseView.addSubview(trendLabel)
        baseView.addSubview(scatterChartView)

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cardCornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            addSubview(baseView)
            baseView.layer.cornerRadius = Layout.cardCornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .white.withAlphaComponent(0.1)
            baseView.clipsToBounds = true
        }

        setupConstraints()
    }

    private func setupConstraints() {
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.left.equalToSuperview().inset(Layout.cardPadding)
            make.right.lessThanOrEqualTo(sentimentLabel.snp.left).offset(-Layout.headerBottomSpacing)
        }

        sentimentLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.right.equalToSuperview().inset(Layout.cardPadding)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.headerBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        trendLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(Layout.descriptionBottomSpacing)
            make.left.equalToSuperview().inset(Layout.cardPadding)
        }

        scatterChartView.snp.makeConstraints { make in
            make.top.equalTo(trendLabel.snp.bottom).offset(Layout.trendBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.height.equalTo(Layout.chartHeight)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: WeeklyMoodScoreViewModel) {
        titleLabel.text = viewModel.title
        sentimentLabel.text = viewModel.sentimentLabel
        descriptionLabel.text = viewModel.description

        let trendText = String(
            format: "%@ %@ %@",
            NSLocalizedString("insight_last_7_days", comment: ""),
            viewModel.trendDirection.symbol,
            String(format: "%.2f", viewModel.trendValue)
        )
        trendLabel.text = trendText

        updateChart(with: viewModel.dailyScores)
    }

    // MARK: - Chart

    private func updateChart(with dailyScores: [DailyMoodScore]) {
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        let dateNumberFormatter = DateFormatter()
        dateNumberFormatter.dateFormat = "d"

        var xLabels: [String] = []
        var dataSets: [ScatterChartDataSet] = []

        for (index, score) in dailyScores.enumerated() {
            let dayAbbr = dayFormatter.string(from: score.date)
            let dateNum = dateNumberFormatter.string(from: score.date)
            xLabels.append("\(dayAbbr)\n\(dateNum)")

            let entry = ChartDataEntry(x: Double(index), y: score.score)
            let dataSet = ScatterChartDataSet(entries: [entry], label: "")
            dataSet.setScatterShape(ScatterChartDataSet.Shape.circle)
            dataSet.scatterShapeSize = Layout.scatterPointSize

            if let color = UIColor(hex: score.colorHex) {
                dataSet.setColor(color)
            } else {
                dataSet.setColor(UIColor.themeTextPrimary)
            }

            dataSet.drawValuesEnabled = false
            dataSet.highlightEnabled = false
            dataSets.append(dataSet)
        }

        scatterChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values: xLabels)
        scatterChartView.xAxis.labelCount = xLabels.count

        let chartData = ScatterChartData(dataSets: dataSets)
        scatterChartView.data = chartData
        scatterChartView.animate(yAxisDuration: 0.8, easingOption: .easeOutQuint)
    }

}

// MARK: - Y-Axis Formatter

private class MoodScoreYAxisFormatter: NSObject, AxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if value == 1.0 {
            return "1.0"
        } else if value == -1.0 {
            return "-1.0"
        }
        return ""
    }
}
