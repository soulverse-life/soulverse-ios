//
//  QuestViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestViewModelTests: XCTestCase {

    private func model(distinctCheckInDays: Int,
                       didCheckInToday: Bool = false,
                       focusDimension: WellnessDimension? = nil,
                       customHabitExists: Bool = false) -> QuestViewModel {
        var state = QuestStateModel.initial()
        state.distinctCheckInDays = distinctCheckInDays
        state.focusDimension = focusDimension
        return QuestViewModel.from(
            state: state,
            didCheckInToday: didCheckInToday,
            customHabitExists: customHabitExists
        )
    }

    func test_QuestViewModel_dayZero_pillReadsDayZeroOfTwentyOne() {
        XCTAssertEqual(model(distinctCheckInDays: 0).dayPillText, "Day 0 of 21")
    }

    func test_QuestViewModel_daySeventeen_pillReadsDaySeventeenOfTwentyOne() {
        XCTAssertEqual(model(distinctCheckInDays: 17).dayPillText, "Day 17 of 21")
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
        XCTAssertFalse(model(distinctCheckInDays: 6).surveySectionVisible)
    }

    func test_QuestViewModel_atDay7_surveySectionVisible() {
        XCTAssertTrue(model(distinctCheckInDays: 7).surveySectionVisible)
    }

    func test_QuestViewModel_day1_eightDimHint_usesFutureDayCopy() {
        let vm = model(distinctCheckInDays: 1)
        XCTAssertEqual(vm.eightDimensionsLockedHint, "On Day 7, you'll see your 8 Dimensions.")
        XCTAssertTrue(vm.eightDimensionsLocked)
    }

    func test_QuestViewModel_day6_eightDimHint_usesSingularCopy() {
        XCTAssertEqual(model(distinctCheckInDays: 6).eightDimensionsLockedHint, "Just 1 more check-in!")
    }

    func test_QuestViewModel_day7_eightDimUnlocked_emptyHint() {
        let vm = model(distinctCheckInDays: 7)
        XCTAssertFalse(vm.eightDimensionsLocked)
        XCTAssertEqual(vm.eightDimensionsLockedHint, "")
    }

    func test_QuestViewModel_day1_customHabitLocked_withFutureDayHint() {
        let vm = model(distinctCheckInDays: 1)
        XCTAssertTrue(vm.customHabitLocked)
        XCTAssertEqual(vm.customHabitLockedHint, "On Day 14, you'll add your own habit.")
    }

    func test_QuestViewModel_day13_customHabitLocked_withSingularHint() {
        let vm = model(distinctCheckInDays: 13)
        XCTAssertTrue(vm.customHabitLocked)
        XCTAssertEqual(vm.customHabitLockedHint, "Just 1 more check-in!")
    }

    func test_QuestViewModel_day14_customHabitUnlocked() {
        XCTAssertFalse(model(distinctCheckInDays: 14).customHabitLocked)
    }

    func test_QuestViewModel_day20_customHabitExists_slotHidden() {
        XCTAssertFalse(model(distinctCheckInDays: 20, customHabitExists: true).customHabitSlotVisible)
    }

    func test_QuestViewModel_day20_noCustomHabit_slotVisible() {
        XCTAssertTrue(model(distinctCheckInDays: 20, customHabitExists: false).customHabitSlotVisible)
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
