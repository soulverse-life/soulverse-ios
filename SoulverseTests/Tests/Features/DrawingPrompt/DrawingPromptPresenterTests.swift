//
//  DrawingPromptPresenterTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingPromptPresenterTests: XCTestCase {

    // MARK: - Properties

    private var delegateMock: DrawingPromptPresenterDelegateMock!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        delegateMock = DrawingPromptPresenterDelegateMock()
    }

    override func tearDown() {
        delegateMock = nil
        super.tearDown()
    }

    // MARK: - Init

    func test_DrawingPromptPresenter_init_viewModelHasNoPrompt() {
        let presenter = makePresenter(checkinId: "abc", recordedEmotion: nil)

        XCTAssertNil(presenter.viewModel.prompt)
        XCTAssertEqual(presenter.viewModel.checkinId, "abc")
    }

    func test_DrawingPromptPresenter_init_doesNotFireDelegate() {
        _ = makePresenter()

        XCTAssertEqual(delegateMock.updateCount, 0)
    }

    // MARK: - loadPrompt — emotion routing

    func test_DrawingPromptPresenter_loadPrompt_nilEmotion_picksGeneralCategory() {
        let presenter = makePresenter(recordedEmotion: nil)

        presenter.loadPrompt()

        XCTAssertEqual(delegateMock.updatedViewModel?.prompt?.category, .general)
    }

    func test_DrawingPromptPresenter_loadPrompt_singlePrimaryEmotion_picksMatchingSingleCategory() {
        let presenter = makePresenter(recordedEmotion: .joy)

        presenter.loadPrompt()

        XCTAssertEqual(delegateMock.updatedViewModel?.prompt?.category, .single(.joy))
    }

    func test_DrawingPromptPresenter_loadPrompt_combinedDyadEmotion_picksMixedCategory() {
        // .optimism is a combined dyad (joy + anticipation) — see RecordedEmotion.sourceEmotions.
        let presenter = makePresenter(recordedEmotion: .optimism)

        presenter.loadPrompt()

        XCTAssertEqual(delegateMock.updatedViewModel?.prompt?.category, .mixed)
    }

    func test_DrawingPromptPresenter_loadPrompt_intensityVariant_picksPrimaryEmotionPool() {
        // .ecstasy is a high-intensity variant of joy — should still route to .single(.joy).
        let presenter = makePresenter(recordedEmotion: .ecstasy)

        presenter.loadPrompt()

        XCTAssertEqual(delegateMock.updatedViewModel?.prompt?.category, .single(.joy))
    }

    // MARK: - loadPrompt — delegate firing

    func test_DrawingPromptPresenter_loadPrompt_firesDelegateExactlyOnce() {
        let presenter = makePresenter(recordedEmotion: nil)

        presenter.loadPrompt()

        XCTAssertEqual(delegateMock.updateCount, 1)
    }

    func test_DrawingPromptPresenter_loadPrompt_propagatesCheckinIdToViewModel() {
        let presenter = makePresenter(checkinId: "checkin-123", recordedEmotion: .joy)

        presenter.loadPrompt()

        XCTAssertEqual(delegateMock.updatedViewModel?.checkinId, "checkin-123")
    }
}

// MARK: - Helpers

private extension DrawingPromptPresenterTests {
    func makePresenter(
        checkinId: String? = nil,
        recordedEmotion: RecordedEmotion? = nil
    ) -> DrawingPromptPresenter {
        let presenter = DrawingPromptPresenter(
            checkinId: checkinId,
            recordedEmotion: recordedEmotion
        )
        presenter.delegate = delegateMock
        return presenter
    }
}
