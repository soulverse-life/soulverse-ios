//
//  EightDimensionsRenderModelBuilder.swift
//  Soulverse
//
//  Pure-function builder. Takes a `QuestStateModel` and emits a render model
//  that the radar overlay + SoC indicator can render directly.
//

import Foundation

enum EightDimensionsRenderModelBuilder {

    static let unlockDay = 7

    /// Canonical axis order — must match Topic.allCases.
    static let canonicalOrder = Topic.allCases

    static func build(state: QuestStateModel) -> EightDimensionsRenderModel {
        // Card-locked path: stage 1 lock icon affordance.
        if state.distinctCheckInDays < unlockDay {
            return EightDimensionsRenderModel(
                axes: Array(repeating: .stage1Locked, count: 8),
                stateOfChangeIndicator: nil,
                isCardLocked: true
            )
        }

        let focus = state.focusDimension
        let lastEightDim = state.lastEightDimDimension
        let socStage = state.lastStateOfChangeStage

        // Per-axis state derivation.
        var axes: [DimensionAxisState] = []
        for dim in canonicalOrder {
            if dim == focus {
                if let stage = socStage {
                    axes.append(.currentFocusWithSoC(stage: stage))
                } else {
                    axes.append(.currentFocusNoSoC)
                }
            } else if dim == lastEightDim {
                // FIXME(v1.1): uses current focus dim's SoC stage; needs
                // per-dimension stage tracking once multi-cycle ships.
                axes.append(.previouslyFocused(stage: socStage ?? 1))
            } else {
                axes.append(.neverAssessed)
            }
        }

        // SoC indicator — visible only after at least one SoC submission.
        let socIndicator: StateOfChangeIndicatorModel? = {
            guard let stage = socStage else { return nil }
            return StateOfChangeIndicatorModel(
                activeStage: stage,
                stageLabelKeys: StateOfChangeIndicatorModel.defaultLabelKeys,
                stageMessageKey: "quest_stage_soc_\(stage)_message"
            )
        }()

        return EightDimensionsRenderModel(
            axes: axes,
            stateOfChangeIndicator: socIndicator,
            isCardLocked: false
        )
    }
}
