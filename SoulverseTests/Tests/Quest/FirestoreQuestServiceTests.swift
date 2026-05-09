//
//  FirestoreQuestServiceTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class FirestoreQuestServiceTests: XCTestCase {

    func test_FirestoreQuestService_conformsToProtocol() {
        let service: QuestServiceProtocol = FirestoreQuestService.shared
        XCTAssertNotNil(service)
    }
}
