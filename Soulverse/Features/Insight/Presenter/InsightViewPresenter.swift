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
    func numberOfSectionsOnTableView() -> Int
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

        let startDate = currentTimeRange.startDate
        let endDate = Date()

        // Fetch mood check-ins
        group.enter()
        let checkInStartDate = startDate ?? Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date.distantPast
        moodCheckInService.fetchCheckIns(uid: uid, from: checkInStartDate, to: endDate) { [weak self] result in
            defer { group.leave() }
            guard self != nil else { return }
            if case .success(let checkIns) = result {
                serialQueue.sync { fetchedCheckIns = checkIns }
            }
        }

        // Fetch drawings
        group.enter()
        drawingService.fetchDrawings(uid: uid, from: startDate ?? Date.distantPast, to: endDate) { [weak self] result in
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
        /*
        // mock data for testing
        var model = loadedModel
        model.weeklyMoodScore = WeeklyMoodScoreViewModel.mockData(referenceDate: weekDate)
        loadedModel = model
        */
    }

    func numberOfSectionsOnTableView() -> Int {
        return 0
    }
}
