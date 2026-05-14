//
//  HabitIncrementFeedback.swift
//  Soulverse
//
//  Visual + haptic feedback played on a habit increment button. Two variants:
//    - `playSuccess(on:)` — quick scale-pulse + light haptic, used when the
//      service accepted the increment.
//    - `playRejected(on:)` — horizontal shake + warning haptic, used when the
//      service rejected the increment (e.g., minute-cap was already reached).
//

import UIKit

enum HabitIncrementFeedback {

    private enum Constants {
        static let pulseScale: CGFloat = 0.92
        static let pulseDownDuration: TimeInterval = 0.08
        static let pulseUpDuration: TimeInterval = 0.12
        static let shakeOffset: CGFloat = 6
        static let shakeDuration: TimeInterval = 0.06
    }

    /// Quick scale-pulse + light haptic for an accepted increment.
    static func playSuccess(on view: UIView) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        let original = view.transform
        UIView.animate(
            withDuration: Constants.pulseDownDuration,
            delay: 0,
            options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState],
            animations: {
                view.transform = original.scaledBy(x: Constants.pulseScale, y: Constants.pulseScale)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: Constants.pulseUpDuration,
                    delay: 0,
                    options: [.curveEaseOut, .allowUserInteraction, .beginFromCurrentState],
                    animations: { view.transform = original }
                )
            }
        )
    }

    /// Horizontal shake for a rejected increment.
    static func playRejected(on view: UIView) {
        let original = view.transform
        let dt = Constants.shakeDuration
        let dx = Constants.shakeOffset

        UIView.animateKeyframes(
            withDuration: dt * 4,
            delay: 0,
            options: [.allowUserInteraction, .beginFromCurrentState],
            animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.00, relativeDuration: 0.25) {
                    view.transform = original.translatedBy(x: -dx, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.25, relativeDuration: 0.25) {
                    view.transform = original.translatedBy(x: dx, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.50, relativeDuration: 0.25) {
                    view.transform = original.translatedBy(x: -dx, y: 0)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                    view.transform = original
                }
            }
        )
    }
}
