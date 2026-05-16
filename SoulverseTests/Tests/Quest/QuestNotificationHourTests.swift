//
//  QuestNotificationHourTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class QuestNotificationHourTests: XCTestCase {

    func test_notificationHour_utcPlusEight_9amLocal_isOneAmUTC() {
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 9,
            timezoneOffsetMinutes: 8 * 60
        )
        XCTAssertEqual(hour, 1)
    }

    func test_notificationHour_utcMinusFive_9amLocal_isFourteenUTC() {
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 9,
            timezoneOffsetMinutes: -5 * 60
        )
        XCTAssertEqual(hour, 14)
    }

    func test_notificationHour_wrapsAroundMidnight() {
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 1,
            timezoneOffsetMinutes: 8 * 60
        )
        XCTAssertEqual(hour, 17)
    }

    func test_notificationHour_utc_returnsLocalHour() {
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: 9,
            timezoneOffsetMinutes: 0
        )
        XCTAssertEqual(hour, 9)
    }
}
