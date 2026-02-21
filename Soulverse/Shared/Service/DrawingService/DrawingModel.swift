//
//  DrawingModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

struct DrawingModel: Codable {
    @DocumentID var id: String?

    // Relationship
    var checkinId: String?
    let isFromCheckIn: Bool

    // Files (Firebase Storage URLs)
    let imageURL: String
    let recordingURL: String
    var thumbnailURL: String?

    // Metadata
    var promptUsed: String?

    // Timezone
    let timezoneOffsetMinutes: Int

    // Timestamps
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case checkinId
        case isFromCheckIn
        case imageURL
        case recordingURL
        case thumbnailURL
        case promptUsed
        case timezoneOffsetMinutes
        case createdAt
        case updatedAt
    }
}
