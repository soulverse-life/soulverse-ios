//
//  LifeAreaOption.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation

enum LifeAreaOption: String, CaseIterable {
    case physical = "Physical"
    case emotional = "Emotional"
    case social = "Social"
    case intellectual = "Intellectual"
    case spiritual = "Spiritual"
    case occupational = "Occupational"
    case environment = "Environment"
    case financial = "Financial"

    /// Display name for the life area button
    var displayName: String {
        return rawValue
    }
}
