//
//  CalendarMonthViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class CalendarMonthViewModelTests: XCTestCase {

    // MARK: - Grid Structure

    func test_build_dayItemsContainOnlyCurrentMonthDays() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 3)
        // March has 31 days
        XCTAssertEqual(vm.dayItems.count, 31)
    }

    func test_build_titleFormattedCorrectly() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 3)
        XCTAssertTrue(vm.title.contains("2026"))
        XCTAssertTrue(vm.title.contains("March") || vm.title.contains("3"))
    }

    func test_build_yearAndMonthStored() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 7)
        XCTAssertEqual(vm.year, 2026)
        XCTAssertEqual(vm.month, 7)
    }

    // MARK: - Leading Empty Slots

    func test_build_march2026_noLeadingSlots() {
        // March 1, 2026 is a Sunday — no leading empties
        let vm = CalendarMonthViewModel.build(year: 2026, month: 3)
        XCTAssertEqual(vm.leadingEmptySlots, 0)
    }

    func test_build_january2026_4LeadingSlots() {
        // Jan 1, 2026 is a Thursday — 4 leading empties (Sun-Wed)
        let vm = CalendarMonthViewModel.build(year: 2026, month: 1)
        XCTAssertEqual(vm.leadingEmptySlots, 4)
    }

    func test_build_february2026_noLeadingSlots() {
        // Feb 1, 2026 is a Sunday
        let vm = CalendarMonthViewModel.build(year: 2026, month: 2)
        XCTAssertEqual(vm.leadingEmptySlots, 0)
    }

    // MARK: - Dynamic Row Count

    func test_build_february2026_has4Rows() {
        // Feb 2026: starts Sunday, 28 days → exactly 4 rows
        let vm = CalendarMonthViewModel.build(year: 2026, month: 2)
        XCTAssertEqual(vm.rowCount, 4)
    }

    func test_build_march2026_has5Rows() {
        // March 2026: starts Sunday, 31 days → 5 rows
        let vm = CalendarMonthViewModel.build(year: 2026, month: 3)
        XCTAssertEqual(vm.rowCount, 5)
    }

    func test_build_january2026_has5Rows() {
        // Jan 2026: 4 leading + 31 days = 35 slots → 5 rows
        let vm = CalendarMonthViewModel.build(year: 2026, month: 1)
        XCTAssertEqual(vm.rowCount, 5)
    }

    func test_build_rowCountNeverExceeds6() {
        for month in 1...12 {
            let vm = CalendarMonthViewModel.build(year: 2026, month: month)
            XCTAssertLessThanOrEqual(vm.rowCount, CalendarMonthViewModel.maxGridRows,
                                     "Month \(month) exceeds max rows")
            XCTAssertGreaterThanOrEqual(vm.rowCount, 4,
                                        "Month \(month) has fewer than 4 rows")
        }
    }

    // MARK: - Grid Slot Count

    func test_build_gridSlotCountIsRowCountTimesColumns() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 3)
        XCTAssertEqual(vm.gridSlotCount, vm.rowCount * CalendarMonthViewModel.gridColumns)
    }

    func test_build_february2026_gridSlotCount28() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 2)
        // 4 rows × 7 = 28
        XCTAssertEqual(vm.gridSlotCount, 28)
    }

    // MARK: - Current Month Days

    func test_build_march2026_has31Days() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 3)
        XCTAssertEqual(vm.dayItems.count, 31)
    }

    func test_build_february2026_has28Days() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 2)
        XCTAssertEqual(vm.dayItems.count, 28)
    }

    func test_build_april2026_has30Days() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 4)
        XCTAssertEqual(vm.dayItems.count, 30)
    }

    // MARK: - Today Highlight

    func test_build_todayMarkedCorrectly() {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)

        let vm = CalendarMonthViewModel.build(year: year, month: month)
        let todayItems = vm.dayItems.filter { $0.isToday }

        XCTAssertEqual(todayItems.count, 1)
        XCTAssertEqual(todayItems.first?.day, day)
    }

    func test_build_noTodayInDifferentMonth() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)

        if currentYear != 2026 || currentMonth != 1 {
            let vm = CalendarMonthViewModel.build(year: 2026, month: 1)
            let todayItems = vm.dayItems.filter { $0.isToday }
            XCTAssertTrue(todayItems.isEmpty)
        }
    }

    // MARK: - buildAllMonths

    func test_buildAllMonths_startsFromJanuary2026() {
        let months = CalendarMonthViewModel.buildAllMonths()
        XCTAssertFalse(months.isEmpty)
        XCTAssertEqual(months.first?.year, 2026)
        XCTAssertEqual(months.first?.month, 1)
    }

    func test_buildAllMonths_endsAtCurrentMonth() {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        let months = CalendarMonthViewModel.buildAllMonths()
        XCTAssertEqual(months.last?.year, currentYear)
        XCTAssertEqual(months.last?.month, currentMonth)
    }

    func test_buildAllMonths_monthCountMatchesExpected() {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        let expectedCount = (currentYear - 2026) * 12 + currentMonth
        let months = CalendarMonthViewModel.buildAllMonths()

        XCTAssertEqual(months.count, expectedCount)
    }

    // MARK: - Day Sequence

    func test_build_daysAreSequential() {
        let vm = CalendarMonthViewModel.build(year: 2026, month: 6)
        let days = vm.dayItems.map { $0.day }
        XCTAssertEqual(days, Array(1...30))
    }
}
