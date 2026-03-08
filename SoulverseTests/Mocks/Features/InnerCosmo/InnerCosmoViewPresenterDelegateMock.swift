//
//  InnerCosmoViewPresenterDelegateMock.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class InnerCosmoViewPresenterDelegateMock: InnerCosmoViewPresenterDelegate {
    var updatedViewModel: InnerCosmoViewModel?
    var updatedSectionIndex: IndexSet?
    var appendedEntries: [MoodEntry]?
    var updateCount = 0
    var appendCount = 0

    /// Set before triggering the async action; fulfilled on the final (non-loading) update.
    var expectation: XCTestExpectation?

    /// Separate expectation for append events.
    var appendExpectation: XCTestExpectation?

    func didUpdate(viewModel: InnerCosmoViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
        if !viewModel.isLoading {
            expectation?.fulfill()
        }
    }

    func didUpdateSection(at index: IndexSet) {
        updatedSectionIndex = index
    }

    func didAppendMoodEntries(_ entries: [MoodEntry]) {
        appendedEntries = entries
        appendCount += 1
        appendExpectation?.fulfill()
    }
}
