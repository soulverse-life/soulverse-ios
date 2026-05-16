//
//  PendingSurveyCardView.swift
//  Soulverse
//

import UIKit
import SnapKit

protocol PendingSurveyCardViewDelegate: AnyObject {
    func pendingSurveyCard(_ card: PendingSurveyCardView, didTapTakeSurveyFor surveyType: QuestSurveyType)
}

final class PendingSurveyCardView: UIView {

    private enum Layout {
        static let titleBottomMargin: CGFloat = 4
        static let descriptionBottomMargin: CGFloat = 20
    }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private let cardContent = UIView()

    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private lazy var ctaButton: SoulverseButton = SoulverseButton(
        title: NSLocalizedString("quest_pending_card_cta", comment: ""),
        style: .primary,
        delegate: self
    )

    weak var delegate: PendingSurveyCardViewDelegate?
    private var surveyType: QuestSurveyType?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        titleLabel.text = NSLocalizedString("quest_pending_card_title", comment: "")
        titleLabel.font = .projectFont(ofSize: QuestLayout.cardTitleFontSize, weight: .bold)
        titleLabel.textColor = .themeTextPrimary

        descriptionLabel.font = .projectFont(ofSize: QuestLayout.cardSubtitleFontSize, weight: .regular)
        descriptionLabel.textColor = .themeTextSecondary
        descriptionLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, ctaButton])
        stack.axis = .vertical
        stack.spacing = Layout.titleBottomMargin
        stack.setCustomSpacing(Layout.descriptionBottomMargin, after: descriptionLabel)

        cardContent.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.verticalEdges.equalToSuperview().inset(QuestLayout.cardVerticalInset)
            make.horizontalEdges.equalToSuperview().inset(QuestLayout.cardHorizontalInset)
        }
        ctaButton.snp.makeConstraints { make in
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        ViewComponentConstants.applyGlassCardEffect(
            to: self,
            visualEffectView: visualEffectView,
            contentView: cardContent,
            cornerRadius: QuestLayout.cardCornerRadius
        )
        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(model: PendingSurveyCardModel) {
        surveyType = model.surveyType
        descriptionLabel.text = NSLocalizedString(model.descriptionKey, comment: "")
    }
}

// MARK: - SoulverseButtonDelegate

extension PendingSurveyCardView: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let surveyType = surveyType else { return }
        delegate?.pendingSurveyCard(self, didTapTakeSurveyFor: surveyType)
    }
}
