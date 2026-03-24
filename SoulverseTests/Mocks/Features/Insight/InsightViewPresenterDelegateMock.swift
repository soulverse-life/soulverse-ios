//
//  InsightViewPresenterDelegateMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class InsightViewPresenterDelegateMock: InsightViewPresenterDelegate {
    var updatedViewModel: InsightViewModel?
    var updatedSectionIndex: IndexSet?
    var updateCount = 0
    var onUpdate: ((InsightViewModel) -> Void)?

    func didUpdate(viewModel: InsightViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
        onUpdate?(viewModel)
    }

    func didUpdateSection(at index: IndexSet) {
        updatedSectionIndex = index
    }
}
