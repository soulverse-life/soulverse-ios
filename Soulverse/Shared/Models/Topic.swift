//
//  Topic.swift
//  Soulverse
//
//

import UIKit

enum Topic: String, CaseIterable {
    case physical = "Physical"
    case emotional = "Emotional"
    case social = "Social"
    case intellectual = "Intellectual"
    case spiritual = "Spiritual"
    case occupational = "Occupational"
    case environment = "Environment"
    case financial = "Financial"

    // MARK: - Localization

    var localizedTitle: String {
        switch self {
        case .physical:
            return NSLocalizedString("topic_physical", comment: "")
        case .emotional:
            return NSLocalizedString("topic_emotional", comment: "")
        case .social:
            return NSLocalizedString("topic_social", comment: "")
        case .intellectual:
            return NSLocalizedString("topic_intellectual", comment: "")
        case .spiritual:
            return NSLocalizedString("topic_spiritual", comment: "")
        case .occupational:
            return NSLocalizedString("topic_occupational", comment: "")
        case .environment:
            return NSLocalizedString("topic_environment", comment: "")
        case .financial:
            return NSLocalizedString("topic_financial", comment: "")
        }
    }

    // MARK: - Visual Properties

    var iconImage: UIImage {
        let symbolName: String
        switch self {
        case .physical: symbolName = "figure.mind.and.body"
        case .emotional: symbolName = "face.smiling"
        case .social: symbolName = "person.line.dotted.person.fill"
        case .intellectual: symbolName = "light.max"
        case .spiritual: symbolName = "water.waves"
        case .occupational: symbolName = "suitcase"
        case .environment: symbolName = "leaf"
        case .financial: symbolName = "dollarsign"
        }
        return UIImage(systemName: symbolName) ?? UIImage()
    }

    var mainColor: UIColor {
        switch self {
        case .physical: return UIColor(red: 255.0/255.0, green: 56.0/255.0, blue: 60.0/255.0, alpha: 1)
        case .emotional: return UIColor(red: 255.0/255.0, green: 141.0/255.0, blue: 40.0/255.0, alpha: 1)
        case .social: return UIColor(red: 0.0/255.0, green: 136.0/255.0, blue: 255.0/255.0, alpha: 1)
        case .intellectual: return UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1)
        case .spiritual: return UIColor(red: 97.0/255.0, green: 85.0/255.0, blue: 245.0/255.0, alpha: 1)
        case .occupational: return UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 0.0/255.0, alpha: 1)
        case .environment: return UIColor(red: 0.0/255.0, green: 200.0/255.0, blue: 179.0/255.0, alpha: 1)
        case .financial: return UIColor(red: 203.0/255.0, green: 48.0/255.0, blue: 224.0/255.0, alpha: 1)
        }
    }
}
