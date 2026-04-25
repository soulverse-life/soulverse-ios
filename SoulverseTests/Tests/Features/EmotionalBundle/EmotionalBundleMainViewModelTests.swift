//
//  EmotionalBundleMainViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class EmotionalBundleMainViewModelTests: XCTestCase {
    func testCompletionCheckRedFlagsComplete() {
        let bundle = EmotionalBundleModel(redFlags: [RedFlagItem(text: "I isolate", sortOrder: 0)])
        XCTAssertTrue(EmotionalBundleMainViewModel.completionCheck(for: .redFlags, in: bundle))
    }

    func testCompletionCheckRedFlagsIncomplete() {
        let bundle = EmotionalBundleModel.empty()
        XCTAssertFalse(EmotionalBundleMainViewModel.completionCheck(for: .redFlags, in: bundle))
    }

    func testCompletionCheckRedFlagsWhitespaceOnly() {
        let bundle = EmotionalBundleModel(redFlags: [RedFlagItem(text: "   ", sortOrder: 0)])
        XCTAssertFalse(EmotionalBundleMainViewModel.completionCheck(for: .redFlags, in: bundle))
    }

    func testCompletionCheckSupportMeComplete() {
        let bundle = EmotionalBundleModel(supportMe: [SupportContact(name: "Alice", sortOrder: 0)])
        XCTAssertTrue(EmotionalBundleMainViewModel.completionCheck(for: .supportMe, in: bundle))
    }

    func testCompletionCheckSupportMeIncomplete() {
        let bundle = EmotionalBundleModel.empty()
        XCTAssertFalse(EmotionalBundleMainViewModel.completionCheck(for: .supportMe, in: bundle))
    }

    func testCompletionCheckFeelCalmComplete() {
        let bundle = EmotionalBundleModel(feelCalm: [CalmActivity(text: "Breathe", sortOrder: 0)])
        XCTAssertTrue(EmotionalBundleMainViewModel.completionCheck(for: .feelCalm, in: bundle))
    }

    func testCompletionCheckStaySafeComplete() {
        let bundle = EmotionalBundleModel(staySafe: [SafetyAction(text: "Remove items", sortOrder: 0)])
        XCTAssertTrue(EmotionalBundleMainViewModel.completionCheck(for: .staySafe, in: bundle))
    }

    func testCompletionCheckProfessionalSupportComplete() {
        let bundle = EmotionalBundleModel(professionalSupport: [ProfessionalContact(placeName: "Hospital", sortOrder: 0)])
        XCTAssertTrue(EmotionalBundleMainViewModel.completionCheck(for: .professionalSupport, in: bundle))
    }

    func testCompletionCheckProfessionalSupportIncomplete() {
        let bundle = EmotionalBundleModel.empty()
        XCTAssertFalse(EmotionalBundleMainViewModel.completionCheck(for: .professionalSupport, in: bundle))
    }

    func testDefaultInit() {
        let vm = EmotionalBundleMainViewModel()
        XCTAssertFalse(vm.isLoading)
        XCTAssertTrue(vm.sectionCards.isEmpty)
    }
}
