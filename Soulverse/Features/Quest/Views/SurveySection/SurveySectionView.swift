//
//  SurveySectionView.swift
//  Soulverse
//
//  Container for the Quest tab Survey section. Hidden when distinctCheckInDays
//  < 7. Composes a section header, a PendingSurveyDeckView, and a
//  RecentResultCardListView.
//

import UIKit
import SnapKit

final class SurveySectionView: UIView {

    private enum Layout {
        static let outerInset: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let deckHeight: CGFloat = 132
    }

    private let titleLabel = UILabel()
    private let deckView = PendingSurveyDeckView()
    private let resultListView = RecentResultCardListView()
    private let emptyResultsLabel = UILabel()

    var onTapPendingCard: ((QuestSurveyType) -> Void)?
    var onTapRecentResult: ((RecentResultCardModel) -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .clear
        titleLabel.text = NSLocalizedString("quest_survey_section_title", comment: "")
        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.textColor = .themeTextPrimary

        emptyResultsLabel.text = NSLocalizedString("quest_survey_section_no_results", comment: "")
        emptyResultsLabel.font = .preferredFont(forTextStyle: .footnote)
        emptyResultsLabel.textColor = .themeTextSecondary
        emptyResultsLabel.textAlignment = .center
        emptyResultsLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, deckView, resultListView, emptyResultsLabel])
        stack.axis = .vertical
        stack.spacing = Layout.sectionSpacing
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        deckView.snp.makeConstraints { make in
            make.height.equalTo(Layout.deckHeight)
        }

        deckView.onTapFrontCard = { [weak self] type in self?.onTapPendingCard?(type) }
        resultListView.onSelect = { [weak self] r in self?.onTapRecentResult?(r) }
    }

    func configure(model: SurveySectionModel) {
        switch model {
        case .hidden:
            isHidden = true
        case let .composed(deck, results):
            isHidden = false
            if deck.isEmpty {
                deckView.isHidden = true
            } else {
                deckView.isHidden = false
                deckView.configure(deck: deck)
            }
            resultListView.configure(results: results)
            emptyResultsLabel.isHidden = !(deck.isEmpty && results.isEmpty)
        }
    }
}
