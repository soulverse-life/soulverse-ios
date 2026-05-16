//
//  SurveySectionView.swift
//  Soulverse
//
//  Container for the Quest tab Survey section. Hidden when
//  distinctCheckInDays < 7. Renders a plain vertical stack of:
//    - one PendingSurveyCardView per pending survey (each a self-contained
//      glass card with title + description + CTA)
//    - one RecentResultCardView per recent submission, via
//      RecentResultCardListView (already an independent-blocks layout)
//

import UIKit
import SnapKit

final class SurveySectionView: UIView {

    private enum Layout {
        static let outerInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
    }

    private let pendingStack = UIStackView()
    private let resultListView = RecentResultCardListView()

    private var pendingCardModelByCard: [PendingSurveyCardView: PendingSurveyCardModel] = [:]

    var onTapPendingCard: ((QuestSurveyType) -> Void)?
    var onTapRecentResult: ((RecentResultCardModel) -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .clear

        pendingStack.axis = .vertical
        pendingStack.spacing = Layout.sectionSpacing

        let outer = UIStackView(arrangedSubviews: [pendingStack, resultListView])
        outer.axis = .vertical
        outer.spacing = Layout.sectionSpacing
        addSubview(outer)
        outer.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }

        resultListView.onSelect = { [weak self] r in self?.onTapRecentResult?(r) }
    }

    func configure(model: SurveySectionModel) {
        switch model {
        case .hidden:
            isHidden = true
        case let .composed(pending, results):
            isHidden = false
            rebuildPending(pending)
            resultListView.configure(results: results)
        }
    }

    private func rebuildPending(_ pending: [PendingSurveyCardModel]) {
        pendingStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pendingCardModelByCard.removeAll()
        for model in pending {
            let card = PendingSurveyCardView()
            card.configure(model: model)
            pendingCardModelByCard[card] = model
            card.onTap = { [weak self, weak card] in
                guard let self = self, let card = card,
                      let m = self.pendingCardModelByCard[card] else { return }
                self.onTapPendingCard?(m.surveyType)
            }
            pendingStack.addArrangedSubview(card)
        }
        pendingStack.isHidden = pending.isEmpty
    }
}
