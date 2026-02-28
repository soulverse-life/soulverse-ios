import Foundation

protocol ToolsViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: ToolsViewModel)
}

protocol ToolsViewPresenterType: AnyObject {
    var delegate: ToolsViewPresenterDelegate? { get set }
    func fetchData()
    func didSelectTool(action: ToolAction)
}

class ToolsViewPresenter: ToolsViewPresenterType {

    weak var delegate: ToolsViewPresenterDelegate?

    private var viewModel: ToolsViewModel = ToolsViewModel(isLoading: true) {
        didSet {
            delegate?.didUpdate(viewModel: viewModel)
        }
    }

    init() {}

    func fetchData() {
        // Simulate API call
        viewModel = ToolsViewModel(isLoading: true, sections: [])

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let models = self.generateMockData()
            let sectionViewModels = self.mapToViewModels(models: models)

            let newViewModel = ToolsViewModel(isLoading: false, sections: sectionViewModels)

            DispatchQueue.main.async {
                self.viewModel = newViewModel
            }
        }
    }

    private func generateMockData() -> [ToolSection] {
        let favoriteItems = [
            ToolItem(
                iconName: "sun.max",
                title: NSLocalizedString("tools_item_emotion_bundle_title", comment: ""),
                description: NSLocalizedString("tools_item_emotion_bundle_description", comment: ""),
                action: .emotionBundle,
                lockState: .unlocked
            ),
            ToolItem(
                iconName: "leaf",
                title: NSLocalizedString("tools_item_self_soothing_labyrinth_title", comment: ""),
                description: NSLocalizedString(
                    "tools_item_self_soothing_labyrinth_description", comment: ""),
                action: .selfSoothingLabyrinth,
                lockState: .unlocked
            ),
        ]

        let exploreItems = [
            ToolItem(
                iconName: "drop",
                title: NSLocalizedString("tools_item_cosmic_drift_bottle_title", comment: ""),
                description: NSLocalizedString(
                    "tools_item_cosmic_drift_bottle_description", comment: ""),
                action: .cosmicDriftBottle,
                lockState: .locked(.notImplemented)
            ),
            ToolItem(
                iconName: "bird",
                title: NSLocalizedString("tools_item_daily_quote_title", comment: ""),
                description: NSLocalizedString("tools_item_daily_quote_description", comment: ""),
                action: .dailyQuote,
                lockState: .locked(.notImplemented)
            ),
            ToolItem(
                iconName: "clock",
                title: NSLocalizedString("tools_item_time_capsule_title", comment: ""),
                description: NSLocalizedString("tools_item_time_capsule_description", comment: ""),
                action: .timeCapsule,
                lockState: .locked(.notImplemented)
            ),
        ]

        return [
            ToolSection(
                title: NSLocalizedString("tools_section_favorite", comment: ""),
                items: favoriteItems
            ),
            ToolSection(
                title: NSLocalizedString("tools_section_explore", comment: ""),
                items: exploreItems
            )
        ]
    }

    private func mapToViewModels(models: [ToolSection]) -> [ToolsSectionViewModel] {
        return models.map { section in
            let cellViewModels = section.items.map { item in
                ToolsCellViewModel(
                    iconName: item.iconName,
                    title: item.title,
                    description: item.description,
                    action: item.action,
                    lockState: item.lockState
                )
            }
            return ToolsSectionViewModel(title: section.title, items: cellViewModels)
        }
    }

    func didSelectTool(action: ToolAction) {
        // Log the selection for debugging
        print("🛠️ [Tools] Tool selected: \(action.debugDescription)")

    }
}
