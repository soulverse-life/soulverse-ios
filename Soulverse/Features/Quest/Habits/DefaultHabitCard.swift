//
//  DefaultHabitCard.swift
//  Soulverse
//
//  Visual card for one of the three fixed default habits.
//

import UIKit
import SnapKit

final class DefaultHabitCard: UIView {

    private enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let outerInset: CGFloat = 16
        static let stackSpacing: CGFloat = 8
        static let buttonStackSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 36
        static let buttonCornerRadius: CGFloat = 18
    }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private let cardContent = UIView()

    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let yesterdayLabel = UILabel()
    private let resetSubtitleLabel = UILabel()
    private let buttonStack = UIStackView()

    var onIncrementTap: ((_ amount: Int) -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ model: HabitCardModel) {
        titleLabel.text = NSLocalizedString(model.titleKey, comment: "")
        totalLabel.text = String(format: NSLocalizedString("quest_habit_today_format", comment: ""), model.todayTotal, model.unit)
        if model.shouldShowYesterday {
            yesterdayLabel.isHidden = false
            yesterdayLabel.text = String(format: NSLocalizedString("quest_habit_yesterday_format", comment: ""), model.yesterdayTotal, model.unit)
        } else {
            yesterdayLabel.isHidden = true
        }
        resetSubtitleLabel.text = NSLocalizedString("quest_habit_resets_at_midnight", comment: "")

        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for amount in model.increments {
            let button = makeIncrementButton(amount: amount)
            buttonStack.addArrangedSubview(button)
        }
    }

    private func setupView() {
        layer.cornerRadius = Layout.cardCornerRadius
        clipsToBounds = true

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .themeTextPrimary

        totalLabel.font = .preferredFont(forTextStyle: .title3)
        totalLabel.textColor = .themeTextPrimary

        yesterdayLabel.font = .preferredFont(forTextStyle: .footnote)
        yesterdayLabel.textColor = .themeTextSecondary

        resetSubtitleLabel.font = .preferredFont(forTextStyle: .caption2)
        resetSubtitleLabel.textColor = .themeTextSecondary

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = Layout.buttonStackSpacing

        let vStack = UIStackView(arrangedSubviews: [titleLabel, totalLabel, yesterdayLabel, resetSubtitleLabel, buttonStack])
        vStack.axis = .vertical
        vStack.spacing = Layout.stackSpacing

        cardContent.addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        buttonStack.snp.makeConstraints { make in
            make.height.equalTo(Layout.buttonHeight)
        }

        ViewComponentConstants.applyGlassCardEffect(
            to: self,
            visualEffectView: visualEffectView,
            contentView: cardContent,
            cornerRadius: Layout.cardCornerRadius
        )
        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeIncrementButton(amount: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("+\(amount)", for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        button.setTitleColor(.themeButtonSecondaryText, for: .normal)
        button.backgroundColor = .themeButtonSecondaryBackground
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addAction(UIAction { [weak self] _ in
            self?.onIncrementTap?(amount)
        }, for: .touchUpInside)
        return button
    }
}
