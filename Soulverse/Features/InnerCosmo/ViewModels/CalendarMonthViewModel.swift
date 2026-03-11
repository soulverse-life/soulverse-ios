//
//  CalendarMonthViewModel.swift
//  Soulverse
//
//  View model for a single month page in the All Period calendar view.
//

import Foundation

struct CalendarDayItem {
    let day: Int
    let isToday: Bool
}

struct CalendarMonthViewModel {
    let year: Int
    let month: Int
    let title: String

    /// Number of empty slots before day 1 (for weekday alignment).
    let leadingEmptySlots: Int

    /// Only current-month days.
    let dayItems: [CalendarDayItem]

    static let gridColumns = 7
    static let maxGridRows = 6

    /// Actual number of rows needed for this month.
    var rowCount: Int {
        let totalSlots = leadingEmptySlots + dayItems.count
        return (totalSlots + Self.gridColumns - 1) / Self.gridColumns
    }

    /// Total grid slots (rows × columns) for this month.
    var gridSlotCount: Int {
        rowCount * Self.gridColumns
    }
}

// MARK: - Builder

extension CalendarMonthViewModel {

    private static let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    /// Builds a view model for the given year/month.
    static func build(year: Int, month: Int, calendar: Calendar = .current) -> CalendarMonthViewModel {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        guard let firstOfMonth = calendar.date(from: components) else {
            return CalendarMonthViewModel(year: year, month: month, title: "", leadingEmptySlots: 0, dayItems: [])
        }

        let title = titleFormatter.string(from: firstOfMonth)

        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let leadingDays = weekdayOfFirst - calendar.firstWeekday
        let leadingEmptySlots = leadingDays < 0 ? leadingDays + 7 : leadingDays

        let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        let today = calendar.dateComponents([.year, .month, .day], from: Date())

        let dayItems = (1...daysInMonth).map { day in
            CalendarDayItem(
                day: day,
                isToday: today.year == year && today.month == month && today.day == day
            )
        }

        return CalendarMonthViewModel(
            year: year,
            month: month,
            title: title,
            leadingEmptySlots: leadingEmptySlots,
            dayItems: dayItems
        )
    }

    /// Builds all month view models from Jan 2026 to the current month.
    static func buildAllMonths(calendar: Calendar = .current) -> [CalendarMonthViewModel] {
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        var months: [CalendarMonthViewModel] = []
        var year = 2026
        var month = 1

        while year < currentYear || (year == currentYear && month <= currentMonth) {
            months.append(build(year: year, month: month, calendar: calendar))
            month += 1
            if month > 12 {
                month = 1
                year += 1
            }
        }

        return months
    }
}
