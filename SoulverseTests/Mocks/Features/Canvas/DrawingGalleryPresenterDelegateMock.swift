//
//  DrawingGalleryPresenterDelegateMock.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingGalleryPresenterDelegateMock: DrawingGalleryPresenterDelegate {
    var updatedViewModel: DrawingGalleryViewModel?
    var updateCount = 0

    /// Set before triggering the async action; fulfilled on the final (non-loading) update.
    var expectation: XCTestExpectation?

    func didUpdate(viewModel: DrawingGalleryViewModel) {
        updatedViewModel = viewModel
        updateCount += 1
        if !viewModel.isLoading {
            expectation?.fulfill()
        }
    }
}
