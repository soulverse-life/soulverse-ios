//
//  QuestTimezoneCalculator.swift
//  Soulverse
//

import Foundation

enum QuestTimezoneCalculator {

    /// Default user-local notification hour. Spec §4.1 quotes 9am.
    static let defaultLocalHour: Int = 9

    /// Returns the UTC hour (0..23) corresponding to `localHour` in a timezone
    /// whose offset (in minutes east of UTC) is `timezoneOffsetMinutes`.
    /// Note: integer division truncates sub-hour offsets (UTC+5:30 etc.);
    /// fixing this needs sub-hour cron granularity server-side.
    static func notificationHour(forLocalHour localHour: Int, timezoneOffsetMinutes offset: Int) -> Int {
        let offsetHours = offset / 60
        let utcHour = (localHour - offsetHours) % 24
        return (utcHour + 24) % 24
    }

    /// Pulls offset directly from the device.
    static func currentOffsetMinutes() -> Int {
        return TimeZone.current.secondsFromGMT() / 60
    }
}

extension FirestoreQuestService {

    /// Convenience: pushes the device's current tz + 9am-local-as-UTC-hour.
    func writeCurrentTimezone(uid: String) {
        let offsetMinutes = QuestTimezoneCalculator.currentOffsetMinutes()
        let hour = QuestTimezoneCalculator.notificationHour(
            forLocalHour: QuestTimezoneCalculator.defaultLocalHour,
            timezoneOffsetMinutes: offsetMinutes
        )
        writeTimezone(uid: uid, offsetMinutes: offsetMinutes, notificationHour: hour) { result in
            if case let .failure(error) = result {
                print("[Quest] writeCurrentTimezone failed: \(error.localizedDescription)")
            }
        }
    }
}
