//
//  ToolsViewPresenterDelegateMock.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class ToolsViewPresenterDelegateMock: ToolsViewPresenterDelegate {
    var updatedViewModel: ToolsViewModel?
    var updateCount = 0

    /// Set before triggering the async action; fulfilled on the final (non-loading) update.
    var expectation: XCTestExpectation?

    func didUpdate(viewModel: ToolsViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
        if !viewModel.isLoading {
            expectation?.fulfill()
        }
    }
}
