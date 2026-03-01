//
//  OnboardingUserDataTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class OnboardingUserDataTests: XCTestCase {

    // MARK: - Default State

    func test_OnboardingUserData_default_isNotComplete() {
        let data = OnboardingUserData()
        XCTAssertFalse(data.isComplete)
    }

    func test_OnboardingUserData_default_isSignedInIsFalse() {
        let data = OnboardingUserData()
        XCTAssertFalse(data.isSignedIn)
    }

    // MARK: - isComplete All Set

    func test_OnboardingUserData_isComplete_trueWhenAllFieldsSet() {
        let data = makeCompleteData()
        XCTAssertTrue(data.isComplete)
    }

    // MARK: - isComplete Missing Individual Fields

    func test_OnboardingUserData_isComplete_falseWhenNotSignedIn() {
        var data = makeCompleteData()
        data.isSignedIn = false
        XCTAssertFalse(data.isComplete)
    }

    func test_OnboardingUserData_isComplete_falseWhenMissingBirthday() {
        var data = makeCompleteData()
        data.birthday = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_OnboardingUserData_isComplete_falseWhenMissingGender() {
        var data = makeCompleteData()
        data.gender = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_OnboardingUserData_isComplete_falseWhenMissingPlanetName() {
        var data = makeCompleteData()
        data.planetName = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_OnboardingUserData_isComplete_falseWhenMissingEmoPetName() {
        var data = makeCompleteData()
        data.emoPetName = nil
        XCTAssertFalse(data.isComplete)
    }

    func test_OnboardingUserData_isComplete_trueWhenMissingSelectedTopic() {
        var data = makeCompleteData()
        data.selectedTopic = nil
        XCTAssertTrue(data.isComplete)
    }
}

// MARK: - Helpers

private extension OnboardingUserDataTests {
    func makeCompleteData() -> OnboardingUserData {
        var data = OnboardingUserData()
        data.isSignedIn = true
        data.birthday = Date()
        data.gender = .man
        data.planetName = "TestPlanet"
        data.emoPetName = "TestPet"
        data.selectedTopic = .emotional
        return data
    }
}
