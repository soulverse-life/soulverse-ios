//
//  CanvasViewPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class CanvasViewPresenterTests: XCTestCase {

    // MARK: - Properties

    private var delegateMock: CanvasViewPresenterDelegateMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        delegateMock = CanvasViewPresenterDelegateMock()
    }

    override func tearDown() {
        delegateMock = nil
        super.tearDown()
    }

    // MARK: - Init Without Emotion Filter

    func test_CanvasViewPresenter_initWithoutEmotionFilter_emotionFilterIsNil() {
        let presenter = makePresenter()

        presenter.fetchData()

        XCTAssertNil(delegateMock.updatedViewModel?.emotionFilter)
    }

    // MARK: - Init With Emotion Filter

    func test_CanvasViewPresenter_initWithEmotionFilter_emotionFilterMatches() {
        let presenter = makePresenter(emotionFilter: .joy)

        presenter.fetchData()

        XCTAssertEqual(delegateMock.updatedViewModel?.emotionFilter, .joy)
    }

    // MARK: - fetchData

    func test_CanvasViewPresenter_fetchData_setsIsLoadingTrue() {
        let presenter = makePresenter()

        presenter.fetchData()

        XCTAssertTrue(delegateMock.updatedViewModel?.isLoading == true)
    }

    // MARK: - numberOfSectionsOnTableView

    func test_CanvasViewPresenter_numberOfSectionsOnTableView_returnsZero() {
        let presenter = makePresenter()

        XCTAssertEqual(presenter.numberOfSectionsOnTableView(), 0)
    }
}

// MARK: - Helpers

private extension CanvasViewPresenterTests {
    func makePresenter(emotionFilter: EmotionType? = nil) -> CanvasViewPresenter {
        let presenter = CanvasViewPresenter(emotionFilter: emotionFilter)
        presenter.delegate = delegateMock
        return presenter
    }
}
