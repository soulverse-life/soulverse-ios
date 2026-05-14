//
//  HabitDateKey.swift
//  Soulverse
//
//  Habit date-key utility. Buckets a Date into "YYYY-MM-DD" using the device's
//  current timezone at write time.
//
//  IMPORTANT: this is intentionally different from the mood-check-in day-counter
//  rule (which uses each record's *stored* `timezoneOffsetMinutes`). Habits do
//  not carry per-write timezone context, so we use device-now consistently.
//  See spec §6.2 D6.
//

import Foundation

enum HabitDateKey {

    /// Return "YYYY-MM-DD" for `date` interpreted in `timeZone`.
    static func dateKey(for date: Date, in timeZone: TimeZone = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        guard let y = comps.year, let m = comps.month, let d = comps.day else {
            assertionFailure("HabitDateKey: failed to extract components from \(date) in \(timeZone)")
            return "0000-00-00"
        }
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Compute the previous day's key from a "YYYY-MM-DD" string.
    /// Used by the "Yesterday: N unit" reference on habit cards.
    static func yesterdayKey(of dateKey: String) -> String {
        guard let date = parse(dateKey) else { return dateKey }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
            return dateKey
        }
        return Self.dateKey(for: yesterday, in: TimeZone(secondsFromGMT: 0)!)
    }

    private static func parse(_ key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: key)
    }
}
