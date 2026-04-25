//
//  EmotionalBundleMainPresenter.swift
//  Soulverse
//

import Foundation

protocol EmotionalBundleMainPresenterDelegate: AnyObject {
    func didUpdate(viewModel: EmotionalBundleMainViewModel)
    func didFailToLoad(error: Error)
}

protocol EmotionalBundleMainPresenterType: AnyObject {
    var delegate: EmotionalBundleMainPresenterDelegate? { get set }
    func fetchData()
    func refreshAfterSave()
    func currentBundle() -> EmotionalBundleModel
}

final class EmotionalBundleMainPresenter: EmotionalBundleMainPresenterType {

    weak var delegate: EmotionalBundleMainPresenterDelegate?

    private let service: EmotionalBundleServiceProtocol
    private let uid: String
    private var cachedBundle: EmotionalBundleModel?

    init(uid: String, service: EmotionalBundleServiceProtocol = FirestoreEmotionalBundleService.shared) {
        self.uid = uid
        self.service = service
    }

    func fetchData() {
        delegate?.didUpdate(viewModel: EmotionalBundleMainViewModel(isLoading: true))

        service.fetchBundle(uid: uid) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let bundle):
                    self.cachedBundle = bundle
                    let viewModel = self.buildViewModel(from: bundle)
                    self.delegate?.didUpdate(viewModel: viewModel)
                case .failure(let error):
                    self.delegate?.didFailToLoad(error: error)
                }
            }
        }
    }

    func refreshAfterSave() {
        fetchData()
    }

    func currentBundle() -> EmotionalBundleModel {
        return cachedBundle ?? .empty()
    }

    private func buildViewModel(from bundle: EmotionalBundleModel?) -> EmotionalBundleMainViewModel {
        let bundle = bundle ?? .empty()
        let cards = EmotionalBundleSection.allCases.map { section in
            BundleSectionCardViewModel(
                section: section,
                title: section.displayTitle,
                iconName: section.iconName,
                isCompleted: EmotionalBundleMainViewModel.completionCheck(for: section, in: bundle)
            )
        }
        return EmotionalBundleMainViewModel(isLoading: false, sectionCards: cards)
    }
}
