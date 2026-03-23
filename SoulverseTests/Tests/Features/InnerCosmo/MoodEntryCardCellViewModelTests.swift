//
//  MoodEntryCardCellViewModelTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class MoodEntryCardCellViewModelTests: XCTestCase {

    // MARK: - hasArtwork

    func test_MoodEntryCardCellViewModel_hasArtwork_trueWhenURLsPresent() {
        let entry = makeMoodEntryCardCellViewModel(artworkURLs: ["https://example.com/art.png"])
        XCTAssertTrue(entry.hasArtwork)
    }

    func test_MoodEntryCardCellViewModel_hasArtwork_falseWhenURLsEmpty() {
        let entry = makeMoodEntryCardCellViewModel(artworkURLs: [])
        XCTAssertFalse(entry.hasArtwork)
    }

    func test_MoodEntryCardCellViewModel_hasArtwork_trueWithMultipleURLs() {
        let entry = makeMoodEntryCardCellViewModel(artworkURLs: [
            "https://example.com/art1.png",
            "https://example.com/art2.png"
        ])
        XCTAssertTrue(entry.hasArtwork)
    }

    // MARK: - formattedDate

    func test_MoodEntryCardCellViewModel_formattedDate_returnsExpectedFormat() {
        // Use a fixed date: March 15, 2026
        let date = TestHelpers.date(2026, 3, 15)
        let entry = makeMoodEntryCardCellViewModel(date: date)

        // Verify using the same formatter logic (locale-independent check)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let expected = formatter.string(from: date)
        XCTAssertEqual(entry.formattedDate, expected)
    }

    // MARK: - Mock Data

    func test_MoodEntryCardCellViewModel_mockData_isNonEmpty() {
        XCTAssertFalse(MoodEntryCardCellViewModel.mockData.isEmpty)
        XCTAssertEqual(MoodEntryCardCellViewModel.mockData.count, 5)
    }

    func test_MoodEntryCardCellViewModel_mockData_allHaveUniqueDates() {
        let dates = MoodEntryCardCellViewModel.mockData.map { $0.formattedDate }
        XCTAssertEqual(Set(dates).count, dates.count, "Mock data has duplicate dates")
    }
}

// MARK: - Helpers

private extension MoodEntryCardCellViewModelTests {
    func makeMoodEntryCardCellViewModel(
        artworkURLs: [String] = [],
        date: Date = Date()
    ) -> MoodEntryCardCellViewModel {
        return MoodEntryCardCellViewModel(
            checkinId: "test-checkin-id",
            emotion: .joy,
            date: date,
            reflection: "Test response",
            artworkURLs: artworkURLs
        )
    }
}

// MARK: - Test Mock Data

extension MoodEntryCardCellViewModel {

    static let mockData: [MoodEntryCardCellViewModel] = [
        MoodEntryCardCellViewModel(
            checkinId: "mock-1",
            emotion: .joy,
            date: Date().addingTimeInterval(-86400),
            reflection: "The joy is in the journey, not the destination",
            artworkURLs: []
        ),
        MoodEntryCardCellViewModel(
            checkinId: "mock-2",
            emotion: .fear,
            date: Date().addingTimeInterval(-172800),
            reflection: "It feels like standing at the edge of a cliff, looking down",
            artworkURLs: []
        ),
        MoodEntryCardCellViewModel(
            checkinId: "mock-3",
            emotion: .serenity,
            date: Date().addingTimeInterval(-259200),
            reflection: "A gentle wave washing over warm sand",
            artworkURLs: ["https://example.com/artwork1.png"]
        ),
        MoodEntryCardCellViewModel(
            checkinId: "mock-4",
            emotion: .love,
            date: Date().addingTimeInterval(-345600),
            reflection: "Warmth spreading from my heart to my fingertips",
            artworkURLs: []
        ),
        MoodEntryCardCellViewModel(
            checkinId: "mock-5",
            emotion: .anticipation,
            date: Date().addingTimeInterval(-432000),
            reflection: "Like the moment before opening a gift",
            artworkURLs: ["https://example.com/artwork2.png"]
        )
    ]
}
