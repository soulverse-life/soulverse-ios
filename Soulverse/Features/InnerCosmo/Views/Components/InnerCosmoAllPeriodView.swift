//
//  InnerCosmoAllPeriodView.swift
//  Soulverse
//
//  Monthly calendar view for the "All" period tab.
//  Displays a swipeable grid of months from Jan 2026 to the current month.
//

import SnapKit
import UIKit

// MARK: - Delegate

protocol InnerCosmoAllPeriodViewDelegate: AnyObject {
    func allPeriodView(_ view: InnerCosmoAllPeriodView, didChangeToMonth year: Int, month: Int)
    func allPeriodView(_ view: InnerCosmoAllPeriodView, didTapDay day: Int, inMonth month: Int, year: Int)
}

// MARK: - InnerCosmoAllPeriodView

class InnerCosmoAllPeriodView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let weekdayHeaderHeight: CGFloat = 32
        static let dayCellSize: CGFloat = 40
        static let rowSpacing: CGFloat = 4
        static let monthLabelHeight: CGFloat = 32
        static let monthLabelFontSize: CGFloat = 17
        static let weekdayFontSize: CGFloat = 13
        static let horizontalPadding: CGFloat = 16

        static var maxGridHeight: CGFloat {
            let rows = CGFloat(CalendarMonthViewModel.maxGridRows)
            return rows * dayCellSize + (rows - 1) * rowSpacing
        }
    }

    // MARK: - Properties

    weak var delegate: InnerCosmoAllPeriodViewDelegate?
    private var months: [CalendarMonthViewModel] = []

    // MARK: - UI Components

    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.monthLabelFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private let weekdayHeaderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(MonthPageCell.self, forCellWithReuseIdentifier: MonthPageCell.reuseIdentifier)
        return cv
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        loadMonths()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear

        addSubview(monthLabel)
        addSubview(weekdayHeaderStack)
        addSubview(collectionView)

        setupWeekdayHeaders()
        setupConstraints()
    }

    private func setupWeekdayHeaders() {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols

        // Reorder starting from the calendar's first weekday
        let startIndex = calendar.firstWeekday - 1
        let ordered = Array(symbols[startIndex...]) + Array(symbols[..<startIndex])

        for symbol in ordered {
            let label = UILabel()
            label.text = symbol
            label.font = .projectFont(ofSize: Layout.weekdayFontSize, weight: .medium)
            label.textColor = .themeTextSecondary
            label.textAlignment = .center
            weekdayHeaderStack.addArrangedSubview(label)
        }
    }

    private func setupConstraints() {
        monthLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            make.height.equalTo(Layout.monthLabelHeight)
        }

        weekdayHeaderStack.snp.makeConstraints { make in
            make.top.equalTo(monthLabel.snp.bottom)
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalPadding)
            make.height.equalTo(Layout.weekdayHeaderHeight)
        }

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(weekdayHeaderStack.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.maxGridHeight)
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Data

    private func loadMonths() {
        months = CalendarMonthViewModel.buildAllMonths()

        collectionView.reloadData()

        // Scroll to the last page (current month) after layout
        DispatchQueue.main.async { [weak self] in
            self?.scrollToCurrentMonth(animated: false)
        }
    }

    private func scrollToCurrentMonth(animated: Bool) {
        guard !months.isEmpty else { return }
        let lastIndex = IndexPath(item: months.count - 1, section: 0)
        collectionView.scrollToItem(at: lastIndex, at: .centeredHorizontally, animated: animated)
        let index = months.count - 1
        updateMonthLabel(for: index)
        notifyMonthChange(for: index)
    }

    private func updateMonthLabel(for index: Int) {
        guard index >= 0, index < months.count else { return }
        monthLabel.text = months[index].title
    }

    private func notifyMonthChange(for index: Int) {
        guard index >= 0, index < months.count else { return }
        let month = months[index]
        delegate?.allPeriodView(self, didChangeToMonth: month.year, month: month.month)
    }

    // MARK: - Public

    /// Returns the currently visible month's year and month.
    func currentVisibleMonth() -> (year: Int, month: Int)? {
        guard !months.isEmpty, collectionView.bounds.width > 0 else { return nil }
        let pageIndex = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
        guard pageIndex >= 0, pageIndex < months.count else { return nil }
        return (months[pageIndex].year, months[pageIndex].month)
    }

    /// Update a specific month's check-in dot data and refresh its cell.
    func updateMonth(year: Int, month: Int, checkInCounts: [Int: Int]) {
        guard let index = months.firstIndex(where: { $0.year == year && $0.month == month }) else { return }
        months[index].checkInCounts = checkInCounts
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.reloadItems(at: [indexPath])
    }
}

// MARK: - UICollectionViewDataSource

extension InnerCosmoAllPeriodView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return months.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MonthPageCell.reuseIdentifier,
            for: indexPath
        ) as? MonthPageCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: months[indexPath.item])
        cell.onDayTapped = { [weak self] day in
            guard let self = self else { return }
            let month = self.months[indexPath.item]
            self.delegate?.allPeriodView(self, didTapDay: day, inMonth: month.month, year: month.year)
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension InnerCosmoAllPeriodView: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        updateMonthLabel(for: pageIndex)
        notifyMonthChange(for: pageIndex)
    }
}

// MARK: - MonthPageCell

private class MonthPageCell: UICollectionViewCell {

    // MARK: - Layout Constants

    private enum Layout {
        static let dayCellSize: CGFloat = 40
        static let rowSpacing: CGFloat = 4
        static let dayFontSize: CGFloat = 15
        static let todayCircleSize: CGFloat = 36
        static let horizontalPadding: CGFloat = 16
        // Dot indicators
        static let dotSize: CGFloat = 6
        static let dotSpacing: CGFloat = 3
        static let dotBottomOffset: CGFloat = 4   // Distance from bottom of cell
        static let maxDots = 3
    }

    static let reuseIdentifier = "MonthPageCell"

    /// Callback when a day with check-ins is tapped.
    var onDayTapped: ((Int) -> Void)?

    private var dayLabels: [UILabel] = []
    private var todayBackgrounds: [UIView] = []
    private var dotContainers: [[UIView]] = []  // 42 arrays of 3 dot views each
    private var currentMonth: CalendarMonthViewModel?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGrid()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGrid() {
        contentView.backgroundColor = .clear

        let todaySize = Layout.todayCircleSize
        let count = CalendarMonthViewModel.gridColumns * CalendarMonthViewModel.maxGridRows

        for _ in 0..<count {
            let todayBg = UIView()
            todayBg.backgroundColor = .themePrimary
            todayBg.layer.cornerRadius = todaySize / 2
            todayBg.isHidden = true
            contentView.addSubview(todayBg)

            let label = UILabel()
            label.font = .projectFont(ofSize: Layout.dayFontSize, weight: .regular)
            label.textAlignment = .center
            contentView.addSubview(label)

            // Create 3 dot views for this slot
            var dots: [UIView] = []
            for _ in 0..<Layout.maxDots {
                let dot = UIView()
                dot.layer.cornerRadius = Layout.dotSize / 2
                dot.isHidden = true
                contentView.addSubview(dot)
                dots.append(dot)
            }

            dayLabels.append(label)
            todayBackgrounds.append(todayBg)
            dotContainers.append(dots)
        }
    }

    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        contentView.addGestureRecognizer(tap)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let month = currentMonth else { return }
        let point = gesture.location(in: contentView)

        let padding = Layout.horizontalPadding
        let columns = CalendarMonthViewModel.gridColumns
        let availableWidth = contentView.bounds.width - padding * 2
        let colWidth = availableWidth / CGFloat(columns)
        let cellSize = Layout.dayCellSize
        let rowSpacing = Layout.rowSpacing

        let col = Int((point.x - padding) / colWidth)
        let row = Int(point.y / (cellSize + rowSpacing))
        guard col >= 0, col < columns else { return }

        let index = row * columns + col
        let dayIndex = index - month.leadingEmptySlots
        guard dayIndex >= 0, dayIndex < month.dayItems.count else { return }

        let day = month.dayItems[dayIndex].day
        onDayTapped?(day)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cellSize = Layout.dayCellSize
        let rowSpacing = Layout.rowSpacing
        let padding = Layout.horizontalPadding
        let todaySize = Layout.todayCircleSize
        let columns = CalendarMonthViewModel.gridColumns
        let availableWidth = contentView.bounds.width - padding * 2
        let colWidth = availableWidth / CGFloat(columns)

        for (index, label) in dayLabels.enumerated() {
            let row = index / columns
            let col = index % columns

            let x = padding + CGFloat(col) * colWidth
            let y = CGFloat(row) * (cellSize + rowSpacing)

            label.frame = CGRect(x: x, y: y, width: colWidth, height: cellSize)

            todayBackgrounds[index].frame = CGRect(
                x: label.frame.midX - todaySize / 2,
                y: label.frame.midY - todaySize / 2,
                width: todaySize,
                height: todaySize
            )

            // Position dots near the bottom of the cell, centered horizontally
            let dots = dotContainers[index]
            let totalDotsWidth = CGFloat(Layout.maxDots) * Layout.dotSize + CGFloat(Layout.maxDots - 1) * Layout.dotSpacing
            let dotsStartX = label.frame.midX - totalDotsWidth / 2
            let dotsY = label.frame.maxY - Layout.dotBottomOffset - Layout.dotSize

            for (dotIndex, dot) in dots.enumerated() {
                let dotX = dotsStartX + CGFloat(dotIndex) * (Layout.dotSize + Layout.dotSpacing)
                dot.frame = CGRect(x: dotX, y: dotsY, width: Layout.dotSize, height: Layout.dotSize)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        currentMonth = nil
        onDayTapped = nil
        for (index, label) in dayLabels.enumerated() {
            label.text = nil
            label.isHidden = false
            label.textColor = .themeTextPrimary
            label.font = .projectFont(ofSize: Layout.dayFontSize, weight: .regular)
            todayBackgrounds[index].isHidden = true
            for dot in dotContainers[index] {
                dot.isHidden = true
            }
        }
    }

    func configure(with month: CalendarMonthViewModel) {
        currentMonth = month
        let leading = month.leadingEmptySlots
        let dayCount = month.dayItems.count
        let totalSlots = month.gridSlotCount

        for (index, label) in dayLabels.enumerated() {
            let dayIndex = index - leading

            if index >= totalSlots || dayIndex < 0 || dayIndex >= dayCount {
                label.isHidden = true
                todayBackgrounds[index].isHidden = true
                for dot in dotContainers[index] { dot.isHidden = true }
                continue
            }

            let item = month.dayItems[dayIndex]
            label.isHidden = false
            label.text = "\(item.day)"

            if item.isToday {
                label.textColor = .themeButtonPrimaryText
                label.font = .projectFont(ofSize: Layout.dayFontSize, weight: .bold)
                todayBackgrounds[index].isHidden = false
            } else {
                label.textColor = .themeTextPrimary
            }

            // Configure dots
            let checkInCount = month.checkInCounts[item.day] ?? 0
            let visibleDots = min(checkInCount, Layout.maxDots)
            let dots = dotContainers[index]
            for (dotIndex, dot) in dots.enumerated() {
                dot.isHidden = dotIndex >= visibleDots
                dot.backgroundColor = .themePrimary
            }
        }
    }
}
