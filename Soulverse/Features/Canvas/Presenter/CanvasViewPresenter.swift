//
//  CanvasViewPresenter.swift
//

import Foundation

protocol CanvasViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: CanvasViewModel)
    func didUpdateSection(at index: IndexSet)
}

protocol CanvasViewPresenterType: AnyObject {
    var delegate: CanvasViewPresenterDelegate? { get set }
    func fetchData(isUpdate: Bool)
    func numberOfSectionsOnTableView() -> Int
    func loadRandomPrompt()
}

class CanvasViewPresenter: CanvasViewPresenterType {
    weak var delegate: CanvasViewPresenterDelegate?
    private var loadedModel: CanvasViewModel {
        didSet {
            delegate?.didUpdate(viewModel: loadedModel)
        }
    }
    private var isFetchingData: Bool = false
    private var dataAccessQueue = DispatchQueue(label: "canvas_data", attributes: .concurrent)

    init(emotionFilter: EmotionType? = nil) {
        self.loadedModel = CanvasViewModel(
            isLoading: false,
            currentPrompt: nil,
            emotionFilter: emotionFilter
        )
    }

    public func fetchData(isUpdate: Bool = false) {
        if isFetchingData { return }
        if !isUpdate { loadedModel.isLoading = true }
        isFetchingData = true
    }

    public func numberOfSectionsOnTableView() -> Int {
        return 0
    }

    public func loadRandomPrompt() {
        let randomPrompt = CanvasPromptManager.randomPrompt(for: loadedModel.emotionFilter)
        loadedModel.currentPrompt = randomPrompt
    }
} 