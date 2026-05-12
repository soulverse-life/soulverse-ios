//
//  PendingSurveyDeckView.swift
//  Soulverse
//
//  Stacked deck-of-cards visual. Renders the front card as a tappable
//  PendingSurveyCardView and the next 0–2 cards as slim slices behind,
//  offset vertically to suggest depth. Optional "+N more" badge for >3.
//

import UIKit
import SnapKit

final class PendingSurveyDeckView: UIView {

    private enum Layout {
        static let cardHeight: CGFloat = 96
        static let stackOffset: CGFloat = 6
        static let backCardInset: CGFloat = 16
        static let moreBadgeFontSize: CGFloat = 11
    }

    private let backCardA = UIView()
    private let backCardB = UIView()
    private let frontCard = PendingSurveyCardView()
    private let moreBadge = UILabel()

    var onTapFrontCard: ((QuestSurveyType) -> Void)?
    private var currentFrontType: QuestSurveyType?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .clear

        for back in [backCardA, backCardB] {
            back.backgroundColor = .themeCardBackground
            back.layer.cornerRadius = 16
            back.layer.masksToBounds = true
            back.alpha = 0.5
            addSubview(back)
        }

        addSubview(frontCard)
        frontCard.onTap = { [weak self] in
            guard let self = self, let type = self.currentFrontType else { return }
            self.onTapFrontCard?(type)
        }

        moreBadge.font = .projectFont(ofSize: Layout.moreBadgeFontSize, weight: .regular)
        moreBadge.textColor = .themeTextSecondary
        moreBadge.textAlignment = .center
        addSubview(moreBadge)

        // Two faux back cards, offset by stackOffset each.
        backCardB.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.backCardInset * 2)
            make.height.equalTo(Layout.cardHeight)
            make.bottom.equalTo(frontCard.snp.top).offset(Layout.stackOffset * 2)
        }
        backCardA.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.backCardInset)
            make.height.equalTo(Layout.cardHeight)
            make.bottom.equalTo(frontCard.snp.top).offset(Layout.stackOffset)
        }
        frontCard.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(Layout.cardHeight)
        }
        moreBadge.snp.makeConstraints { make in
            make.right.equalTo(frontCard.snp.right).inset(8)
            make.top.equalToSuperview().inset(2)
        }
    }

    func configure(deck: PendingSurveyDeckModel) {
        guard let front = deck.frontCard else {
            isHidden = true
            return
        }
        isHidden = false
        currentFrontType = front.surveyType
        frontCard.configure(
            title: NSLocalizedString(front.titleKey, comment: ""),
            body: NSLocalizedString(front.bodyKey, comment: ""),
            isInteractive: true
        )

        backCardA.isHidden = deck.stackedBehindCount < 1
        backCardB.isHidden = deck.stackedBehindCount < 2

        if deck.moreBadgeCount > 0 {
            moreBadge.isHidden = false
            moreBadge.text = String(
                format: NSLocalizedString("quest_pending_deck_more_badge", comment: ""),
                deck.moreBadgeCount
            )
        } else {
            moreBadge.isHidden = true
        }
    }
}
