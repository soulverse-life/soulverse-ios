//
//  QuestViewPresenter.swift
//  Soulverse
//

import Foundation

protocol QuestViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: QuestViewModel)
    func didUpdateSection(at index: IndexSet)
    func didRequestPresentMoodCheckIn()
}

protocol QuestViewPresenterType: AnyObject {
    var delegate: QuestViewPresenterDelegate? { get set }
    var loadedModel: QuestViewModel { get }
    func start()
    func stop()
    func didTapDailyCheckInCTA()
    func numberOfSectionsOnTableView() -> Int
}

final class QuestViewPresenter: QuestViewPresenterType {

    weak var delegate: QuestViewPresenterDelegate?
    private(set) var loadedModel: QuestViewModel = QuestViewModel.loading() {
        didSet { delegate?.didUpdate(viewModel: loadedModel) }
    }

    private let questService: QuestServiceProtocol
    private let moodCheckInService: MoodCheckInServiceProtocol
    private let userIdProvider: () -> String?

    private var listenerToken: QuestListenerToken?
    private var lastState: QuestStateModel?
    private var didCheckInToday: Bool = false

    init(
        questService: QuestServiceProtocol = FirestoreQuestService.shared,
        moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
        userIdProvider: @escaping () -> String? = { User.shared.userId }
    ) {
        self.questService = questService
        self.moodCheckInService = moodCheckInService
        self.userIdProvider = userIdProvider
    }

    deinit { stop() }

    // MARK: -

    func start() {
        // Force a loading emission so the controller can clear stale state.
        loadedModel = QuestViewModel.loading()

        guard let uid = userIdProvider() else { return }

        listenerToken = questService.listen(uid: uid) { [weak self] state in
            self?.handle(state: state)
        }

        refreshTodayCheckInFlag(uid: uid)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMoodCheckInCreated),
            name: NSNotification.Name(rawValue: Notification.MoodCheckInCreated),
            object: nil
        )
    }

    func stop() {
        listenerToken?.cancel()
        listenerToken = nil
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleMoodCheckInCreated() {
        guard let uid = userIdProvider() else { return }
        refreshTodayCheckInFlag(uid: uid)
    }

    // MARK: -

    private func handle(state: QuestStateModel) {
        lastState = state
        recomposeViewModel()
    }

    private func refreshTodayCheckInFlag(uid: String) {
        moodCheckInService.fetchLatestCheckIns(uid: uid, limit: 1) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if case let .success(items) = result, let latest = items.first?.createdAt {
                    self.didCheckInToday = Self.isSameLocalDay(latest, Date())
                } else {
                    self.didCheckInToday = false
                }
                self.recomposeViewModel()
            }
        }
    }

    private func recomposeViewModel() {
        let state = lastState ?? .initial()
        let isLoading = (lastState == nil)
        loadedModel = QuestViewModel.from(
            state: state,
            didCheckInToday: didCheckInToday,
            customHabitExists: false,    // Plan 3 fills this in
            isLoading: isLoading
        )
    }

    private static func isSameLocalDay(_ a: Date, _ b: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(a, inSameDayAs: b)
    }

    // MARK: - User actions

    func didTapDailyCheckInCTA() {
        delegate?.didRequestPresentMoodCheckIn()
    }

    func numberOfSectionsOnTableView() -> Int {
        // Sections in this plan:
        //   0 — ProgressSection         (hidden when distinctCheckInDays >= 21)
        //   1 — EightDimensionsCard     (host only, locked-state in this plan)
        //   2 — HabitCheckerSection     (host placeholder; Plan 3 fills)
        //   3 — SurveySection           (hidden when distinctCheckInDays < 7)
        return 4
    }
}
