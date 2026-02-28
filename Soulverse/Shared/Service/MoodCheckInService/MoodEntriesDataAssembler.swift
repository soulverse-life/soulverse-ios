//
//  MoodEntriesDataAssembler.swift
//  Soulverse
//

import Foundation

/// Represents a single card in the MoodEntriesSection.
/// Can be a check-in card (with optional drawings) or an orphan card (drawings only).
struct MoodEntryCard {

    /// The mood check-in data, nil for orphan (drawing-only) cards.
    let checkIn: MoodCheckInModel?

    /// Drawings associated with this card (max display count enforced by UI).
    let drawings: [DrawingModel]

    /// The date this card represents.
    let date: Date

    /// Whether this is an orphan card (no check-in, drawings only).
    var isOrphan: Bool {
        return checkIn == nil
    }
}

/// Assembles MoodEntryCards from check-ins and drawings.
///
/// Card assembly rules:
/// 1. Each check-in becomes its own card
/// 2. Drawings with checkinId attach to that check-in's card
/// 3. Standalone drawings between check-ins attach to the preceding check-in's card
/// 4. Drawings on days with no check-in become orphan cards (grouped by day)
/// 5. Multiple check-ins per day produce multiple cards
final class MoodEntriesDataAssembler {

    private let moodCheckInService: MoodCheckInServiceProtocol
    private let drawingService: DrawingServiceProtocol

    init(moodCheckInService: MoodCheckInServiceProtocol = FirestoreMoodCheckInService.shared,
         drawingService: DrawingServiceProtocol = FirestoreDrawingService.shared) {
        self.moodCheckInService = moodCheckInService
        self.drawingService = drawingService
    }

    /// Fetches the latest X check-ins and associated drawings, then assembles cards.
    func fetchAndAssemble(
        uid: String,
        checkInLimit: Int,
        completion: @escaping (Result<[MoodEntryCard], Error>) -> Void
    ) {
        // Step 1: Fetch latest X check-ins
        moodCheckInService.fetchLatestCheckIns(uid: uid, limit: checkInLimit) { [weak self] checkInResult in
            guard let self = self else { return }
            switch checkInResult {
            case .failure(let error):
                completion(.failure(error))
                return

            case .success(let checkIns):
                guard !checkIns.isEmpty else {
                    // No check-ins — fetch recent drawings as orphan cards
                    self.fetchOrphanDrawings(uid: uid, completion: completion)
                    return
                }

                // Step 2: Derive date range from oldest check-in
                guard let oldestDate = checkIns.last?.createdAt else {
                    completion(.success([]))
                    return
                }

                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: oldestDate)

                // Step 3: Fetch all drawings in date range
                self.drawingService.fetchDrawings(uid: uid, from: startOfDay, to: nil) { drawingResult in
                    switch drawingResult {
                    case .failure(let error):
                        completion(.failure(error))
                        return

                    case .success(let drawings):
                        // Step 4: Assemble cards
                        let cards = Self.assembleCards(checkIns: checkIns, drawings: drawings)
                        completion(.success(cards))
                    }
                }
            }
        }
    }

    /// Assembles cards from check-ins and drawings.
    /// Check-ins should be sorted by createdAt descending (as returned by fetchLatestCheckIns).
    /// Drawings should be sorted by createdAt descending (as returned by fetchDrawings).
    static func assembleCards(
        checkIns: [MoodCheckInModel],
        drawings: [DrawingModel]
    ) -> [MoodEntryCard] {
        let calendar = Calendar.current

        // Sort check-ins by date ascending for interval-based assignment
        let sortedCheckIns = checkIns.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }

        // Separate drawings: linked (have checkinId) vs standalone
        var linkedDrawings: [String: [DrawingModel]] = [:]
        var standaloneDrawings: [DrawingModel] = []

        for drawing in drawings {
            if let checkinId = drawing.checkinId {
                linkedDrawings[checkinId, default: []].append(drawing)
            } else {
                standaloneDrawings.append(drawing)
            }
        }

        // Sort standalone drawings by date ascending for interval assignment
        let sortedStandalone = standaloneDrawings.sorted {
            ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
        }

        // Assign standalone drawings to check-ins or orphan buckets
        var checkInDrawings: [String: [DrawingModel]] = linkedDrawings
        var orphanDrawingsByDay: [DateComponents: [DrawingModel]] = [:]

        for drawing in sortedStandalone {
            guard let drawingDate = drawing.createdAt else { continue }

            // Find the preceding check-in (latest check-in before this drawing)
            let precedingCheckIn = sortedCheckIns.last { checkIn in
                guard let checkInDate = checkIn.createdAt else { return false }
                return checkInDate <= drawingDate
            }

            if let checkIn = precedingCheckIn, let checkInId = checkIn.id {
                checkInDrawings[checkInId, default: []].append(drawing)
            } else {
                // No preceding check-in — orphan card grouped by day
                let dayComponents = calendar.dateComponents([.year, .month, .day], from: drawingDate)
                orphanDrawingsByDay[dayComponents, default: []].append(drawing)
            }
        }

        // Build cards from check-ins
        var cards: [MoodEntryCard] = sortedCheckIns.map { checkIn in
            let drawings = checkInDrawings[checkIn.id ?? "", default: []]
                .sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            return MoodEntryCard(
                checkIn: checkIn,
                drawings: drawings,
                date: checkIn.createdAt ?? Date()
            )
        }

        // Build orphan cards from drawing-only days
        for (_, dayDrawings) in orphanDrawingsByDay {
            let sorted = dayDrawings.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
            if let firstDate = sorted.first?.createdAt {
                cards.append(MoodEntryCard(
                    checkIn: nil,
                    drawings: sorted,
                    date: firstDate
                ))
            }
        }

        // Sort all cards by date descending (most recent first)
        cards.sort { $0.date > $1.date }

        return cards
    }

    // MARK: - Private

    /// Fetches recent drawings when there are no check-ins (all become orphan cards).
    private func fetchOrphanDrawings(
        uid: String,
        completion: @escaping (Result<[MoodEntryCard], Error>) -> Void
    ) {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        drawingService.fetchDrawings(uid: uid, from: sevenDaysAgo, to: nil) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let drawings):
                let calendar = Calendar.current
                var byDay: [DateComponents: [DrawingModel]] = [:]

                for drawing in drawings {
                    guard let date = drawing.createdAt else { continue }
                    let day = calendar.dateComponents([.year, .month, .day], from: date)
                    byDay[day, default: []].append(drawing)
                }

                let cards: [MoodEntryCard] = byDay.compactMap { _, dayDrawings in
                    let sorted = dayDrawings.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
                    guard let firstDate = sorted.first?.createdAt else { return nil }
                    return MoodEntryCard(checkIn: nil, drawings: sorted, date: firstDate)
                }.sorted { $0.date > $1.date }

                completion(.success(cards))
            }
        }
    }
}
