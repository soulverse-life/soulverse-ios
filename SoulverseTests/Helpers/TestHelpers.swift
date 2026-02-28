//
//  TestHelpers.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

/// Shared test utilities for creating test data
enum TestHelpers {

    /// Creates a Date for the given components in UTC.
    /// - Parameters:
    ///   - year: Year
    ///   - month: Month (1-12)
    ///   - day: Day (1-31)
    ///   - hour: Hour (0-23), defaults to 0
    ///   - minute: Minute (0-59), defaults to 0
    /// - Returns: A Date in UTC
    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 0,
        _ minute: Int = 0
    ) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.timeZone = TimeZone(identifier: "UTC")
        return Calendar.current.date(from: components)!
    }
}
