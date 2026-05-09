//
//  LockedCardHintTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class LockedCardHintTests: XCTestCase {

    private let featureName = "see your 8 Dimensions"
    private let unlockDay = 7

    func test_LockedCardHint_farAway_useFutureDayCopy() {
        let hint = LockedCardHint.copy(currentDay: 1, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, "On Day 7, you'll see your 8 Dimensions.")
    }

    func test_LockedCardHint_threeRemaining_stillUseFutureDayCopy() {
        let hint = LockedCardHint.copy(currentDay: 4, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, "On Day 7, you'll see your 8 Dimensions.")
    }

    func test_LockedCardHint_twoRemaining_useJustNCopy() {
        let hint = LockedCardHint.copy(currentDay: 5, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, "Just 2 more check-ins!")
    }

    func test_LockedCardHint_oneRemaining_useSingularCopy() {
        let hint = LockedCardHint.copy(currentDay: 6, unlockDay: unlockDay, featureName: featureName)
        XCTAssertEqual(hint, "Just 1 more check-in!")
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
