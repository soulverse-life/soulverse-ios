//
//  CustomHabitCard.swift
//  Soulverse
//
//  Visual card for the user's active custom habit. Mirrors DefaultHabitCard
//  with an added trash-icon delete affordance.
//

import UIKit
import SnapKit

final class CustomHabitCard: UIView {
    private enum Layout {
        static let outerInset: CGFloat = 12
        static let stackSpacing: CGFloat = 6
        static let buttonStackSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 36
        static let buttonCornerRadius: CGFloat = 18
        static let titleFontSize: CGFloat = 17
        static let totalFontSize: CGFloat = 20
        static let yesterdayFontSize: CGFloat = 13
        static let resetSubtitleFontSize: CGFloat = 11
        static let incrementButtonFontSize: CGFloat = 15
    }

    private let titleLabel = UILabel()
    private let totalLabel = UILabel()
    private let yesterdayLabel = UILabel()
    private let resetSubtitleLabel = UILabel()
    private let buttonStack = UIStackView()
    private let deleteButton = UIButton(type: .system)

    var onIncrementTap: ((_ amount: Int) -> Void)?
    var onDeleteTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ habit: CustomHabit, todayTotal: Int, yesterdayTotal: Int) {
        titleLabel.text = habit.name
        totalLabel.text = String(format: NSLocalizedString("quest_habit_today_format", comment: ""), todayTotal, habit.unit)
        if yesterdayTotal > 0 {
            yesterdayLabel.isHidden = false
            yesterdayLabel.text = String(format: NSLocalizedString("quest_habit_yesterday_format", comment: ""), yesterdayTotal, habit.unit)
        } else {
            yesterdayLabel.isHidden = true
        }
        resetSubtitleLabel.text = NSLocalizedString("quest_habit_resets_at_midnight", comment: "")

        buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for amount in habit.increments {
            let button = makeIncrementButton(amount: amount)
            buttonStack.addArrangedSubview(button)
        }
    }

    private func setupView() {
        backgroundColor = .clear

        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        titleLabel.textColor = .themeTextPrimary

        totalLabel.font = .projectFont(ofSize: Layout.totalFontSize, weight: .regular)
        totalLabel.textColor = .themeTextPrimary

        yesterdayLabel.font = .projectFont(ofSize: Layout.yesterdayFontSize, weight: .regular)
        yesterdayLabel.textColor = .themeTextSecondary

        resetSubtitleLabel.font = .projectFont(ofSize: Layout.resetSubtitleFontSize, weight: .regular)
        resetSubtitleLabel.textColor = .themeTextSecondary

        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = Layout.buttonStackSpacing

        deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
        deleteButton.tintColor = .themeTextSecondary
        deleteButton.addAction(UIAction { [weak self] _ in self?.onDeleteTap?() }, for: .touchUpInside)

        let topRow = UIStackView(arrangedSubviews: [titleLabel, deleteButton])
        topRow.axis = .horizontal
        topRow.distribution = .equalSpacing
        topRow.alignment = .center

        let vStack = UIStackView(arrangedSubviews: [topRow, totalLabel, yesterdayLabel, resetSubtitleLabel, buttonStack])
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
        button.titleLabel?.font = .projectFont(ofSize: Layout.incrementButtonFontSize, weight: .regular)
        button.setTitleColor(.themeButtonSecondaryText, for: .normal)
        button.backgroundColor = .themeButtonSecondaryBackground
        button.layer.cornerRadius = Layout.buttonCornerRadius
        button.addAction(UIAction { [weak self] _ in
            self?.onIncrementTap?(amount)
        }, for: .touchUpInside)
        return button
    }
}
