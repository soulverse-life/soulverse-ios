//
//  HabitTelemetry.swift
//  Soulverse
//
//  Detects significant timezone shifts within the same calendar day during habit
//  writes, and emits an analytics event for support-staff diagnosis. Per spec
//  §6.2 D6 amendment.
//

import Foundation

protocol HabitTelemetryWriting {
    func write(name: String, properties: [String: Any])
}

/// Console-print writer used by default. Plan 7 will swap in the real analytics
/// pipeline (PostHog/Firebase) via dependency injection at the call site.
final class ConsoleHabitTelemetryWriter: HabitTelemetryWriting {
    func write(name: String, properties: [String: Any]) {
        print("[Quest Habit Telemetry] \(name): \(properties)")
    }
}

/// Tracks timezone shifts across consecutive habit writes within the same
/// calendar day. Fires an event when shift exceeds 2 hours.
final class HabitTelemetry {
    private let writer: HabitTelemetryWriting
    private var lastWrite: (date: Date, timeZone: TimeZone)?

    init(writer: HabitTelemetryWriting = ConsoleHabitTelemetryWriter()) {
        self.writer = writer
    }

    func observe(writeAt date: Date, in timeZone: TimeZone) {
        defer { lastWrite = (date, timeZone) }
        guard let prev = lastWrite else { return }

        let prevDay = HabitDateKey.dateKey(for: prev.date, in: prev.timeZone)
        let nowDay = HabitDateKey.dateKey(for: date, in: timeZone)
        guard prevDay == nowDay else { return }

        let prevOffsetH = Double(prev.timeZone.secondsFromGMT()) / 3600.0
        let nowOffsetH = Double(timeZone.secondsFromGMT()) / 3600.0
        let shiftHours = abs(nowOffsetH - prevOffsetH)
        guard shiftHours > 2 else { return }

        writer.write(
            name: "quest_habit_timezone_shift_detected",
            properties: [
                "previous_offset_hours": prevOffsetH,
                "current_offset_hours":  nowOffsetH,
                "shift_hours":           shiftHours,
                "day_key":               nowDay
            ]
        )
    }
}
