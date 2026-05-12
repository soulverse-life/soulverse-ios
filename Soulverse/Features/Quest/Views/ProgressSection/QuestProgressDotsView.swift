//
//  QuestProgressDotsView.swift
//  Soulverse
//
//  Renders a 7-dot row representing the current stage's days. Each dot is an
//  EmotionPlanetView (the same component InnerCosmo uses) at 20pt diameter,
//  with no emotion label. Two-color states:
//    - completed → near-white planet
//    - not yet completed → InnerCosmo's placeholder gray (#B0B0B0)
//
//  Per the design (~/Desktop/quest_1.png), we never render all 21 planets
//  at once — the stage being viewed always occupies the full row.
//

import UIKit
import SnapKit

final class QuestProgressDotsView: UIView {

    private enum Layout {
        static let dotsPerStage: Int = 7
        static let planetPointSize: CGFloat = 20
        /// `EmotionPlanetView` sizes itself via `data.sizeMultiplier * 36`
        /// (its internal baseSize). Reverse-engineer the multiplier so the
        /// rendered planet is exactly `planetPointSize` pt in diameter.
        static let planetSizeMultiplier: CGFloat = planetPointSize / 36.0
        static let dotSpacing: CGFloat = 8
    }

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.spacing = Layout.dotSpacing
        return s
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    /// Rebuild the 7-dot row coloured by completion state. Called whenever
    /// the view model's `currentDot` / `stage` changes.
    func configure(currentDot: Int, stage: QuestStage) {
        let stageRange = stage.dotRange
        let relativeCurrent: Int = {
            guard stageRange.contains(currentDot) else {
                return currentDot < stageRange.lowerBound ? 0 : Layout.dotsPerStage
            }
            return currentDot - stageRange.lowerBound + 1
        }()

        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for i in 0..<Layout.dotsPerStage {
            let position = i + 1
            let isCompleted = position <= relativeCurrent
            let color: UIColor = isCompleted ? .themePlanetCompleted : .themePlanetPlaceholder

            let data = EmotionPlanetData(
                emotion: "",
                color: color,
                sizeMultiplier: Layout.planetSizeMultiplier
            )
            let planet = EmotionPlanetView(data: data)
            let size = planet.calculateSize()
            planet.snp.makeConstraints { make in
                make.width.equalTo(size.width)
                make.height.equalTo(size.height)
            }
            stack.addArrangedSubview(planet)
        }
    }
}
