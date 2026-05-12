//
//  DimensionAxisState.swift
//  Soulverse
//
//  Per-axis render state for the 8-Dimensions radar overlay.
//  Mapped from `QuestStateModel` by `EightDimensionsRenderModelBuilder`.
//

import Foundation

enum DimensionAxisState: Equatable {
    /// distinctCheckInDays < 7. All 8 axes start here, EmoPet at center.
    case stage1Locked
    /// User's current focus dim, no SoC yet — 5 outline dots, no solid dot.
    case currentFocusNoSoC
    /// User's current focus dim, SoC submitted at the given stage (1–5).
    case currentFocusWithSoC(stage: Int)
    /// Previously focused (post-v1.1). Single solid dot at last reached stage.
    case previouslyFocused(stage: Int)
    /// Never assessed — lock icon at outermost position.
    case neverAssessed
}

/// Friendly-label SoC indicator (5 dots) below the radar.
struct StateOfChangeIndicatorModel: Equatable {
    let activeStage: Int    // 1–5
    let stageLabelKeys: [String]
    let stageMessageKey: String

    static let defaultLabelKeys: [String] = (1...5).map { "quest_stage_soc_\($0)_label" }
}

/// One render entry per dimension, in canonical order.
struct EightDimensionsRenderModel: Equatable {
    /// Always 8 entries in `Topic.allCases` order.
    let axes: [DimensionAxisState]
    let stateOfChangeIndicator: StateOfChangeIndicatorModel?
    let isCardLocked: Bool
}
