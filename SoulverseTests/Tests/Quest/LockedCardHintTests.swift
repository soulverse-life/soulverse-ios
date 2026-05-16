//
//  LockedCardHintTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class LockedCardHintTests: XCTestCase {

    private let featureName = "see your 8 Dimensions"
    private let unlockDay = 7

    private func futureDayExpected(unlockDay: Int, featureName: String) -> String {
        let format = NSLocalizedString("quest_locked_hint_future_day", bundle: AppBundle.main, comment: "")
        return String(format: format, unlockDay, featureName)
    }

    private func nMoreExpected(remaining: Int) -> String {
        let format = NSLocalizedString("quest_locked_hint_n_more", bundle: AppBundle.main, comment: "")
        return String(format: format, remaining)
    }

    private var oneMoreExpected: String {
        NSLocalizedString("quest_locked_hint_one_more", bundle: AppBundle.main, comment: "")
    }

    func test_LockedCardHint_farAway_useFutureDayCopy() {
        let hint = LockedCardHint.copy(currentDay: 1, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, futureDayExpected(unlockDay: unlockDay, featureName: featureName))
    }

    func test_LockedCardHint_threeRemaining_stillUseFutureDayCopy() {
        let hint = LockedCardHint.copy(currentDay: 4, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, futureDayExpected(unlockDay: unlockDay, featureName: featureName))
    }

    func test_LockedCardHint_twoRemaining_useJustNCopy() {
        let hint = LockedCardHint.copy(currentDay: 5, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, nMoreExpected(remaining: 2))
    }

    func test_LockedCardHint_oneRemaining_useSingularCopy() {
        let hint = LockedCardHint.copy(currentDay: 6, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, oneMoreExpected)
    }

    func test_LockedCardHint_atUnlock_returnsEmpty() {
        let hint = LockedCardHint.copy(currentDay: 7, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, "")
    }

    func test_LockedCardHint_pastUnlock_returnsEmpty() {
        let hint = LockedCardHint.copy(currentDay: 12, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, "")
    }
}
