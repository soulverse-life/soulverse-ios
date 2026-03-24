import UIKit
import DGCharts
import SnapKit

// MARK: - Delegate Protocol

protocol WeeklyMoodScoreViewDelegate: AnyObject {
    func weeklyMoodScoreView(_ view: WeeklyMoodScoreView, didSwipeToPage pageIndex: Int)
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
        static let scatterPointSize: CGFloat = 12
        static let axisLineWidth: CGFloat = 2
        static let zeroLineWidth: CGFloat = 2
        static let zeroLineAlpha: CGFloat = 0.4
        static let timeLabelFontSize: CGFloat = 10
        static let timeLabelOffsetX: CGFloat = 10
        static let dashedLineWidth: CGFloat = 1.5
        static let dashedLineDashLength: CGFloat = 6
        static let dashedLineGapLength: CGFloat = 4
        static let weekdayRowHeight: CGFloat = 16
        static let weekdayLabelFontSize: CGFloat = 10
        static let weekdayDateFontSize: CGFloat = 10
        static let weekdayLabelTopSpacing: CGFloat = 4
        static let dateNumberRowTopSpacing: CGFloat = 2
        static let daysPerWeek = 7
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

    private var lastLayoutBounds: CGRect = .zero
    private var entriesByIndex: [Int: [MoodCheckInEntry]] = [:]
    private var selectedColumnIndex: Int = -1
    private var dashedLineLayer: CAShapeLayer?
    private var timeLabelViews: [UILabel] = []
    private var dayAbbrLabels: [UILabel] = []

    /// Pixel x-positions for 7 columns, computed from chart transformer.
    private var columnXPositions: [CGFloat] = []

    /// Page start dates received from ViewModel.
    private var weekStartDates: [Date] = []

    /// Index of the currently visible page.
    private var currentPageIndex: Int = 0

    /// Suppresses delegate calls during programmatic scroll
    private var isSuppressingPageChange = false

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

        chartView.rightAxis.enabled = false

        chartView.clipDataToContentEnabled = false

        let yAxis = chartView.leftAxis
        yAxis.axisMinimum = -1.15
        yAxis.axisMaximum = 1.15
        yAxis.labelCount = 3
        yAxis.granularity = 1.0
        yAxis.forceLabelsEnabled = false
        yAxis.labelTextColor = .themeTextSecondary
        yAxis.labelFont = UIFont.projectFont(ofSize: Layout.axisLabelFontSize, weight: .regular, scalable: false)
        yAxis.drawGridLinesEnabled = false
        yAxis.drawAxisLineEnabled = true
        yAxis.axisLineColor = UIColor.themeTextSecondary.withAlphaComponent(Layout.zeroLineAlpha)
        yAxis.axisLineWidth = Layout.axisLineWidth
        yAxis.valueFormatter = MoodScoreYAxisFormatter()

        let zeroLine = ChartLimitLine(limit: 0)
        zeroLine.lineWidth = Layout.zeroLineWidth
        zeroLine.lineColor = UIColor.themeTextSecondary.withAlphaComponent(Layout.zeroLineAlpha)
        yAxis.addLimitLine(zeroLine)

        let xAxis = chartView.xAxis
        xAxis.labelPosition = .bottom
        xAxis.drawLabelsEnabled = false
        xAxis.drawGridLinesEnabled = false
        xAxis.drawAxisLineEnabled = false
        xAxis.granularity = 1

        return chartView
    }()

    private lazy var dayAbbrRow: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var dateNumberCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(DateWeekCell.self, forCellWithReuseIdentifier: DateWeekCell.reuseID)
        return cv
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
        baseView.addSubview(dateNumberCollectionView)

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
            make.height.equalTo(Layout.weekdayRowHeight)
        }

        dateNumberCollectionView.snp.makeConstraints { make in
            make.top.equalTo(dayAbbrRow.snp.bottom).offset(Layout.dateNumberRowTopSpacing)
            make.left.right.equalTo(scatterChartView)
            make.height.equalTo(Layout.weekdayRowHeight)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: WeeklyMoodScoreViewModel) {
        titleLabel.text = viewModel.title

        guard !viewModel.dailyScores.isEmpty else { return }

        dateNumberCollectionView.isScrollEnabled = viewModel.isSwipeEnabled

        // Update page data if changed
        let pagesChanged = (weekStartDates != viewModel.weekStartDates)
        weekStartDates = viewModel.weekStartDates
        currentPageIndex = viewModel.currentPageIndex

        if pagesChanged {
            dateNumberCollectionView.reloadData()

            // Scroll to current page without triggering delegate
            DispatchQueue.main.async { [weak self] in
                guard let self, !self.weekStartDates.isEmpty else { return }
                self.isSuppressingPageChange = true
                let indexPath = IndexPath(item: self.currentPageIndex, section: 0)
                self.dateNumberCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                self.isSuppressingPageChange = false
            }
        }

        updateChart(with: viewModel.dailyScores)
    }

    // MARK: - Helpers

    /// Returns 7 day dates for the week starting at the given date.
    private func datesForWeek(startingAt startDate: Date) -> [Date] {
        let calendar = Calendar.current
        return (0..<Layout.daysPerWeek).compactMap {
            calendar.date(byAdding: .day, value: $0, to: startDate)
        }
    }

    // MARK: - Chart

    private func updateChart(with dailyScores: [DailyMoodScore]) {
        clearSelectionOverlay()
        updateDayAbbrLabels(from: dailyScores)
        applyChartData(with: dailyScores)
        scatterChartView.animate(yAxisDuration: 0.8, easingOption: .easeOutQuint)
    }

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

    // MARK: - Day Abbreviation Labels

    /// Updates weekday labels based on the dates in dailyScores.
    private func updateDayAbbrLabels(from dailyScores: [DailyMoodScore]) {
        let calendar = Calendar.current
        let daySymbols = calendar.shortWeekdaySymbols

        // Derive weekday abbreviations from actual dates
        let orderedSymbols = dailyScores.map { dailyScore -> String in
            let weekdayIndex = calendar.component(.weekday, from: dailyScore.date) - 1  // 0-based
            return daySymbols[weekdayIndex]
        }

        if dayAbbrLabels.isEmpty {
            for symbol in orderedSymbols {
                let label = UILabel()
                label.text = symbol
                label.textAlignment = .center
                label.font = UIFont.projectFont(ofSize: Layout.weekdayLabelFontSize, weight: .regular, scalable: false)
                label.textColor = .themeTextSecondary
                dayAbbrRow.addSubview(label)
                dayAbbrLabels.append(label)
            }
        } else {
            for (index, symbol) in orderedSymbols.enumerated() where index < dayAbbrLabels.count {
                dayAbbrLabels[index].text = symbol
            }
        }
    }

    private func repositionDayAbbrLabels() {
        repositionLabelsToChart(dayAbbrLabels)
    }

    // MARK: - Column Positions

    private func updateColumnXPositions() {
        let transformer = scatterChartView.getTransformer(forAxis: .left)
        var positions: [CGFloat] = []
        for i in 0..<Layout.daysPerWeek {
            var point = CGPoint(x: Double(i), y: 0)
            transformer.pointValueToPixel(&point)
            positions.append(point.x)
        }
        columnXPositions = positions

        dateNumberCollectionView.visibleCells.forEach { cell in
            (cell as? DateWeekCell)?.updateLabelPositions(columnXPositions)
        }
    }

    private func repositionLabelsToChart(_ labels: [UILabel]) {
        guard !labels.isEmpty, !columnXPositions.isEmpty else { return }
        for (index, label) in labels.enumerated() where index < columnXPositions.count {
            let xOffset = columnXPositions[index]
            label.snp.remakeConstraints { make in
                make.centerX.equalTo(scatterChartView.snp.left).offset(xOffset)
                make.top.bottom.equalToSuperview()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds != lastLayoutBounds else { return }
        lastLayoutBounds = bounds
        updateColumnXPositions()
        repositionDayAbbrLabels()
    }

    // MARK: - Tap Selection Overlay

    private func showSelectionOverlay(forColumnIndex columnIndex: Int) {
        clearSelectionOverlay()
        selectedColumnIndex = columnIndex

        guard let entries = entriesByIndex[columnIndex], !entries.isEmpty else { return }

        let xPixel = pixelXForIndex(columnIndex)

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

        let timeFormatter = Self.timeFormatter

        for entry in entries {
            let yPixel = pixelYForScore(entry.score)

            let timeLabel = UILabel()
            timeLabel.text = timeFormatter.string(from: entry.time)
            timeLabel.font = UIFont.projectFont(ofSize: Layout.timeLabelFontSize, weight: .medium, scalable: false)
            timeLabel.textColor = .themeTextPrimary
            timeLabel.sizeToFit()

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

// MARK: - UICollectionViewDataSource

extension WeeklyMoodScoreView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weekStartDates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateWeekCell.reuseID, for: indexPath) as! DateWeekCell
        let weekDates = datesForWeek(startingAt: weekStartDates[indexPath.item])
        let dateStrings = weekDates.map { Self.dateNumberFormatter.string(from: $0) }
        cell.configure(dateStrings: dateStrings, xPositions: columnXPositions)
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension WeeklyMoodScoreView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView === dateNumberCollectionView, !isSuppressingPageChange else { return }
        handlePageChange()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView === dateNumberCollectionView, !decelerate, !isSuppressingPageChange else { return }
        handlePageChange()
    }

    private func handlePageChange() {
        let pageWidth = dateNumberCollectionView.bounds.width
        guard pageWidth > 0 else { return }

        let newPage = Int(round(dateNumberCollectionView.contentOffset.x / pageWidth))
        guard newPage >= 0, newPage < weekStartDates.count, newPage != currentPageIndex else { return }

        currentPageIndex = newPage
        clearSelectionOverlay()

        delegate?.weeklyMoodScoreView(self, didSwipeToPage: newPage)
    }
}

// MARK: - ChartViewDelegate

extension WeeklyMoodScoreView: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let columnIndex = Int(round(entry.x))
        guard columnIndex >= 0, columnIndex < (entriesByIndex.count) else { return }

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

// MARK: - DateWeekCell

private final class DateWeekCell: UICollectionViewCell {
    static let reuseID = "DateWeekCell"
    private static let labelFontSize: CGFloat = 10

    private var labels: [UILabel] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        for _ in 0..<7 {
            let label = UILabel()
            label.textAlignment = .center
            label.font = UIFont.projectFont(ofSize: Self.labelFontSize, weight: .regular, scalable: false)
            label.textColor = .themeTextSecondary
            contentView.addSubview(label)
            labels.append(label)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(dateStrings: [String], xPositions: [CGFloat]) {
        for (index, label) in labels.enumerated() {
            label.text = index < dateStrings.count ? dateStrings[index] : ""
        }
        updateLabelPositions(xPositions)
    }

    func updateLabelPositions(_ xPositions: [CGFloat]) {
        guard !xPositions.isEmpty else {
            let count = CGFloat(labels.count)
            for (index, label) in labels.enumerated() {
                let fraction = (CGFloat(index) + 0.5) / count
                label.snp.remakeConstraints { make in
                    make.centerX.equalTo(contentView.snp.left).offset(contentView.bounds.width * fraction)
                    make.top.bottom.equalToSuperview()
                }
            }
            return
        }

        for (index, label) in labels.enumerated() where index < xPositions.count {
            label.snp.remakeConstraints { make in
                make.centerX.equalTo(contentView.snp.left).offset(xPositions[index])
                make.top.bottom.equalToSuperview()
            }
        }
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
