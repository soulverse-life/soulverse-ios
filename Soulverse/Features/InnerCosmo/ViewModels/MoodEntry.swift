//
//  MoodEntry.swift
//  Soulverse
//
//  Data model for mood entry cards displayed in InnerCosmos.
//

import UIKit

struct MoodEntry {

    // MARK: - Properties

    let id: String
    let emotion: RecordedEmotion
    let date: Date
    let journal: String
    let colorHex: String
    let colorIntensity: Double
    let artworkURLs: [String]
    let topic: Topic?

    // MARK: - Computed Properties

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    var formattedDate: String {
        MoodEntry.dateFormatter.string(from: date)
    }

    var color: UIColor {
        UIColor(hex: colorHex) ?? .themeTextSecondary
    }

    var hasArtwork: Bool { !artworkURLs.isEmpty }
}

// MARK: - Mock Data

extension MoodEntry {

    static let mockData: [MoodEntry] = [
        MoodEntry(
            id: "1",
            emotion: .joy,
            date: Date().addingTimeInterval(-86400), // 1 day ago
            journal: "The joy is in the journey, not the destination",
            colorHex: "#FFD700",
            colorIntensity: 0.8,
            artworkURLs: [],
            topic: .emotional
        ),
        MoodEntry(
            id: "2",
            emotion: .fear,
            date: Date().addingTimeInterval(-172800), // 2 days ago
            journal: "It feels like standing at the edge of a cliff, looking down",
            colorHex: "#4A4A8A",
            colorIntensity: 0.6,
            artworkURLs: [],
            topic: .spiritual
        ),
        MoodEntry(
            id: "3",
            emotion: .serenity,
            date: Date().addingTimeInterval(-259200), // 3 days ago
            journal: "A gentle wave washing over warm sand",
            colorHex: "#87CEEB",
            colorIntensity: 0.5,
            artworkURLs: ["https://example.com/artwork1.png"],
            topic: .physical
        ),
        MoodEntry(
            id: "4",
            emotion: .love,
            date: Date().addingTimeInterval(-345600), // 4 days ago
            journal: "Warmth spreading from my heart to my fingertips",
            colorHex: "#FF6B6B",
            colorIntensity: 0.9,
            artworkURLs: [],
            topic: .social
        ),
        MoodEntry(
            id: "5",
            emotion: .anticipation,
            date: Date().addingTimeInterval(-432000), // 5 days ago
            journal: "Like the moment before opening a gift",
            colorHex: "#FFA500",
            colorIntensity: 0.7,
            artworkURLs: ["https://example.com/artwork2.png"],
            topic: .occupational
        )
    ]
}
