//
//  CanvasViewPresenterDelegateMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class CanvasViewPresenterDelegateMock: CanvasViewPresenterDelegate {
    var updatedViewModel: CanvasViewModel?
    var updatedSectionIndex: IndexSet?
    var updateCount = 0

    func didUpdate(viewModel: CanvasViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
    }

    func didUpdateSection(at index: IndexSet) {
        updatedSectionIndex = index
    }
}
