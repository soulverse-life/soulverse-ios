//
//  JournalModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

struct JournalModel: Codable {
    @DocumentID var id: String?

    // Content
    var title: String?
    var content: String?
    var prompt: String?

    // Relationship
    let checkinId: String

    // Timezone
    let timezoneOffsetMinutes: Int

    // Timestamps
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case prompt
        case checkinId
        case timezoneOffsetMinutes
        case createdAt
        case updatedAt
    }
}
