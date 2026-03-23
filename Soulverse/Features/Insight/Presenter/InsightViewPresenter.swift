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
    func fetchWeeklyMoodScore(for weekDate: Date)
    func setTimeRange(_ range: TimeRange)
}

class InsightViewPresenter: InsightViewPresenterType {

    weak var delegate: InsightViewPresenterDelegate?

    private let user: UserProtocol
    private let moodCheckInService: MoodCheckInServiceProtocol
    private let drawingService: DrawingServiceProtocol

    private var currentTimeRange: TimeRange = .last7Days
    private var isFetchingData: Bool = false

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

    func setTimeRange(_ range: TimeRange) {
        currentTimeRange = range
        fetchData()
    }

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

            var model = InsightViewModel(isLoading: false)
            model.timeRange = self.currentTimeRange

            model.weeklyMoodScore = fetchedCheckIns.isEmpty
                ? WeeklyMoodScoreViewModel.mockData()
                : WeeklyMoodScoreViewModel.from(checkIns: fetchedCheckIns)

            model.topicDistribution = TopicDistributionViewModel.from(checkIns: fetchedCheckIns)
            model.habitActivity = HabitActivityViewModel.mockData()
            model.checkinActivity = CheckinActivityViewModel.from(
                checkIns: fetchedCheckIns, drawings: fetchedDrawings
            )

            self.loadedModel = model
        }
    }

    func fetchWeeklyMoodScore(for weekDate: Date) {
        guard let uid = user.userId else { return }

        let calendar = Calendar.current
        let weekEnd = calendar.startOfDay(for: weekDate)
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd) else { return }
        guard let dayAfterEnd = calendar.date(byAdding: .day, value: 1, to: weekEnd) else { return }

        moodCheckInService.fetchCheckIns(uid: uid, from: weekStart, to: dayAfterEnd) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                var model = self.loadedModel
                if case .success(let checkIns) = result {
                    model.weeklyMoodScore = WeeklyMoodScoreViewModel.from(
                        checkIns: checkIns, referenceDate: weekDate
                    )
                }
                self.loadedModel = model
            }
        }
    }
}
