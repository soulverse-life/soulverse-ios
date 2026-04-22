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

    // MARK: - Init Without Recorded Emotion

    func test_CanvasViewPresenter_initWithoutRecordedEmotion_recordedEmotionIsNil() {
        let presenter = makePresenter()

        presenter.fetchData()

        XCTAssertNil(delegateMock.updatedViewModel?.recordedEmotion)
    }

    // MARK: - Init With Recorded Emotion

    func test_CanvasViewPresenter_initWithRecordedEmotion_recordedEmotionMatches() {
        let presenter = makePresenter(recordedEmotion: .joy)

        presenter.fetchData()

        XCTAssertEqual(delegateMock.updatedViewModel?.recordedEmotion, .joy)
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
    func makePresenter(recordedEmotion: RecordedEmotion? = nil) -> CanvasViewPresenter {
        let presenter = CanvasViewPresenter(recordedEmotion: recordedEmotion)
        presenter.delegate = delegateMock
        return presenter
    }
}
