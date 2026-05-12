//
//  QuestProgressSectionView.swift
//  Soulverse
//
//  The Quest tab's day-progress section: a centered 7-dot rail representing
//  the current stage's days (not all 21 — stage advances replace the row).
//
//  The page-level tagline + EmoPet dialog have been hoisted into
//  QuestHeaderView; this view is intentionally narrow in scope.
//

import UIKit
import SnapKit

final class QuestProgressSectionView: UIView {

    private enum Layout {
        static let containerInset: CGFloat = ViewComponentConstants.horizontalPadding
    }

    private let dotsView = QuestProgressDotsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        addSubview(dotsView)
        dotsView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(Layout.containerInset)
            make.right.lessThanOrEqualToSuperview().offset(-Layout.containerInset)
        }
    }

    func configure(viewModel: QuestViewModel) {
        isHidden = !viewModel.progressSectionVisible
        dotsView.configure(currentDot: viewModel.currentDot, stage: viewModel.stage)
    }
}
