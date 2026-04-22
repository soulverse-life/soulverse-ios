//
//  DrawingPromptPresenterType.swift
//  Soulverse
//

import Foundation

protocol DrawingPromptPresenterDelegate: AnyObject {
    func didUpdate(viewModel: DrawingPromptViewModel)
}

protocol DrawingPromptPresenterType: AnyObject {
    var delegate: DrawingPromptPresenterDelegate? { get set }
    var viewModel: DrawingPromptViewModel { get }
    func loadPrompt()
}
