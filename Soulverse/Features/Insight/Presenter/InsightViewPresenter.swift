//
//  InsightViewPresenter.swift
//

import Foundation

protocol InsightViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: InsightViewModel)
    func didUpdateSection(at index: IndexSet)
}

protocol InsightViewPresenterType: AnyObject {
    var delegate: InsightViewPresenterDelegate? { get set }
    func fetchData(isUpdate: Bool)
    func didSwipeToWeekPage(_ pageIndex: Int)
    func setTimeRange(_ range: TimeRange)
}

class InsightViewPresenter: InsightViewPresenterType {

    weak var delegate: InsightViewPresenterDelegate?

    private let user: UserProtocol
    private let moodCheckInService: MoodCheckInServiceProtocol
    private let drawingService: DrawingServiceProtocol

    private var currentTimeRange: TimeRange = .last7Days
    private var isFetchingData: Bool = false

    // MARK: - Week Page State

    private enum WeekPageConfig {
        static let pastWeekPages = 52
        static let futureWeekPages = 4
    }

    /// Start date (the earliest day) for each page. Each page covers 7 days: [startDate, startDate+6].
    private var weekStartDates: [Date] = []

    /// Index of the currently visible page.
    private var currentWeekPageIndex: Int = 0

    private var loadedModel: InsightViewModel = InsightViewModel(isLoading: false) {
        didSet {
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }

    init(user: UserProtocol = User.shared,
         moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared) {
        self.user = user
        self.moodCheckInService = moodCheckInService
        self.drawingService = drawingService
    }

    // MARK: - Time Range

    func setTimeRange(_ range: TimeRange) {
        currentTimeRange = range
        generateWeekPages()
        fetchData()
    }

    // MARK: - Fetch Data

    func fetchData(isUpdate: Bool = false) {
        guard !isFetchingData else { return }
        guard let uid = user.userId else {
            loadedModel = InsightViewModel(isLoading: false)
            return
        }

        if !isUpdate { loadedModel.isLoading = true }
        isFetchingData = true

        let group = DispatchGroup()
        let serialQueue = DispatchQueue(label: "insight_fetch_results")
        var fetchedCheckIns: [MoodCheckInModel] = []
        var fetchedDrawings: [DrawingModel] = []

        let endDate = Date()
        let fallbackStartDate = DateComponents(calendar: .current, year: 2026, month: 1, day: 1).date ?? endDate
        let startDate = currentTimeRange.startDate ?? fallbackStartDate

        // Fetch mood check-ins
        group.enter()
        moodCheckInService.fetchCheckIns(uid: uid, from: startDate, to: endDate) { [weak self] result in
            defer { group.leave() }
            guard self != nil else { return }
            if case .success(let checkIns) = result {
                serialQueue.sync { fetchedCheckIns = checkIns }
            }
        }

        // Fetch drawings
        group.enter()
        drawingService.fetchDrawings(uid: uid, from: startDate, to: endDate) { [weak self] result in
            defer { group.leave() }
            guard self != nil else { return }
            if case .success(let drawings) = result {
                serialQueue.sync { fetchedDrawings = drawings }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isFetchingData = false

            // Generate week pages on first load
            if self.weekStartDates.isEmpty {
                self.generateWeekPages()
            }

            var model = InsightViewModel(isLoading: false)
            model.timeRange = self.currentTimeRange

            let isSwipeEnabled = self.currentTimeRange == .all
            model.weeklyMoodScore = fetchedCheckIns.isEmpty
                ? WeeklyMoodScoreViewModel.mockData(
                    weekStartDates: self.weekStartDates,
                    currentPageIndex: self.currentWeekPageIndex,
                    isSwipeEnabled: isSwipeEnabled
                )
                : WeeklyMoodScoreViewModel.from(
                    checkIns: fetchedCheckIns,
                    weekStartDates: self.weekStartDates,
                    currentPageIndex: self.currentWeekPageIndex,
                    isSwipeEnabled: isSwipeEnabled
                )

            model.topicDistribution = TopicDistributionViewModel.from(checkIns: fetchedCheckIns)
            model.habitActivity = HabitActivityViewModel.mockData()
            model.checkinActivity = CheckinActivityViewModel.from(
                checkIns: fetchedCheckIns, drawings: fetchedDrawings
            )

            self.loadedModel = model
        }
    }

    // MARK: - Week Page Navigation

    func didSwipeToWeekPage(_ pageIndex: Int) {
        guard pageIndex >= 0, pageIndex < weekStartDates.count, pageIndex != currentWeekPageIndex else { return }
        currentWeekPageIndex = pageIndex

        guard let uid = user.userId else { return }

        let calendar = Calendar.current
        let weekStart = weekStartDates[pageIndex]
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else { return }
        guard let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: weekEnd) else { return }

        moodCheckInService.fetchCheckIns(uid: uid, from: weekStart, to: dayAfterEnd) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                var model = self.loadedModel
                if case .success(let checkIns) = result {
                    let isSwipeEnabled = self.currentTimeRange == .all
                    model.weeklyMoodScore = WeeklyMoodScoreViewModel.from(
                        checkIns: checkIns,
                        referenceDate: weekEnd,
                        weekStartDates: self.weekStartDates,
                        currentPageIndex: self.currentWeekPageIndex,
                        isSwipeEnabled: isSwipeEnabled
                    )
                }
                self.loadedModel = model
            }
        }
    }

    // MARK: - Week Page Generation

    /// Generates week pages anchored on today.
    /// Each page is a 7-day window: the "current" page covers [today-6, today].
    /// Previous pages shift back by 7 days each.
    private func generateWeekPages() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Current page starts at today - 6
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        var dates: [Date] = []
        for offset in -WeekPageConfig.pastWeekPages...WeekPageConfig.futureWeekPages {
            if let pageStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) {
                dates.append(pageStart)
            }
        }

        weekStartDates = dates
        currentWeekPageIndex = WeekPageConfig.pastWeekPages
    }
}
