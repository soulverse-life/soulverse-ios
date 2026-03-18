//
//  InnerCosmoViewPresenterType.swift
//

import Foundation

protocol InnerCosmoViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: InnerCosmoViewModel)
    func didUpdateSection(at index: IndexSet)
    func didAppendMoodEntries(_ entries: [MoodEntryCardCellViewModel])
    func didUpdateMonthCheckInCounts(year: Int, month: Int, counts: [Int: Int])
    func didUpdateMonthMoodEntries(_ entries: [MoodEntryCardCellViewModel])
}

protocol InnerCosmoViewPresenterType {

    func fetchData(isUpdate: Bool)
    func loadMoreMoodEntries()
    func fetchMonthData(year: Int, month: Int)
    func invalidateMonthCache()
}
