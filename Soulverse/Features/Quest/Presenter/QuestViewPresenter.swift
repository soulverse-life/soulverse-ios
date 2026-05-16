//
//  QuestViewPresenter.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

protocol QuestViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: QuestViewModel)
    func didRequestPresentMoodCheckIn()
}

protocol QuestViewPresenterType: AnyObject {
    var delegate: QuestViewPresenterDelegate? { get set }
    var loadedModel: QuestViewModel { get }
    func start()
    func stop()
    func didTapDailyCheckInCTA()
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
    private var surveyListener: ListenerRegistration?
    private var lastState: QuestStateModel?
    private var lastRecentSubmissions: [RecentSurveySubmission] = []
    private var didCheckInToday: Bool = false

    init(
        questService: QuestServiceProtocol = FirestoreQuestService.shared,
        moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
        userIdProvider: @escaping () -> String? = { User.shared.userId }
    ) {
        self.questService = questService
        self.moodCheckInService = moodCheckInService
        self.userIdProvider = userIdProvider

        // Registered once for lifetime — start()/stop() pair with view
        // appearance and cannot double-register here.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMoodCheckInCreated),
            name: NSNotification.Name(rawValue: Notification.MoodCheckInCreated),
            object: nil
        )
    }

    deinit {
        stop()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: -

    func start() {
        // Force a loading emission so the controller can clear stale state.
        loadedModel = QuestViewModel.loading()

        guard let uid = userIdProvider() else { return }

        listenerToken = questService.listen(uid: uid) { [weak self] state in
            self?.handle(state: state)
        }

        surveyListener = FirestoreSurveyService.observeRecentSubmissions(uid: uid) { [weak self] subs in
            DispatchQueue.main.async {
                self?.lastRecentSubmissions = subs
                self?.recomposeViewModel()
            }
        }

        refreshTodayCheckInFlag(uid: uid)
    }

    func stop() {
        listenerToken?.cancel()
        listenerToken = nil
        surveyListener?.remove()
        surveyListener = nil
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
            recentSubmissions: lastRecentSubmissions,
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
}
