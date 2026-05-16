//
//  QuestServiceMockTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestServiceMockTests: XCTestCase {

    func test_QuestServiceMock_emitsInitialState_thenUpdates() {
        let mock = QuestServiceMock()
        var received: [QuestStateModel] = []

        let token = mock.listen(uid: "u1") { state in
            received.append(state)
        }

        mock.emit(QuestStateModel.initial())
        var updated = QuestStateModel.initial()
        updated.distinctCheckInDays = 5
        mock.emit(updated)

        XCTAssertEqual(received.count, 2)
        XCTAssertEqual(received[0].distinctCheckInDays, 0)
        XCTAssertEqual(received[1].distinctCheckInDays, 5)

        token.cancel()
    }

    func test_QuestServiceMock_recordsTimezoneWrite() {
        let mock = QuestServiceMock()
        mock.writeTimezone(uid: "u1", offsetMinutes: 480, notificationHour: 1) { _ in }
        XCTAssertEqual(mock.lastWrittenOffsetMinutes, 480)
        XCTAssertEqual(mock.lastWrittenNotificationHour, 1)
    }
}
