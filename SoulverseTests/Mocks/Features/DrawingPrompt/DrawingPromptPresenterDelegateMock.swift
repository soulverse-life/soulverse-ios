//
//  DrawingPromptPresenterDelegateMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class DrawingPromptPresenterDelegateMock: DrawingPromptPresenterDelegate {
    var updatedViewModel: DrawingPromptViewModel?
    var updateCount = 0

    func didUpdate(viewModel: DrawingPromptViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
    }
}
