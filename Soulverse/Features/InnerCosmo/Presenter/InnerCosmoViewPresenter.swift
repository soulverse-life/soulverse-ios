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

    // MARK: - Initialization

    init(user: UserProtocol = User.shared,
         assembler: MoodEntriesDataAssemblerProtocol = MoodEntriesDataAssembler()) {
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

        assembler.fetchInitial(limit: 10) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingData = false

                switch result {
                case .success(let cards):
                    let entries = self.convertToMoodEntries(cards)
                    self.loadedModel = InnerCosmoViewModel(
                        isLoading: false,
                        userName: self.user.nickName,
                        petName: self.user.emoPetName,
                        planetName: self.user.planetName,
                        moodEntries: entries
                    )

                case .failure:
                    // On error, deliver empty entries gracefully
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
                    let newEntries = self.convertToMoodEntries(cards)
                    // Append to internal state without triggering full didUpdate
                    self.suppressDidSet = true
                    self.loadedModel.moodEntries.append(contentsOf: newEntries)
                    self.suppressDidSet = false
                    // Notify delegate with only the new entries for incremental insert
                    self.delegate?.didAppendMoodEntries(newEntries)

                case .failure:
                    // Silently fail on load-more errors
                    break
                }
            }
        }
    }

    // MARK: - Private Methods

    private func convertToMoodEntries(_ cards: [MoodEntryCard]) -> [MoodEntry] {
        return cards.map { card in
            if let checkIn = card.checkIn {
                return MoodEntry(
                    id: checkIn.id ?? UUID().uuidString,
                    emotion: RecordedEmotion(rawValue: checkIn.emotion) ?? .serenity,
                    date: checkIn.createdAt ?? card.date,
                    journal: checkIn.journal ?? checkIn.evaluation,
                    colorHex: checkIn.colorHex,
                    colorIntensity: checkIn.colorIntensity,
                    artworkURL: card.drawings.first?.imageURL,
                    topic: Topic(rawValue: checkIn.topic)
                )
            } else {
                // Orphan card (drawing-only, no check-in)
                return MoodEntry(
                    id: card.drawings.first?.id ?? UUID().uuidString,
                    emotion: .serenity,
                    date: card.date,
                    journal: "",
                    colorHex: "#808080",
                    colorIntensity: 0.5,
                    artworkURL: card.drawings.first?.imageURL,
                    topic: nil
                )
            }
        }
    }

    @objc private func userIdentityChange() {
        // Refresh data when user identity changes
        fetchData(isUpdate: true)
    }
}
