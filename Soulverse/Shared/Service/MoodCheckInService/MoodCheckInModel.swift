//
//  MoodCheckInModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

struct MoodCheckInModel: Codable {
    @DocumentID var id: String?

    // Sensing
    let colorHex: String
    let colorIntensity: Double

    // Naming
    let emotion: String

    // Attributing
    let topic: String

    // Evaluating
    let evaluation: String

    // Journal (optional)
    var journal: String?

    // Timezone
    let timezoneOffsetMinutes: Int

    // Timestamps
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case colorHex
        case colorIntensity
        case emotion
        case topic
        case evaluation
        case journal
        case timezoneOffsetMinutes
        case createdAt
        case updatedAt
    }
}
