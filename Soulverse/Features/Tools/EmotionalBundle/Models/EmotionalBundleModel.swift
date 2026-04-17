//
//  EmotionalBundleModel.swift
//  Soulverse
//

import Foundation
import FirebaseFirestore

// MARK: - Main Bundle Model

struct EmotionalBundleModel: Codable {
    @DocumentID var id: String?
    var version: Int
    var redFlags: [RedFlagItem]
    var supportMe: [SupportContact]
    var feelCalm: [CalmActivity]
    var staySafe: [SafetyAction]
    var professionalSupport: [ProfessionalContact]
    @ServerTimestamp var createdAt: Date?
    @ServerTimestamp var updatedAt: Date?

    init(
        version: Int = 1,
        redFlags: [RedFlagItem] = [],
        supportMe: [SupportContact] = [],
        feelCalm: [CalmActivity] = [],
        staySafe: [SafetyAction] = [],
        professionalSupport: [ProfessionalContact] = []
    ) {
        self.version = version
        self.redFlags = redFlags
        self.supportMe = supportMe
        self.feelCalm = feelCalm
        self.staySafe = staySafe
        self.professionalSupport = professionalSupport
    }

    static func empty() -> EmotionalBundleModel {
        return EmotionalBundleModel()
    }
}

// Custom decoder for forward-compatible field additions
extension EmotionalBundleModel {
    enum CodingKeys: String, CodingKey {
        case id, version, redFlags, supportMe, feelCalm, staySafe, professionalSupport, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decodeIfPresent(DocumentID<String>.self, forKey: .id) ?? .init(wrappedValue: nil)
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        redFlags = try container.decodeIfPresent([RedFlagItem].self, forKey: .redFlags) ?? []
        supportMe = try container.decodeIfPresent([SupportContact].self, forKey: .supportMe) ?? []
        feelCalm = try container.decodeIfPresent([CalmActivity].self, forKey: .feelCalm) ?? []
        staySafe = try container.decodeIfPresent([SafetyAction].self, forKey: .staySafe) ?? []
        professionalSupport = try container.decodeIfPresent([ProfessionalContact].self, forKey: .professionalSupport) ?? []
        _createdAt = try container.decodeIfPresent(ServerTimestamp<Date>.self, forKey: .createdAt) ?? .init(wrappedValue: nil)
        _updatedAt = try container.decodeIfPresent(ServerTimestamp<Date>.self, forKey: .updatedAt) ?? .init(wrappedValue: nil)
    }
}

// MARK: - Section Item Models

struct RedFlagItem: Codable, Identifiable {
    var id: String
    var text: String
    var sortOrder: Int

    init(text: String = "", sortOrder: Int) {
        self.id = "rf_\(UUID().uuidString.prefix(8))"
        self.text = text
        self.sortOrder = sortOrder
    }
}

struct SupportContact: Codable, Identifiable {
    var id: String
    var name: String
    var phone: String?
    var email: String?
    var relationship: String?
    var sortOrder: Int

    init(name: String = "", phone: String? = nil, email: String? = nil, relationship: String? = nil, sortOrder: Int) {
        self.id = "sm_\(UUID().uuidString.prefix(8))"
        self.name = name
        self.phone = phone
        self.email = email
        self.relationship = relationship
        self.sortOrder = sortOrder
    }
}

struct CalmActivity: Codable, Identifiable {
    var id: String
    var text: String
    var sortOrder: Int

    init(text: String = "", sortOrder: Int) {
        self.id = "fc_\(UUID().uuidString.prefix(8))"
        self.text = text
        self.sortOrder = sortOrder
    }
}

struct SafetyAction: Codable, Identifiable {
    var id: String
    var text: String
    var sortOrder: Int

    init(text: String = "", sortOrder: Int) {
        self.id = "ss_\(UUID().uuidString.prefix(8))"
        self.text = text
        self.sortOrder = sortOrder
    }
}

struct ProfessionalContact: Codable, Identifiable {
    var id: String
    var placeName: String?
    var contactName: String?
    var phone: String?
    var sortOrder: Int

    init(placeName: String? = nil, contactName: String? = nil, phone: String? = nil, sortOrder: Int) {
        self.id = "ps_\(UUID().uuidString.prefix(8))"
        self.placeName = placeName
        self.contactName = contactName
        self.phone = phone
        self.sortOrder = sortOrder
    }
}

// MARK: - Section Identifiers

enum EmotionalBundleSection: String, CaseIterable {
    case redFlags
    case supportMe
    case feelCalm
    case staySafe
    case professionalSupport

    var displayTitle: String {
        switch self {
        case .redFlags: return NSLocalizedString("emotional_bundle_section_red_flags", comment: "")
        case .supportMe: return NSLocalizedString("emotional_bundle_section_support_me", comment: "")
        case .feelCalm: return NSLocalizedString("emotional_bundle_section_feel_calm", comment: "")
        case .staySafe: return NSLocalizedString("emotional_bundle_section_stay_safe", comment: "")
        case .professionalSupport: return NSLocalizedString("emotional_bundle_section_professional_support", comment: "")
        }
    }

    var iconName: String {
        switch self {
        case .redFlags: return "exclamationmark.triangle"
        case .supportMe: return "person.2"
        case .feelCalm: return "leaf"
        case .staySafe: return "shield"
        case .professionalSupport: return "stethoscope"
        }
    }
}

// MARK: - Section Data (for partial saves)

enum EmotionalBundleSectionData {
    case redFlags([RedFlagItem])
    case supportMe([SupportContact])
    case feelCalm([CalmActivity])
    case staySafe([SafetyAction])
    case professionalSupport([ProfessionalContact])
}
