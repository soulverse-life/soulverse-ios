//
//  InnerCosmoViewPresenterType.swift
//

import Foundation

protocol InnerCosmoViewPresenterDelegate: AnyObject {
    func didUpdate(viewModel: InnerCosmoViewModel)
    func didUpdateSection(at index: IndexSet)
}

protocol InnerCosmoViewPresenterType {
    
    func fetchData(isUpdate: Bool)
}
