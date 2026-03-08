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
            handleDataFetchCompletion(moodEntries: [], error: .userNotAuthenticated)
            return
        }

        assembler.fetchMoodEntries(uid: uid, checkInLimit: Self.checkInLimit) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let entries):
                    self.handleDataFetchCompletion(moodEntries: entries, error: nil)

                case .failure(let error):
                    self.handleDataFetchCompletion(moodEntries: [], error: .fetchFailed(error))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func handleDataFetchCompletion(moodEntries: [MoodEntry], error: MoodEntriesLoadError?) {
        loadedModel = InnerCosmoViewModel(
            isLoading: false,
            userName: user.nickName,
            petName: user.emoPetName,
            planetName: user.planetName,
            moodEntries: moodEntries,
            moodEntriesError: error
        )
        isFetchingData = false
    }

    @objc private func userIdentityChange() {
        // Refresh data when user identity changes
        fetchData(isUpdate: true)
    }
}
