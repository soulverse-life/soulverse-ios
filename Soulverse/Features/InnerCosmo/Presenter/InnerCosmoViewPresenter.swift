//
//  InnerCosmoViewPresenter.swift
//

import Firebase

class InnerCosmoViewPresenter: InnerCosmoViewPresenterType {

    // MARK: - Properties

    weak var delegate: InnerCosmoViewPresenterDelegate?

    private var loadedModel: InnerCosmoViewModel {
        didSet {
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }

    private var isFetchingData: Bool = false
    private var dataAccessQueue = DispatchQueue(label: "inner_cosmo_data", attributes: .concurrent)

    private let user: UserProtocol
    private let assembler: MoodEntriesDataAssembler

    private static let checkInLimit = 10

    // MARK: - Initialization

    init(user: UserProtocol = User.shared,
         assembler: MoodEntriesDataAssembler = MoodEntriesDataAssembler()) {
        self.user = user
        self.assembler = assembler
        self.loadedModel = InnerCosmoViewModel(isLoading: true)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userIdentityChange),
            name: NSNotification.Name(rawValue: Notification.UserIdentityChange),
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

        guard let uid = user.userId else {
            handleDataFetchCompletion(moodEntries: [], hasError: true)
            return
        }

        assembler.fetchAndAssemble(uid: uid, checkInLimit: Self.checkInLimit) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let cards):
                    let entries = self.convertToMoodEntries(cards)
                    self.handleDataFetchCompletion(moodEntries: entries, hasError: false)

                case .failure:
                    self.handleDataFetchCompletion(moodEntries: [], hasError: true)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func handleDataFetchCompletion(moodEntries: [MoodEntry], hasError: Bool) {
        loadedModel = InnerCosmoViewModel(
            isLoading: false,
            userName: user.nickName,
            petName: user.emoPetName,
            planetName: user.planetName,
            moodEntries: moodEntries,
            moodEntriesLoadError: hasError
        )
        isFetchingData = false
    }

    private func convertToMoodEntries(_ cards: [MoodEntryCard]) -> [MoodEntry] {
        cards.compactMap { card in
            guard let checkIn = card.checkIn else { return nil }

            let emotion = RecordedEmotion(rawValue: checkIn.emotion) ?? .joy
            let topic = Topic(rawValue: checkIn.topic)

            return MoodEntry(
                id: checkIn.id ?? UUID().uuidString,
                emotion: emotion,
                date: card.date,
                promptResponse: checkIn.evaluation,
                colorHex: checkIn.colorHex,
                colorIntensity: checkIn.colorIntensity,
                artworkURLs: card.drawings.prefix(4).map { $0.imageURL },
                topic: topic
            )
        }
    }

    @objc private func userIdentityChange() {
        // Refresh data when user identity changes
        fetchData(isUpdate: true)
    }
}
