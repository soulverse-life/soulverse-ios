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

    func didUpdate(viewModel: InsightViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
    }

    func didUpdateSection(at index: IndexSet) {
        updatedSectionIndex = index
    }
}
