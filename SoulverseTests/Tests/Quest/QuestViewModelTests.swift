//
//  QuestViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestViewModelTests: XCTestCase {

    private func model(distinctCheckInDays: Int,
                       didCheckInToday: Bool = false,
                       focusDimension: Topic? = nil) -> QuestViewModel {
        var state = QuestStateModel.initial()
        state.distinctCheckInDays = distinctCheckInDays
        state.focusDimension = focusDimension
        return QuestViewModel.from(
            state: state,
            didCheckInToday: didCheckInToday
        )
    }

    private func pillExpected(day: Int) -> String {
        let format = NSLocalizedString("quest_progress_day_pill", bundle: AppBundle.main, comment: "")
        return String(format: format, day, QuestViewModel.questCompleteDay)
    }

    func test_QuestViewModel_dayZero_pillReadsDayZeroOfTwentyOne() {
        XCTAssertEqual(model(distinctCheckInDays: 0).dayPillText, pillExpected(day: 0))
    }

    func test_QuestViewModel_daySeventeen_pillReadsDaySeventeenOfTwentyOne() {
        XCTAssertEqual(model(distinctCheckInDays: 17).dayPillText, pillExpected(day: 17))
    }

    func test_QuestViewModel_belowDay21_progressSectionVisible() {
        XCTAssertTrue(model(distinctCheckInDays: 5).progressSectionVisible)
    }

    func test_QuestViewModel_atDay21_progressSectionHidden() {
        XCTAssertFalse(model(distinctCheckInDays: 21).progressSectionVisible)
    }

    func test_QuestViewModel_aboveDay21_progressSectionHidden() {
        XCTAssertFalse(model(distinctCheckInDays: 30).progressSectionVisible)
    }

    func test_QuestViewModel_didNotCheckInToday_ctaVisible() {
        XCTAssertTrue(model(distinctCheckInDays: 5, didCheckInToday: false).dailyCheckInCTAVisible)
    }

    func test_QuestViewModel_alreadyCheckedInToday_ctaHidden() {
        XCTAssertFalse(model(distinctCheckInDays: 5, didCheckInToday: true).dailyCheckInCTAVisible)
    }

    func test_QuestViewModel_atDay21_ctaHidden() {
        XCTAssertFalse(model(distinctCheckInDays: 21, didCheckInToday: false).dailyCheckInCTAVisible)
    }

    func test_QuestViewModel_belowDay7_surveySectionHidden() {
        XCTAssertEqual(model(distinctCheckInDays: 6).surveySection, .hidden)
    }

    func test_QuestViewModel_atDay7_surveySectionVisible() {
        XCTAssertNotEqual(model(distinctCheckInDays: 7).surveySection, .hidden)
    }

    func test_QuestViewModel_day1_eightDimHint_usesFutureDayCopy() {
        let vm = model(distinctCheckInDays: 1)
        let featureName = NSLocalizedString("quest_locked_feature_8dim", bundle: AppBundle.main, comment: "")
        let expected = LockedCardHint.copy(currentDay: 1, unlockDay: QuestViewModel.eightDimensionsUnlockDay, featureName: featureName)
        XCTAssertEqual(vm.eightDimensionsLockedHint, expected)
        XCTAssertTrue(vm.eightDimensionsLocked)
    }

    func test_QuestViewModel_day6_eightDimHint_usesSingularCopy() {
        let vm = model(distinctCheckInDays: 6)
        let featureName = NSLocalizedString("quest_locked_feature_8dim", bundle: AppBundle.main, comment: "")
        let expected = LockedCardHint.copy(currentDay: 6, unlockDay: QuestViewModel.eightDimensionsUnlockDay, featureName: featureName)
        XCTAssertEqual(vm.eightDimensionsLockedHint, expected)
    }

    func test_QuestViewModel_day7_eightDimUnlocked_emptyHint() {
        let vm = model(distinctCheckInDays: 7)
        XCTAssertFalse(vm.eightDimensionsLocked)
        XCTAssertEqual(vm.eightDimensionsLockedHint, "")
    }

    func test_QuestViewModel_day3_stageIsStage1_currentDotIs3() {
        let vm = model(distinctCheckInDays: 3)
        XCTAssertEqual(vm.stage, .stage1)
        XCTAssertEqual(vm.currentDot, 3)
    }

    func test_QuestViewModel_day10_stageIsStage2() {
        let vm = model(distinctCheckInDays: 10)
        XCTAssertEqual(vm.stage, .stage2)
        XCTAssertEqual(vm.currentDot, 10)
    }
}
