import Foundation

struct ToolsSectionViewModel {
    let title: String
    let items: [ToolsCellViewModel]
}

struct ToolsViewModel {
    let healingTitle: String
    let healingSubtitle: String
    var isLoading: Bool
    let sections: [ToolsSectionViewModel]

    init(isLoading: Bool = false, sections: [ToolsSectionViewModel] = []) {
        self.healingTitle = NSLocalizedString("tools_healing_title", comment: "")
        self.healingSubtitle = NSLocalizedString("tools_healing_subtitle", comment: "")
        self.isLoading = isLoading
        self.sections = sections
    }

    // MARK: - Helper Methods

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfItems(in section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].items.count
    }

    func item(at indexPath: IndexPath) -> ToolsCellViewModel? {
        guard indexPath.section < sections.count,
            indexPath.item < sections[indexPath.section].items.count
        else {
            return nil
        }
        return sections[indexPath.section].items[indexPath.item]
    }

    func titleForSection(_ section: Int) -> String? {
        guard section < sections.count else { return nil }
        return sections[section].title
    }
}
