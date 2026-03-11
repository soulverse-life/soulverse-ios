import UIKit
import DGCharts
import SnapKit

// MARK: - Delegate Protocol

protocol WeeklyMoodScoreViewDelegate: AnyObject {
    func weeklyMoodScoreView(_ view: WeeklyMoodScoreView, didSwipeToWeekContaining date: Date)
}

class WeeklyMoodScoreView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let axisLabelFontSize: CGFloat = 10
        static let titleBottomSpacing: CGFloat = 16
        static let chartHeight: CGFloat = 200
        static let scatterPointSize: CGFloat = 15
        static let axisLineWidth: CGFloat = 2
        static let zeroLineWidth: CGFloat = 2
        static let zeroLineAlpha: CGFloat = 0.4
        static let timeLabelFontSize: CGFloat = 10
        static let timeLabelOffsetX: CGFloat = 10
        static let dashedLineWidth: CGFloat = 1.5
        static let dashedLineDashLength: CGFloat = 6
        static let dashedLineGapLength: CGFloat = 4
        static let weekdayAreaHeight: CGFloat = 34
        static let dayAbbrRowHeight: CGFloat = 16
        static let dateNumberRowHeight: CGFloat = 16
        static let weekdayLabelFontSize: CGFloat = 10
        static let weekdayDateFontSize: CGFloat = 10
        static let weekdayLabelTopSpacing: CGFloat = 4
        static let dateNumberTopSpacing: CGFloat = 2
    }

    // MARK: - Formatters

    private static let dateNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    // MARK: - Properties

    weak var delegate: WeeklyMoodScoreViewDelegate?

    /// Tracks the last laid-out bounds to avoid redundant repositioning
    private var lastLayoutBounds: CGRect = .zero

    /// Mapping of x-index to entries for tap lookup
    private var entriesByIndex: [Int: [MoodCheckInEntry]] = [:]

    /// Currently selected column index (-1 = none)
    private var selectedColumnIndex: Int = -1

    /// Current week reference date for swipe navigation
    private var currentReferenceDate: Date = Date()

    /// Overlay layer for dashed line
    private var dashedLineLayer: CAShapeLayer?

    /// Time label views shown on tap
    private var timeLabelViews: [UILabel] = []

    /// Fixed day abbreviation labels (Sat, Sun, Mon...) — created once
    private var dayAbbrLabels: [UILabel] = []

    /// Date number labels (20, 21, 22...) — animated on swipe
    private var dateNumberLabels: [UILabel] = []


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

    private lazy var scatterChartView: ScatterChartView = {
        let chartView = ScatterChartView()
        chartView.chartDescription.enabled = false
        chartView.legend.enabled = false
        chartView.isUserInteractionEnabled = true
        chartView.highlightPerTapEnabled = true
        chartView.setScaleEnabled(false)
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        chartView.clipValuesToContentEnabled = false
        chartView.delegate = self

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

        // X-axis — labels disabled, we use a custom weekday label view
        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawLabelsEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = 1

        return chartView
    }()

    /// Fixed row for day abbreviations (Sat, Sun, Mon...)
    private lazy var dayAbbrRow: UIView = {
        let view = UIView()
        return view
    }()

    /// Container for date number labels
    private lazy var dateNumberContainer: UIView = {
        let view = UIView()
        return view
    }()

    /// Inner view holding date number labels, animated on swipe
    private lazy var dateNumberRow: UIView = {
        let view = UIView()
        return view
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
        baseView.addSubview(scatterChartView)
        baseView.addSubview(dayAbbrRow)
        dateNumberContainer.addSubview(dateNumberRow)
        baseView.addSubview(dateNumberContainer)

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
        setupSwipeGestures()
    }

    private func setupConstraints() {
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        scatterChartView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.height.equalTo(Layout.chartHeight)
        }

        dayAbbrRow.snp.makeConstraints { make in
            make.top.equalTo(scatterChartView.snp.bottom).offset(Layout.weekdayLabelTopSpacing)
            make.left.right.equalTo(scatterChartView)
            make.height.equalTo(Layout.dayAbbrRowHeight)
        }

        dateNumberContainer.snp.makeConstraints { make in
            make.top.equalTo(dayAbbrRow.snp.bottom).offset(Layout.dateNumberTopSpacing)
            make.left.right.equalTo(scatterChartView)
            make.height.equalTo(Layout.dateNumberRowHeight)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }

        dateNumberRow.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupSwipeGestures() {
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        dateNumberContainer.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        dateNumberContainer.addGestureRecognizer(swipeRight)
    }

    // MARK: - Swipe Handling

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        let calendar = Calendar.current
        let offset = gesture.direction == .left ? 7 : -7

        guard let newDate = calendar.date(byAdding: .day, value: offset, to: currentReferenceDate) else { return }
        currentReferenceDate = newDate
        clearSelectionOverlay()
        delegate?.weeklyMoodScoreView(self, didSwipeToWeekContaining: newDate)
    }

    // MARK: - Configuration

    func configure(with viewModel: WeeklyMoodScoreViewModel) {
        titleLabel.text = viewModel.title
        updateChart(with: viewModel.dailyScores)
    }

    func setReferenceDate(_ date: Date) {
        currentReferenceDate = date
    }

    // MARK: - Chart

    private func updateChart(with dailyScores: [DailyMoodScore]) {
        clearSelectionOverlay()
        setupDayAbbrLabels(count: dailyScores.count)
        applyChartData(with: dailyScores)
        scatterChartView.animate(yAxisDuration: 0.8, easingOption: .easeOutQuint)
        updateDateNumberLabels(with: dailyScores)
    }

    /// Builds and sets chart data without animation
    private func applyChartData(with dailyScores: [DailyMoodScore]) {
        entriesByIndex.removeAll()
        var dataSets: [ScatterChartDataSet] = []

        for (dayIndex, dailyScore) in dailyScores.enumerated() {
            entriesByIndex[dayIndex] = dailyScore.entries

            for entry in dailyScore.entries {
                let chartEntry = ChartDataEntry(x: Double(dayIndex), y: entry.score)
                let dataSet = ScatterChartDataSet(entries: [chartEntry], label: "")
                dataSet.setScatterShape(ScatterChartDataSet.Shape.circle)
                dataSet.scatterShapeSize = Layout.scatterPointSize

                if let color = UIColor(hex: entry.colorHex) {
                    dataSet.setColor(color)
                } else {
                    dataSet.setColor(UIColor.themeTextPrimary)
                }

                dataSet.drawValuesEnabled = false
                dataSet.highlightEnabled = true
                dataSets.append(dataSet)
            }
        }

        scatterChartView.xAxis.axisMinimum = -0.5
        scatterChartView.xAxis.axisMaximum = Double(dailyScores.count) - 0.5
        scatterChartView.xAxis.labelCount = dailyScores.count

        let chartData = ScatterChartData(dataSets: dataSets)
        scatterChartView.data = chartData
    }

    // MARK: - Day Abbreviation Labels (Fixed)

    /// Creates the fixed day abbreviation labels once. These don't change on swipe.
    private func setupDayAbbrLabels(count: Int) {
        guard dayAbbrLabels.isEmpty else { return }

        let daySymbols = Calendar.current.shortWeekdaySymbols
        // Build the 7-day order starting from Saturday (index 6 in Calendar)
        let saturdayIndex = 6
        let orderedSymbols = (0..<count).map { daySymbols[(saturdayIndex + $0) % 7] }

        for symbol in orderedSymbols {
            let label = UILabel()
            label.text = symbol
            label.textAlignment = .center
            label.font = UIFont.projectFont(ofSize: Layout.weekdayLabelFontSize, weight: .regular, scalable: false)
            label.textColor = .themeTextSecondary
            dayAbbrRow.addSubview(label)
            dayAbbrLabels.append(label)
        }
    }

    private func repositionDayAbbrLabels() {
        repositionLabels(dayAbbrLabels, in: dayAbbrRow)
    }

    // MARK: - Date Number Labels (Updated on Swipe)

    /// Creates date number labels once, then reuses them on subsequent updates.
    private func updateDateNumberLabels(with dailyScores: [DailyMoodScore]) {
        let formatter = Self.dateNumberFormatter

        if dateNumberLabels.isEmpty {
            // First call — create labels
            for dailyScore in dailyScores {
                let label = UILabel()
                label.text = formatter.string(from: dailyScore.date)
                label.textAlignment = .center
                label.font = UIFont.projectFont(ofSize: Layout.weekdayDateFontSize, weight: .regular, scalable: false)
                label.textColor = .themeTextSecondary
                dateNumberRow.addSubview(label)
                dateNumberLabels.append(label)
            }
        } else {
            // Subsequent calls — reuse labels, update text only
            for (index, dailyScore) in dailyScores.enumerated() where index < dateNumberLabels.count {
                dateNumberLabels[index].text = formatter.string(from: dailyScore.date)
            }
        }

        repositionLabels(dateNumberLabels, in: dateNumberRow)
    }

    private func repositionDateNumberLabels() {
        repositionLabels(dateNumberLabels, in: dateNumberRow)
    }

    /// Shared helper to align labels to chart x-coordinates within a container row.
    private func repositionLabels(_ labels: [UILabel], in row: UIView) {
        guard !labels.isEmpty else { return }
        let transformer = scatterChartView.getTransformer(forAxis: .left)
        let containerOriginX = scatterChartView.frame.origin.x - row.superview!.frame.origin.x
        for (index, label) in labels.enumerated() {
            var point = CGPoint(x: Double(index), y: 0)
            transformer.pointValueToPixel(&point)
            label.snp.remakeConstraints { make in
                make.centerX.equalTo(row.snp.left).offset(containerOriginX + point.x)
                make.top.bottom.equalToSuperview()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != lastLayoutBounds else { return }
        lastLayoutBounds = bounds
        repositionDayAbbrLabels()
        repositionDateNumberLabels()
    }

    // MARK: - Tap Selection Overlay

    private func showSelectionOverlay(forColumnIndex columnIndex: Int) {
        clearSelectionOverlay()
        selectedColumnIndex = columnIndex

        guard let entries = entriesByIndex[columnIndex], !entries.isEmpty else { return }

        let xPixel = pixelXForIndex(columnIndex)

        // Draw dashed vertical line
        let lineLayer = CAShapeLayer()
        let path = UIBezierPath()

        let chartContentTop = scatterChartView.viewPortHandler.contentTop
        let chartContentBottom = scatterChartView.viewPortHandler.contentBottom

        path.move(to: CGPoint(x: xPixel, y: chartContentTop))
        path.addLine(to: CGPoint(x: xPixel, y: chartContentBottom))

        lineLayer.path = path.cgPath
        lineLayer.strokeColor = UIColor.themeTextSecondary.withAlphaComponent(0.6).cgColor
        lineLayer.lineWidth = Layout.dashedLineWidth
        lineLayer.lineDashPattern = [
            NSNumber(value: Float(Layout.dashedLineDashLength)),
            NSNumber(value: Float(Layout.dashedLineGapLength))
        ]
        lineLayer.fillColor = nil
        scatterChartView.layer.addSublayer(lineLayer)
        dashedLineLayer = lineLayer

        // Add time labels for each entry
        let timeFormatter = Self.timeFormatter

        for entry in entries {
            let yPixel = pixelYForScore(entry.score)

            let timeLabel = UILabel()
            timeLabel.text = timeFormatter.string(from: entry.time)
            timeLabel.font = UIFont.projectFont(ofSize: Layout.timeLabelFontSize, weight: .medium, scalable: false)
            timeLabel.textColor = .themeTextPrimary
            timeLabel.sizeToFit()

            // Position to the right of the dot; if it would go off-screen, put it on the left
            let labelX: CGFloat
            let rightEdge = xPixel + Layout.timeLabelOffsetX + timeLabel.bounds.width
            if rightEdge > scatterChartView.bounds.width - Layout.cardPadding {
                labelX = xPixel - Layout.timeLabelOffsetX - timeLabel.bounds.width
            } else {
                labelX = xPixel + Layout.timeLabelOffsetX
            }

            timeLabel.frame = CGRect(
                x: labelX,
                y: yPixel - timeLabel.bounds.height / 2,
                width: timeLabel.bounds.width,
                height: timeLabel.bounds.height
            )

            scatterChartView.addSubview(timeLabel)
            timeLabelViews.append(timeLabel)
        }
    }

    private func clearSelectionOverlay() {
        dashedLineLayer?.removeFromSuperlayer()
        dashedLineLayer = nil
        timeLabelViews.forEach { $0.removeFromSuperview() }
        timeLabelViews.removeAll()
        selectedColumnIndex = -1
        scatterChartView.highlightValues(nil)
    }

    // MARK: - Coordinate Helpers

    private func pixelXForIndex(_ index: Int) -> CGFloat {
        let transformer = scatterChartView.getTransformer(forAxis: .left)
        var point = CGPoint(x: Double(index), y: 0)
        transformer.pointValueToPixel(&point)
        return point.x
    }

    private func pixelYForScore(_ score: Double) -> CGFloat {
        let transformer = scatterChartView.getTransformer(forAxis: .left)
        var point = CGPoint(x: 0, y: score)
        transformer.pointValueToPixel(&point)
        return point.y
    }
}

// MARK: - ChartViewDelegate

extension WeeklyMoodScoreView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let columnIndex = Int(round(entry.x))
        guard columnIndex >= 0, columnIndex < (entriesByIndex.count) else { return }

        // If tapping the same column again, deselect
        if columnIndex == selectedColumnIndex {
            clearSelectionOverlay()
            return
        }

        showSelectionOverlay(forColumnIndex: columnIndex)
    }

    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        clearSelectionOverlay()
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
