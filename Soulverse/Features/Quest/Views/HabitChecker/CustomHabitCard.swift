//
//  CustomHabitCard.swift
//  Soulverse
//
//  Visual card for the user's active custom habit. Mirrors DefaultHabitCard
//  (icon + accent-colored total + tinted increment buttons + tinted card bg)
//  with an added trash-icon delete affordance. Accent + icon are pulled from
//  the habit's deterministic palette slot (see CustomHabit.accentColor).
//

import UIKit
import SnapKit

protocol CustomHabitCardDelegate: AnyObject {
    /// Returns `true` if the increment was applied, `false` if rejected.
    func customHabitCard(_ card: CustomHabitCard, didTapIncrement amount: Int) -> Bool
    func customHabitCardDidTapDelete(_ card: CustomHabitCard)
}

final class CustomHabitCard: UIView {
    private enum Layout {
        static let cardCornerRadius: CGFloat = 16
        static let outerInset: CGFloat = 14
        static let stackSpacing: CGFloat = 20
        static let titleRowSpacing: CGFloat = 8
        static let iconSize: CGFloat = 20
        static let buttonStackSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 36
        static let buttonCornerRadius: CGFloat = 14
        static let titleFontSize: CGFloat = 15
        static let totalFontSize: CGFloat = 15
        static let incrementButtonFontSize: CGFloat = 15
        static let cardBackgroundAlpha: CGFloat = 0.05
        static let buttonBackgroundAlpha: CGFloat = 0.18
    }

    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let buttonStack = UIStackView()
    private let deleteButton = UIButton(type: .system)

    private var accentColor: UIColor = .themeTextPrimary
    /// See note on `DefaultHabitCard.currentIncrements`.
    private var currentIncrements: [Int] = []

    weak var delegate: CustomHabitCardDelegate?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ habit: CustomHabit, todayTotal: Int, yesterdayTotal: Int) {
        accentColor = habit.accentColor

        iconImageView.image = UIImage(systemName: habit.iconName)
        titleLabel.text = habit.name
        totalLabel.text = String(
            format: NSLocalizedString("quest_habit_today_format", comment: ""),
            todayTotal,
            habit.unit
        )
        totalLabel.textColor = accentColor

        if currentIncrements != habit.increments {
            buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for amount in habit.increments {
                buttonStack.addArrangedSubview(makeIncrementButton(amount: amount))
            }
            currentIncrements = habit.increments
        } else {
            for case let button as UIButton in buttonStack.arrangedSubviews {
                button.setTitleColor(accentColor, for: .normal)
                button.backgroundColor = accentColor.withAlphaComponent(Layout.buttonBackgroundAlpha)
            }
        }
    }

    private func setupView() {
        layer.cornerRadius = Layout.cardCornerRadius
        clipsToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(Layout.cardBackgroundAlpha)

        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .themeTextPrimary
        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        titleLabel.textColor = .themeTextPrimary

        totalLabel.font = .projectFont(ofSize: Layout.totalFontSize, weight: .semibold)
        totalLabel.textAlignment = .right
        totalLabel.setContentHuggingPriority(.required, for: .horizontal)

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .themeTextSecondary
        deleteButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.customHabitCardDidTapDelete(self)
        }, for: .touchUpInside)

        let titleRow = UIStackView(arrangedSubviews: [iconImageView, titleLabel, totalLabel, deleteButton])
        titleRow.axis = .horizontal
        titleRow.alignment = .center
        titleRow.spacing = Layout.titleRowSpacing

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = Layout.buttonStackSpacing

        let vStack = UIStackView(arrangedSubviews: [titleRow, buttonStack])
        vStack.axis = .vertical
        vStack.spacing = Layout.stackSpacing

        addSubview(vStack)
        vStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        buttonStack.snp.makeConstraints { make in
            make.height.equalTo(Layout.buttonHeight)
        }
    }

    private func makeIncrementButton(amount: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(
            String(format: NSLocalizedString("quest_habit_increment_button_format", comment: ""), amount),
            for: .normal
        )
        button.titleLabel?.font = .projectFont(ofSize: Layout.incrementButtonFontSize, weight: .semibold)
        button.setTitleColor(accentColor, for: .normal)
        button.backgroundColor = accentColor.withAlphaComponent(Layout.buttonBackgroundAlpha)
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addAction(UIAction { [weak self, weak button] _ in
            guard let self = self else { return }
            let applied = self.delegate?.customHabitCard(self, didTapIncrement: amount) ?? false
            guard let button = button else { return }
            if applied {
                HabitIncrementFeedback.playSuccess(on: button)
            } else {
                HabitIncrementFeedback.playRejected(on: button)
            }
        }, for: .touchUpInside)
        return button
    }
}
