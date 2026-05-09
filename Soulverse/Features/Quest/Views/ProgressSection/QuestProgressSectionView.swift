//
//  QuestProgressSectionView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class QuestProgressSectionView: UIView {

    private enum Layout {
        static let containerInset: CGFloat = ViewComponentConstants.horizontalPadding
        static let pillHorizontalPadding: CGFloat = 12
        static let pillVerticalPadding: CGFloat = 4
        static let pillToDotsSpacing: CGFloat = 14
        static let dotsToCTASpacing: CGFloat = 16
        static let pillFontSize: CGFloat = 13
        static let ctaFontSize: CGFloat = 15
        static let ctaHeight: CGFloat = ViewComponentConstants.actionButtonHeight
    }

    var onCTAtap: (() -> Void)?

    var pillText: String { return pillLabel.text ?? "" }
    var isCTAHidden: Bool { return ctaButton.isHidden }

    private let pillLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.pillFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        l.backgroundColor = .themeProgressBarInactive
        l.layer.cornerRadius = 12
        l.layer.masksToBounds = true
        l.textAlignment = .center
        return l
    }()

    private let dotsView = QuestProgressDotsView()

    private lazy var ctaButton: UIButton = {
        let b = UIButton(type: .system)
        b.titleLabel?.font = UIFont.projectFont(ofSize: Layout.ctaFontSize, weight: .semibold)
        b.setTitleColor(.themeButtonPrimaryText, for: .normal)
        b.backgroundColor = .themeButtonPrimaryBackground
        b.layer.cornerRadius = Layout.ctaHeight / 2
        b.addTarget(self, action: #selector(handleCTATap), for: .touchUpInside)
        return b
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        let stack = UIStackView(arrangedSubviews: [pillLabel, dotsView, ctaButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Layout.pillToDotsSpacing
        stack.setCustomSpacing(Layout.dotsToCTASpacing, after: dotsView)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.containerInset)
        }

        pillLabel.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(24)
            make.width.greaterThanOrEqualTo(96)
        }

        ctaButton.snp.makeConstraints { make in
            make.height.equalTo(Layout.ctaHeight)
            make.left.right.equalTo(stack)
        }
    }

    func configure(viewModel: QuestViewModel) {
        isHidden = !viewModel.progressSectionVisible

        pillLabel.text = "  \(viewModel.dayPillText)  "
        dotsView.configure(currentDot: viewModel.currentDot, stage: viewModel.stage)

        ctaButton.setTitle(
            NSLocalizedString("quest_progress_daily_cta", comment: "Day-1 CTA"),
            for: .normal
        )
        ctaButton.isHidden = !viewModel.dailyCheckInCTAVisible
    }

    @objc private func handleCTATap() {
        onCTAtap?()
    }

    func simulateCTATap() {
        handleCTATap()
    }
}
