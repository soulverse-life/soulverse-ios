//
//  InnerCosmoViewPresenterDelegateMock.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class InnerCosmoViewPresenterDelegateMock: InnerCosmoViewPresenterDelegate {
    var updatedViewModel: InnerCosmoViewModel?
    var updatedSectionIndex: IndexSet?
    var appendedEntries: [MoodEntryCardCellViewModel]?
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

    func didAppendMoodEntries(_ entries: [MoodEntryCardCellViewModel]) {
        appendedEntries = entries
        appendCount += 1
        appendExpectation?.fulfill()
    }

    func didUpdateMonthCheckInCounts(year: Int, month: Int, counts: [Int: Int]) {}

    func didUpdateMonthMoodEntries(_ entries: [MoodEntryCardCellViewModel]) {}

    func didRequestDayDetail(checkIns: [MoodCheckInModel]) {}

    var requestedCheckIn: MoodCheckInModel?
    var checkInDetailExpectation: XCTestExpectation?

    func didRequestCheckInDetail(checkIn: MoodCheckInModel) {
        requestedCheckIn = checkIn
        checkInDetailExpectation?.fulfill()
    }
}
