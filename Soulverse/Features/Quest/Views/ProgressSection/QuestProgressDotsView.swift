//
//  QuestProgressDotsView.swift
//  Soulverse
//
//  Renders a 7-dot row representing the current stage's days. Completed
//  days are filled; the current day is highlighted with a slightly larger
//  active dot; remaining days are dim.
//
//  Per the design (~/Desktop/quest_1.png), we never render all 21 planets
//  at once — the stage being viewed always occupies the full row.
//

import UIKit
import SnapKit

final class QuestProgressDotsView: UIView {

    private enum Layout {
        static let dotsPerStage: Int = 7
        static let dotSize: CGFloat = 24
        static let activeDotSize: CGFloat = 30
        static let dotSpacing: CGFloat = 14
    }

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.spacing = Layout.dotSpacing
        return s
    }()

    private var dotViews: [UIImageView] = []
    private(set) var dotCount: Int = Layout.dotsPerStage

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

        for _ in 0..<Layout.dotsPerStage {
            let dot = UIImageView()
            dot.contentMode = .scaleAspectFit
            dot.image = UIImage(named: "EMOPet/basic_first_level")
            dot.snp.makeConstraints { make in
                make.size.equalTo(Layout.dotSize)
            }
            stack.addArrangedSubview(dot)
            dotViews.append(dot)
        }
    }

    /// Map the (1-indexed) absolute current dot to the (1..7) dot position
    /// within the active stage, then style each dot.
    func configure(currentDot: Int, stage: QuestStage) {
        let stageRange = stage.dotRange
        // Map absolute dot → position within stage (1...7)
        let relativeCurrent: Int = {
            guard stageRange.contains(currentDot) else {
                // Before the stage started → 0; after → 7 (all complete)
                return currentDot < stageRange.lowerBound ? 0 : Layout.dotsPerStage
            }
            return currentDot - stageRange.lowerBound + 1
        }()

        for (idx, dot) in dotViews.enumerated() {
            let position = idx + 1
            let isCurrent = position == relativeCurrent
            let isCompleted = position < relativeCurrent

            dot.snp.updateConstraints { make in
                make.size.equalTo(isCurrent ? Layout.activeDotSize : Layout.dotSize)
            }

            if isCurrent {
                dot.alpha = 1.0
            } else if isCompleted {
                dot.alpha = 0.85
            } else {
                dot.alpha = 0.4
            }
        }
    }
}
