//
//  InnerCosmoViewPresenterType.swift
//

import Foundation

protocol InnerCosmoViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: InnerCosmoViewModel)
    func didUpdateSection(at index: IndexSet)
    func didAppendMoodEntries(_ entries: [MoodEntryCardCellViewModel])
}

protocol InnerCosmoViewPresenterType {

    func fetchData(isUpdate: Bool)
    func loadMoreMoodEntries()
}
