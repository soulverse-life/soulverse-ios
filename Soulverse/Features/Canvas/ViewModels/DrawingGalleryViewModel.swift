//
//  DrawingGalleryViewModel.swift
//  Soulverse
//

import Foundation

struct DrawingGallerySectionViewModel {
    let title: String
    let drawings: [DrawingModel]
}

struct DrawingGalleryViewModel {
    var isLoading: Bool
    let sections: [DrawingGallerySectionViewModel]
    let errorMessage: String?

    init(isLoading: Bool = false, sections: [DrawingGallerySectionViewModel] = [], errorMessage: String? = nil) {
        self.isLoading = isLoading
        self.sections = sections
        self.errorMessage = errorMessage
    }

    // MARK: - Helper Methods

    func numberOfSections() -> Int {
        return sections.count
    }

    func numberOfItems(in section: Int) -> Int {
        guard section < sections.count else { return 0 }
        return sections[section].drawings.count
    }

    func drawing(at indexPath: IndexPath) -> DrawingModel? {
        guard indexPath.section < sections.count,
              indexPath.item < sections[indexPath.section].drawings.count
        else {
            return nil
        }
        return sections[indexPath.section].drawings[indexPath.item]
    }

    func titleForSection(_ section: Int) -> String? {
        guard section < sections.count else { return nil }
        return sections[section].title
    }

    var isEmpty: Bool {
        return sections.isEmpty
    }
}
