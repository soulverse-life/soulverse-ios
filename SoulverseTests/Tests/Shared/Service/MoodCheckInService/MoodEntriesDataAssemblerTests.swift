//
//  MoodEntriesDataAssemblerTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class MoodEntriesDataAssemblerTests: XCTestCase {

    // MARK: - Empty Inputs

    func test_assembleCards_emptyCheckInsAndDrawings_returnsEmpty() {
        let cards = MoodEntriesDataAssembler.assembleCards(checkIns: [], drawings: [])
        XCTAssertTrue(cards.isEmpty)
    }

    // MARK: - Single Check-In

    func test_assembleCards_singleCheckIn_noDrawings_returnsSingleCard() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        let cards = MoodEntriesDataAssembler.assembleCards(checkIns: [checkIn], drawings: [])

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].checkIn?.id, "c1")
        XCTAssertTrue(cards[0].drawings.isEmpty)
        XCTAssertFalse(cards[0].isOrphan)
    }

    func test_assembleCards_singleCheckIn_withLinkedDrawing_attachesDrawing() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        let drawing = makeDrawing(id: "d1", checkinId: "c1", createdAt: date(2026, 2, 20, 10, 5))

        let cards = MoodEntriesDataAssembler.assembleCards(checkIns: [checkIn], drawings: [drawing])

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].drawings.count, 1)
        XCTAssertEqual(cards[0].drawings[0].id, "d1")
    }

    // MARK: - Standalone Drawings

    func test_assembleCards_standaloneDrawing_afterCheckIn_attachesToPrecedingCheckIn() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        // Standalone drawing (no checkinId) created after check-in
        let drawing = makeDrawing(id: "d1", checkinId: nil, createdAt: date(2026, 2, 20, 14, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(checkIns: [checkIn], drawings: [drawing])

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].checkIn?.id, "c1")
        XCTAssertEqual(cards[0].drawings.count, 1)
        XCTAssertEqual(cards[0].drawings[0].id, "d1")
    }

    func test_assembleCards_standaloneDrawing_beforeAllCheckIns_becomesOrphanCard() {
        // Drawing happens before the check-in
        let drawing = makeDrawing(id: "d1", checkinId: nil, createdAt: date(2026, 2, 19, 8, 0))
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(checkIns: [checkIn], drawings: [drawing])

        XCTAssertEqual(cards.count, 2)

        // First card (most recent) is the check-in card
        let checkInCard = cards.first { !$0.isOrphan }
        XCTAssertNotNil(checkInCard)
        XCTAssertEqual(checkInCard?.checkIn?.id, "c1")

        // Second card is the orphan
        let orphanCard = cards.first { $0.isOrphan }
        XCTAssertNotNil(orphanCard)
        XCTAssertEqual(orphanCard?.drawings.count, 1)
        XCTAssertEqual(orphanCard?.drawings[0].id, "d1")
    }

    // MARK: - Multiple Check-Ins

    func test_assembleCards_multipleCheckIns_sortedByDateDescending() {
        let c1 = makeCheckIn(id: "c1", createdAt: date(2026, 2, 18, 10, 0))
        let c2 = makeCheckIn(id: "c2", createdAt: date(2026, 2, 19, 10, 0))
        let c3 = makeCheckIn(id: "c3", createdAt: date(2026, 2, 20, 10, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [c1, c2, c3],
            drawings: []
        )

        XCTAssertEqual(cards.count, 3)
        // Most recent first
        XCTAssertEqual(cards[0].checkIn?.id, "c3")
        XCTAssertEqual(cards[1].checkIn?.id, "c2")
        XCTAssertEqual(cards[2].checkIn?.id, "c1")
    }

    func test_assembleCards_multipleCheckInsSameDay_producesMultipleCards() {
        let c1 = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 9, 0))
        let c2 = makeCheckIn(id: "c2", createdAt: date(2026, 2, 20, 15, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(checkIns: [c1, c2], drawings: [])

        XCTAssertEqual(cards.count, 2)
        // Most recent first
        XCTAssertEqual(cards[0].checkIn?.id, "c2")
        XCTAssertEqual(cards[1].checkIn?.id, "c1")
    }

    // MARK: - Drawings Between Check-Ins

    func test_assembleCards_drawingBetweenCheckIns_assignedToPrecedingCheckIn() {
        let c1 = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 9, 0))
        let c2 = makeCheckIn(id: "c2", createdAt: date(2026, 2, 20, 15, 0))
        // Standalone drawing between c1 and c2
        let drawing = makeDrawing(id: "d1", checkinId: nil, createdAt: date(2026, 2, 20, 12, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [c1, c2],
            drawings: [drawing]
        )

        XCTAssertEqual(cards.count, 2)

        // The drawing should be attached to c1 (preceding check-in)
        let c1Card = cards.first { $0.checkIn?.id == "c1" }
        XCTAssertEqual(c1Card?.drawings.count, 1)
        XCTAssertEqual(c1Card?.drawings[0].id, "d1")

        // c2 should have no drawings
        let c2Card = cards.first { $0.checkIn?.id == "c2" }
        XCTAssertEqual(c2Card?.drawings.count, 0)
    }

    // MARK: - Mixed Linked and Standalone Drawings

    func test_assembleCards_mixedLinkedAndStandaloneDrawings_correctlyAssigned() {
        let c1 = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        // Linked drawing (created during check-in)
        let d1 = makeDrawing(id: "d1", checkinId: "c1", createdAt: date(2026, 2, 20, 10, 5))
        // Standalone drawing after check-in
        let d2 = makeDrawing(id: "d2", checkinId: nil, createdAt: date(2026, 2, 20, 14, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [c1],
            drawings: [d1, d2]
        )

        XCTAssertEqual(cards.count, 1)
        XCTAssertEqual(cards[0].drawings.count, 2)
        // Both drawings should be attached to c1
        let drawingIds = cards[0].drawings.map { $0.id }
        XCTAssertTrue(drawingIds.contains("d1"))
        XCTAssertTrue(drawingIds.contains("d2"))
    }

    // MARK: - Orphan Card Properties

    func test_MoodEntryCard_isOrphan_trueWhenNoCheckIn() {
        let card = MoodEntryCard(checkIn: nil, drawings: [], date: Date())
        XCTAssertTrue(card.isOrphan)
    }

    func test_MoodEntryCard_isOrphan_falseWhenHasCheckIn() {
        let checkIn = makeCheckIn(id: "c1", createdAt: Date())
        let card = MoodEntryCard(checkIn: checkIn, drawings: [], date: Date())
        XCTAssertFalse(card.isOrphan)
    }

    // MARK: - Orphan Grouping by Day

    func test_assembleCards_multipleOrphanDrawingsSameDay_groupedIntoOneCard() {
        // Two standalone drawings on the same day, before any check-in
        let d1 = makeDrawing(id: "d1", checkinId: nil, createdAt: date(2026, 2, 18, 9, 0))
        let d2 = makeDrawing(id: "d2", checkinId: nil, createdAt: date(2026, 2, 18, 14, 0))
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [checkIn],
            drawings: [d1, d2]
        )

        let orphanCards = cards.filter { $0.isOrphan }
        XCTAssertEqual(orphanCards.count, 1)
        XCTAssertEqual(orphanCards[0].drawings.count, 2)
    }

    func test_assembleCards_orphanDrawingsDifferentDays_separateCards() {
        let d1 = makeDrawing(id: "d1", checkinId: nil, createdAt: date(2026, 2, 17, 9, 0))
        let d2 = makeDrawing(id: "d2", checkinId: nil, createdAt: date(2026, 2, 18, 14, 0))
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [checkIn],
            drawings: [d1, d2]
        )

        let orphanCards = cards.filter { $0.isOrphan }
        XCTAssertEqual(orphanCards.count, 2)
    }

    // MARK: - Only Drawings, No Check-Ins

    func test_assembleCards_onlyDrawings_noCheckIns_allBecomeOrphanCards() {
        let d1 = makeDrawing(id: "d1", checkinId: nil, createdAt: date(2026, 2, 20, 10, 0))
        let d2 = makeDrawing(id: "d2", checkinId: nil, createdAt: date(2026, 2, 21, 10, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [],
            drawings: [d1, d2]
        )

        // All drawings should be orphan cards
        XCTAssertEqual(cards.count, 2)
        XCTAssertTrue(cards.allSatisfy { $0.isOrphan })
    }

    // MARK: - Drawing Sorting Within Cards

    func test_assembleCards_drawingsWithinCard_sortedByDateAscending() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        let d1 = makeDrawing(id: "d1", checkinId: "c1", createdAt: date(2026, 2, 20, 12, 0))
        let d2 = makeDrawing(id: "d2", checkinId: "c1", createdAt: date(2026, 2, 20, 10, 5))
        let d3 = makeDrawing(id: "d3", checkinId: "c1", createdAt: date(2026, 2, 20, 11, 0))

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [checkIn],
            drawings: [d1, d2, d3]
        )

        XCTAssertEqual(cards[0].drawings.count, 3)
        // Drawings should be sorted ascending by createdAt
        XCTAssertEqual(cards[0].drawings[0].id, "d2") // 10:05
        XCTAssertEqual(cards[0].drawings[1].id, "d3") // 11:00
        XCTAssertEqual(cards[0].drawings[2].id, "d1") // 12:00
    }

    // MARK: - Edge Cases

    func test_assembleCards_drawingWithNilCreatedAt_isSkipped() {
        let checkIn = makeCheckIn(id: "c1", createdAt: date(2026, 2, 20, 10, 0))
        // Standalone drawing with nil createdAt (no checkinId either)
        let drawing = makeDrawing(id: "d1", checkinId: nil, createdAt: nil)

        let cards = MoodEntriesDataAssembler.assembleCards(
            checkIns: [checkIn],
            drawings: [drawing]
        )

        // The nil-date standalone drawing should be skipped
        XCTAssertEqual(cards.count, 1)
        XCTAssertTrue(cards[0].drawings.isEmpty)
    }
}

// MARK: - Test Helpers

private extension MoodEntriesDataAssemblerTests {

    func makeCheckIn(
        id: String,
        createdAt: Date?
    ) -> MoodCheckInModel {
        return MoodCheckInModel(
            id: id,
            colorHex: "#FF5733",
            colorIntensity: 0.8,
            emotion: "happy",
            topic: "work",
            evaluation: "positive",
            journal: nil,
            timezoneOffsetMinutes: 480,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    func makeDrawing(
        id: String,
        checkinId: String?,
        createdAt: Date?
    ) -> DrawingModel {
        return DrawingModel(
            id: id,
            checkinId: checkinId,
            isFromCheckIn: checkinId != nil,
            imageURL: "https://storage.example.com/\(id)/image.png",
            recordingURL: "https://storage.example.com/\(id)/recording.pkd",
            thumbnailURL: nil,
            promptUsed: nil,
            timezoneOffsetMinutes: 480,
            createdAt: createdAt,
            updatedAt: createdAt
        )
    }

    /// Creates a Date for the given components (UTC).
    func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
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
