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
    var templateName: String?

    // Reflection — optional, can be filled in later via DrawingReflectionView.
    // `reflectiveQuestion` is captured at save time (snapshot of the prompt's
    // reflective question, or a generic fallback for free drawings).
    var reflectiveQuestion: String?
    var reflectiveAnswer: String?
    @ServerTimestamp var reflectionAnsweredAt: Date?

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
        case templateName
        case reflectiveQuestion
        case reflectiveAnswer
        case reflectionAnsweredAt
        case timezoneOffsetMinutes
        case createdAt
        case updatedAt
    }
}
