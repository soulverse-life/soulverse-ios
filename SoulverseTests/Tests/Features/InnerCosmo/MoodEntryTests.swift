//
//  MoodEntryTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class MoodEntryTests: XCTestCase {

    // MARK: - hasArtwork

    func test_MoodEntry_hasArtwork_trueWhenURLsPresent() {
        let entry = makeMoodEntry(artworkURLs: ["https://example.com/art.png"])
        XCTAssertTrue(entry.hasArtwork)
    }

    func test_MoodEntry_hasArtwork_falseWhenURLsEmpty() {
        let entry = makeMoodEntry(artworkURLs: [])
        XCTAssertFalse(entry.hasArtwork)
    }

    func test_MoodEntry_hasArtwork_trueWithMultipleURLs() {
        let entry = makeMoodEntry(artworkURLs: [
            "https://example.com/art1.png",
            "https://example.com/art2.png"
        ])
        XCTAssertTrue(entry.hasArtwork)
    }

    // MARK: - formattedDate

    func test_MoodEntry_formattedDate_returnsExpectedFormat() {
        // Use a fixed date: March 15, 2026
        let date = TestHelpers.date(2026, 3, 15)
        let entry = makeMoodEntry(date: date)

        // Verify using the same formatter logic (locale-independent check)
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let expected = formatter.string(from: date)
        XCTAssertEqual(entry.formattedDate, expected)
    }

    // MARK: - Mock Data

    func test_MoodEntry_mockData_isNonEmpty() {
        XCTAssertFalse(MoodEntry.mockData.isEmpty)
        XCTAssertEqual(MoodEntry.mockData.count, 5)
    }

    func test_MoodEntry_mockData_allHaveUniqueIds() {
        let ids = MoodEntry.mockData.map { $0.id }
        XCTAssertEqual(Set(ids).count, ids.count, "Mock data has duplicate IDs")
    }
}

// MARK: - Helpers

private extension MoodEntryTests {
    func makeMoodEntry(
        artworkURLs: [String] = [],
        date: Date = Date()
    ) -> MoodEntry {
        return MoodEntry(
            id: "test-id",
            emotion: .joy,
            date: date,
            journal: "Test response",
            colorHex: "#FFD700",
            colorIntensity: 0.8,
            artworkURLs: artworkURLs,
            topic: .emotional
        )
    }
}
