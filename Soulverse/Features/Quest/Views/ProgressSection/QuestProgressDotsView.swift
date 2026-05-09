//
//  QuestProgressDotsView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class QuestProgressDotsView: UIView {

    private enum Layout {
        static let totalDots: Int = QuestViewModel.questCompleteDay
        static let dotSize: CGFloat = 6
        static let activeDotSize: CGFloat = 10
        static let dotSpacing: CGFloat = 4
        static let stageGap: CGFloat = 8
    }

    private let stack: UIStackView = {
        let s = UIStackView()
        s.axis = .horizontal
        s.alignment = .center
        s.distribution = .equalSpacing
        s.spacing = Layout.dotSpacing
        return s
    }()

    private var dotViews: [UIView] = []

    private(set) var dotCount: Int = 0
    private(set) var highlightedDotIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        for i in 1...Layout.totalDots {
            let dot = UIView()
            dot.backgroundColor = .themeProgressBarInactive
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.snp.makeConstraints { make in
                make.size.equalTo(Layout.dotSize)
            }
            stack.addArrangedSubview(dot)
            dotViews.append(dot)

            // Insert a wider gap after each stage boundary (dots 7 and 14).
            if i == 7 || i == 14 {
                let gap = UIView()
                gap.snp.makeConstraints { make in
                    make.width.equalTo(Layout.stageGap)
                }
                stack.addArrangedSubview(gap)
            }
        }
        dotCount = dotViews.count
    }

    func configure(currentDot: Int, stage: QuestStage) {
        highlightedDotIndex = max(0, min(currentDot, Layout.totalDots))
        let stageRange = stage.dotRange

        for (idx, dot) in dotViews.enumerated() {
            let dotNumber = idx + 1
            let inCurrentStage = stageRange.contains(dotNumber)
            let completed = dotNumber <= currentDot

            dot.snp.updateConstraints { make in
                make.size.equalTo(dotNumber == currentDot ? Layout.activeDotSize : Layout.dotSize)
            }
            dot.layer.cornerRadius = (dotNumber == currentDot ? Layout.activeDotSize : Layout.dotSize) / 2

            if dotNumber == currentDot {
                dot.backgroundColor = .themeProgressBarActive
                dot.layer.borderWidth = 2
                dot.layer.borderColor = UIColor.themeProgressBarActive.withAlphaComponent(0.4).cgColor
            } else if completed {
                dot.backgroundColor = .themeProgressBarActive.withAlphaComponent(0.6)
                dot.layer.borderWidth = 0
            } else if inCurrentStage {
                dot.backgroundColor = .themeProgressBarInactive
                dot.layer.borderWidth = 0
            } else {
                dot.backgroundColor = .themeProgressBarInactive.withAlphaComponent(0.5)
                dot.layer.borderWidth = 0
            }
        }
    }
}
