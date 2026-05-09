//
//  QuestStage.swift
//  Soulverse
//
//  Pure stage derivation from distinctCheckInDays. No UIKit; safe to use
//  inside framework-agnostic ViewModel code.
//

import Foundation

enum QuestStage: Equatable {
    case stage1     // distinctCheckInDays 0..6
    case stage2     // distinctCheckInDays 7..13
    case stage3     // distinctCheckInDays 14..20
    case completed  // distinctCheckInDays >= 21

    static func from(distinctCheckInDays days: Int) -> QuestStage {
        switch days {
        case ..<7:    return .stage1
        case 7...13:  return .stage2
        case 14...20: return .stage3
        default:      return .completed
        }
    }

    /// Inclusive 1-indexed dot range belonging to this stage on the 21-dot rail.
    var dotRange: ClosedRange<Int> {
        switch self {
        case .stage1:    return 1...7
        case .stage2:    return 8...14
        case .stage3:    return 15...21
        case .completed: return 1...21
        }
    }
}
