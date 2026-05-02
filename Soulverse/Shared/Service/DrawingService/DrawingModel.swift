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
    /// Set server-side via `FirestoreDrawingService.updateDrawingReflection`. We
    /// deliberately don't use `@ServerTimestamp` here: the field is absent on
    /// new drawings (no answer yet), and the wrapper's auto-synthesized
    /// Codable init throws `keyNotFound` on absent keys — breaking decode for
    /// every drawing in the "saved but reflection-not-yet-submitted" state.
    /// Plain `Date?` lets Codable's decodeIfPresent path treat absence as nil.
    var reflectionAnsweredAt: Date?

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
