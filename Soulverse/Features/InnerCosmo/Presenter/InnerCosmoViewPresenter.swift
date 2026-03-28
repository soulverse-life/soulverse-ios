//
//  InnerCosmoViewPresenter.swift
//

import Firebase

class InnerCosmoViewPresenter: InnerCosmoViewPresenterType {

    // MARK: - Properties

    weak var delegate: InnerCosmoViewPresenterDelegate?

    private var suppressDidSet = false

    private var loadedModel: InnerCosmoViewModel {
        didSet {
            guard !suppressDidSet else { return }
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }

    private var isFetchingData: Bool = false
    private var isFetchingMore: Bool = false

    private let user: UserProtocol
    private let assembler: MoodEntriesDataAssemblerProtocol
    private let moodCheckInService: MoodCheckInServiceProtocol
    private let drawingService: DrawingServiceProtocol

    private static let checkInLimit = 7

    /// Check-in models backing the 7 emotion planets (index 0 = central planet)
    private var planetCheckIns: [MoodCheckInModel] = []

    /// Current recent mood entries for restoring when switching back to Recent tab
    var currentMoodEntries: [MoodEntryCardCellViewModel] {
        loadedModel.moodEntries
    }

    /// Cached cards from the last recent fetch (for looking up MoodCheckInModel by checkinId)
    private var recentCards: [MoodEntryCard] = []

    // MARK: - Month Cache

    private struct MonthCacheEntry {
        let checkIns: [MoodCheckInModel]
        let checkInCounts: [Int: Int]
        let moodEntries: [MoodEntryCardCellViewModel]
    }

    private var monthCache: [String: MonthCacheEntry] = [:]
    private var fetchingMonths: Set<String> = []
    private var currentVisibleMonth: String = ""

    // MARK: - Initialization

    init(user: UserProtocol = User.shared,
         assembler: MoodEntriesDataAssemblerProtocol = MoodEntriesDataAssembler(),
         moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared) {
        self.user = user
        self.assembler = assembler
        self.moodCheckInService = moodCheckInService
        self.drawingService = drawingService
        self.loadedModel = InnerCosmoViewModel(isLoading: true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userIdentityChange),
            name: NSNotification.Name(rawValue: Notification.UserIdentityChange),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDataChanged),
            name: NSNotification.Name(rawValue: Notification.MoodCheckInCreated),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onDataChanged),
            name: NSNotification.Name(rawValue: Notification.DrawingSaved),
            object: nil
        )
    }

    // MARK: - Public Methods

    public func fetchData(isUpdate: Bool = false) {
        guard !isFetchingData else { return }

        isFetchingData = true

        if !isUpdate {
            loadedModel.isLoading = true
        }

        assembler.fetchInitial(limit: Self.checkInLimit) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingData = false

                switch result {
                case .success(let cards):
                    self.recentCards = cards
                    let entries = MoodEntriesDataAssembler.convertToMoodEntries(cards)
                    let emotions = Self.convertToEmotionPlanets(cards)
                    self.planetCheckIns = Array(cards
                        .compactMap { $0.checkIn }
                        .prefix(Self.checkInLimit))
                    self.loadedModel = InnerCosmoViewModel(
                        isLoading: false,
                        userName: self.user.nickName,
                        petName: self.user.emoPetName,
                        planetName: self.user.planetName,
                        emotions: emotions,
                        moodEntries: entries
                    )

                case .failure:
                    self.loadedModel = InnerCosmoViewModel(
                        isLoading: false,
                        userName: self.user.nickName,
                        petName: self.user.emoPetName,
                        planetName: self.user.planetName
                    )
                }
            }
        }
    }

    public func loadMoreMoodEntries() {
        guard !isFetchingMore, assembler.hasMore else { return }

        isFetchingMore = true

        assembler.fetchMore { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingMore = false

                switch result {
                case .success(let cards):
                    guard !cards.isEmpty else { return }
                    let newEntries = MoodEntriesDataAssembler.convertToMoodEntries(cards)
                    self.suppressDidSet = true
                    self.loadedModel.moodEntries.append(contentsOf: newEntries)
                    self.suppressDidSet = false
                    self.delegate?.didAppendMoodEntries(newEntries)

                case .failure:
                    break
                }
            }
        }
    }

    // MARK: - Private Methods

    @objc private func userIdentityChange() {
        invalidateMonthCache()
        fetchData(isUpdate: true)
    }

    @objc private func onDataChanged() {
        invalidateMonthCache()
        fetchData(isUpdate: true)
    }

    // MARK: - Month Data Fetching

    public func fetchMonthData(year: Int, month: Int) {
        let key = cacheKey(year: year, month: month)
        currentVisibleMonth = key

        // Return cached data immediately
        if let cached = monthCache[key] {
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.currentVisibleMonth == key else { return }
                self.delegate?.didUpdateMonthCheckInCounts(year: year, month: month, counts: cached.checkInCounts)
                self.delegate?.didUpdateMonthMoodEntries(cached.moodEntries)
            }
            return
        }

        fetchMonthFromFirestore(year: year, month: month, silent: false)
    }

    public func invalidateMonthCache() {
        monthCache.removeAll()
        fetchingMonths.removeAll()
    }

    public func didSelectDay(day: Int, month: Int, year: Int) {
        let key = cacheKey(year: year, month: month)
        guard let cached = monthCache[key] else { return }
        let calendar = Calendar.current
        let checkIns = cached.checkIns.filter { checkIn in
            guard let createdAt = checkIn.createdAt else { return false }
            return calendar.component(.day, from: createdAt) == day
        }
        guard !checkIns.isEmpty else { return }
        delegate?.didRequestDayDetail(checkIns: checkIns)
    }

    public func didSelectPlanet(at index: Int) {
        guard index >= 0, index < planetCheckIns.count else { return }
        delegate?.didRequestCheckInDetail(checkIn: planetCheckIns[index])
    }

    /// Looks up a MoodCheckInModel by its checkinId from recent cards cache.
    func checkInModel(forId checkinId: String) -> MoodCheckInModel? {
        return recentCards.compactMap { $0.checkIn }.first { $0.id == checkinId }
    }

    private func cacheKey(year: Int, month: Int) -> String {
        "\(year)-\(String(format: "%02d", month))"
    }

    private func fetchMonthFromFirestore(year: Int, month: Int, silent: Bool) {
        let key = cacheKey(year: year, month: month)
        guard !fetchingMonths.contains(key) else { return }
        guard let uid = user.userId else { return }

        fetchingMonths.insert(key)

        let calendar = Calendar.current
        var startComponents = DateComponents()
        startComponents.year = year
        startComponents.month = month
        startComponents.day = 1
        guard let startDate = calendar.date(from: startComponents) else {
            fetchingMonths.remove(key)
            return
        }

        guard let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            fetchingMonths.remove(key)
            return
        }

        moodCheckInService.fetchCheckIns(uid: uid, from: startDate, to: endDate) { [weak self] checkInResult in
            guard let self = self else { return }

            switch checkInResult {
            case .failure:
                self.fetchingMonths.remove(key)

            case .success(let checkIns):
                self.drawingService.fetchDrawings(uid: uid, from: startDate, to: endDate) { [weak self] drawingResult in
                    guard let self = self else { return }
                    self.fetchingMonths.remove(key)

                    let drawings: [DrawingModel]
                    switch drawingResult {
                    case .success(let d): drawings = d
                    case .failure: drawings = []
                    }

                    // assembleCards expects descending order; fetchCheckIns returns ascending
                    let descendingCheckIns = checkIns.reversed()
                    let cards = MoodEntriesDataAssembler.assembleCards(
                        checkIns: Array(descendingCheckIns),
                        drawings: drawings
                    )

                    // Compute check-in counts per day
                    var counts: [Int: Int] = [:]
                    for checkIn in checkIns {
                        guard let createdAt = checkIn.createdAt else { continue }
                        let day = calendar.component(.day, from: createdAt)
                        counts[day, default: 0] += 1
                    }

                    let entries = MoodEntriesDataAssembler.convertToMoodEntries(cards)

                    let cacheEntry = MonthCacheEntry(
                        checkIns: checkIns,
                        checkInCounts: counts,
                        moodEntries: entries
                    )
                    self.monthCache[key] = cacheEntry

                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }

                        if !silent && self.currentVisibleMonth == key {
                            self.delegate?.didUpdateMonthCheckInCounts(year: year, month: month, counts: counts)
                            self.delegate?.didUpdateMonthMoodEntries(entries)
                        }

                        // Pre-fetch adjacent months
                        if !silent {
                            self.prefetchAdjacentMonths(year: year, month: month)
                        }
                    }
                }
            }
        }
    }

    private func prefetchAdjacentMonths(year: Int, month: Int) {
        // Previous month
        var prevYear = year
        var prevMonth = month - 1
        if prevMonth < 1 { prevMonth = 12; prevYear -= 1 }
        if monthCache[cacheKey(year: prevYear, month: prevMonth)] == nil {
            fetchMonthFromFirestore(year: prevYear, month: prevMonth, silent: true)
        }

        // Next month (only if not in the future)
        var nextYear = year
        var nextMonth = month + 1
        if nextMonth > 12 { nextMonth = 1; nextYear += 1 }
        let now = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)
        if nextYear < currentYear || (nextYear == currentYear && nextMonth <= currentMonth) {
            if monthCache[cacheKey(year: nextYear, month: nextMonth)] == nil {
                fetchMonthFromFirestore(year: nextYear, month: nextMonth, silent: true)
            }
        }
    }

    // MARK: - Emotion Planet Conversion

    /// Convert mood check-in cards to emotion planet data for the daily view.
    /// Always returns exactly `totalPlanetCount` items, padded with grey placeholders.
    private static let totalPlanetCount = 7
    private static let placeholderColorHex = "#B0B0B0"

    private static func convertToEmotionPlanets(_ cards: [MoodEntryCard]) -> [EmotionPlanetData] {
        let checkInCards = cards.filter { $0.checkIn != nil }

        var planets: [EmotionPlanetData] = checkInCards.prefix(totalPlanetCount).compactMap { card in
            guard let checkIn = card.checkIn else { return nil }
            let emotion = RecordedEmotion(rawValue: checkIn.emotion)
            let displayName = emotion?.displayName ?? checkIn.emotion
            return EmotionPlanetData(
                emotion: displayName,
                colorHex: checkIn.colorHex
            )
        }

        // Pad with grey placeholders (random sizes) to always have 7 planets
        while planets.count < totalPlanetCount {
            planets.append(EmotionPlanetData(
                emotion: "",
                colorHex: placeholderColorHex,
                sizeMultiplier: CGFloat.random(in: 0.7...1.1)
            ))
        }

        return planets
    }
}
