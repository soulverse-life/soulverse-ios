//
//  CrashlyticsClientMock.swift
//  SoulverseTests
//

@testable import Soulverse

final class CrashlyticsClientMock: CrashlyticsClient {
    private(set) var setUserIDCallCount = 0
    private(set) var lastUserIDSet: String?

    func setUserID(_ userID: String) {
        setUserIDCallCount += 1
        lastUserIDSet = userID
    }
}
