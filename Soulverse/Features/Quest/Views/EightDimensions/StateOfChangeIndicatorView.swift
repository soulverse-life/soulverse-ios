//
//  StateOfChangeIndicatorView.swift
//  Soulverse
//
//  Five-dot horizontal indicator. Highlights the active stage and shows the
//  user-facing label below the row of dots.
//

import UIKit
import SnapKit

final class StateOfChangeIndicatorView: UIView {

    private enum Layout {
        static let dotSize: CGFloat = 10
        static let dotSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 8
        static let activeLabelFontSize: CGFloat = 13
    }

    private let dotStack = UIStackView()
    private let activeLabel = UILabel()
    private var dots: [UIView] = []

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .clear

        dotStack.axis = .horizontal
        dotStack.alignment = .center
        dotStack.spacing = Layout.dotSpacing
        for _ in 0..<5 {
            let dot = UIView()
            dot.snp.makeConstraints { make in
                make.width.height.equalTo(Layout.dotSize)
            }
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.backgroundColor = .themeButtonDisabledBackground
            dotStack.addArrangedSubview(dot)
            dots.append(dot)
        }

        activeLabel.font = .projectFont(ofSize: Layout.activeLabelFontSize, weight: .regular)
        activeLabel.textColor = .themeTextPrimary
        activeLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [dotStack, activeLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.labelSpacing
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(model: StateOfChangeIndicatorModel?) {
        guard let model = model else {
            isHidden = true
            return
        }
        isHidden = false
        for (i, dot) in dots.enumerated() {
            let stage = i + 1
            dot.backgroundColor = (stage == model.activeStage)
                ? .themeButtonPrimaryBackground
                : .themeButtonDisabledBackground
        }
        let labelKey = model.stageLabelKeys[max(0, min(model.activeStage - 1, 4))]
        activeLabel.text = NSLocalizedString(labelKey, comment: "")
    }
}
