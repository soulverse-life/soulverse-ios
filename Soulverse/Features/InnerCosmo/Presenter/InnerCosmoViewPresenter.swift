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

    // MARK: - Initialization

    init(user: UserProtocol = User.shared) {
        self.user = user
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

        // TODO: Replace with actual API call
        // Simulating data fetch completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.handleDataFetchCompletion()
        }
    }

    // MARK: - Private Methods

    private func handleDataFetchCompletion() {
        
        var emotionData: [EmotionPlanetData] = []
        if let todayEmotion = user.todayCheckInData {
            var emotionStr: String = ""
            if todayEmotion.emotions.count == 1 {
                emotionStr = todayEmotion.emotions[0].emotion.displayName
            } else if todayEmotion.emotions.count == 2 {
                let emotion1 = todayEmotion.emotions[0].emotion
                let emotion2 = todayEmotion.emotions[1].emotion

                if let combinedEmotion = EmotionCombination.getCombinedEmotion(from: emotion1, and: emotion2) {
                    emotionStr = combinedEmotion.displayName
                }
            }
            let todayEmotionData = EmotionPlanetData(
                emotion: emotionStr,
                colorHex: todayEmotion.colorHexString ?? "",
                sizeMultiplier: 1.1
            )
            emotionData.append(todayEmotionData)
        }
        
        loadedModel = InnerCosmoViewModel(
            isLoading: false,
            userName: user.nickName,
            planetName: user.planetName,
            petName: user.emoPetName,
            emotions: emotionData  
        )
        isFetchingData = false
    }

    @objc private func userIdentityChange() {
        // Refresh data when user identity changes
        fetchData(isUpdate: true)
    }
}
