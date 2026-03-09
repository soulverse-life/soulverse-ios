//
//  MoodEntryCardCellViewModel.swift
//  Soulverse
//
//  View model for MoodEntryCardCell displayed in InnerCosmos.
//

import Foundation

struct MoodEntryCardCellViewModel {

    // MARK: - Constants

    static let maxArtworkCount = 4

    // MARK: - Properties

    let emotion: RecordedEmotion?
    let date: Date
    let journal: String?
    let artworkURLs: [String]

    // MARK: - Computed Properties

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var formattedDate: String {
        MoodEntryCardCellViewModel.dateFormatter.string(from: date)
    }

    var hasArtwork: Bool { !artworkURLs.isEmpty }
}
