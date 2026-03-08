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

    private static let checkInLimit = 10

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

        assembler.fetchInitial(limit: Self.checkInLimit) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isFetchingData = false

                switch result {
                case .success(let cards):
                    let entries = MoodEntriesDataAssembler.convertToMoodEntries(cards)
                    self.loadedModel = InnerCosmoViewModel(
                        isLoading: false,
                        userName: self.user.nickName,
                        petName: self.user.emoPetName,
                        planetName: self.user.planetName,
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
        // Refresh data when user identity changes
        fetchData(isUpdate: true)
    }
}
