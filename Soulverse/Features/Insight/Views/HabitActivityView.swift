//
//  HabitActivityView.swift
//

import UIKit
import SnapKit

class HabitActivityView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let habitNameFontSize: CGFloat = 14
        static let detailFontSize: CGFloat = 13
        static let iconSize: CGFloat = 24
        static let rowSpacing: CGFloat = 14
        static let titleBottomSpacing: CGFloat = 16
        static let iconNameSpacing: CGFloat = 10
        static let streakTotalSpacing: CGFloat = 12
        static let flameIconSize: CGFloat = 13
        static let borderWidth: CGFloat = 1
        static let fallbackBackgroundAlpha: CGFloat = 0.1
    }

    // MARK: - Subviews

    private let baseView: UIView = {
        let view = UIView()
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var rowsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.rowSpacing
        return stackView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        baseView.addSubview(titleLabel)
        baseView.addSubview(rowsStackView)

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cardCornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            addSubview(baseView)
            baseView.layer.cornerRadius = Layout.cardCornerRadius
            baseView.layer.borderWidth = Layout.borderWidth
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .themeCardBackground
            baseView.clipsToBounds = true
        }

        setupConstraints()
    }

    private func setupConstraints() {
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        rowsStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: HabitActivityViewModel) {
        titleLabel.text = viewModel.title

        if viewModel.habits.isEmpty {
            isHidden = true
            return
        }

        isHidden = false

        // Remove existing rows
        rowsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for habit in viewModel.habits {
            let rowView = createHabitRow(for: habit)
            rowsStackView.addArrangedSubview(rowView)
        }
    }

    // MARK: - Row Creation

    private func createHabitRow(for habit: HabitActivityViewModel.HabitItem) -> UIView {
        let rowView = UIView()

        // Left side: icon + name
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.image = UIImage(systemName: habit.iconName)
        iconImageView.tintColor = habit.isBuiltIn ? .themePrimary : .themeTextSecondary

        let nameLabel = UILabel()
        nameLabel.font = UIFont.projectFont(ofSize: Layout.habitNameFontSize, weight: .medium)
        nameLabel.textColor = .themeTextPrimary
        nameLabel.text = habit.name

        let leftStack = UIStackView(arrangedSubviews: [iconImageView, nameLabel])
        leftStack.axis = .horizontal
        leftStack.spacing = Layout.iconNameSpacing
        leftStack.alignment = .center

        iconImageView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.iconSize)
        }

        // Right side: streak + total
        let flameImageView = UIImageView()
        flameImageView.contentMode = .scaleAspectFit
        flameImageView.image = UIImage(systemName: "flame.fill")
        flameImageView.tintColor = .themeTextSecondary

        flameImageView.snp.makeConstraints { make in
            make.width.height.equalTo(Layout.flameIconSize)
        }

        let streakLabel = UILabel()
        streakLabel.font = UIFont.projectFont(ofSize: Layout.detailFontSize, weight: .regular)
        streakLabel.textColor = .themeTextSecondary
        streakLabel.text = String(
            format: NSLocalizedString("insight_habit_streak", comment: ""),
            habit.currentStreak
        )

        let totalLabel = UILabel()
        totalLabel.font = UIFont.projectFont(ofSize: Layout.detailFontSize, weight: .regular)
        totalLabel.textColor = .themeTextSecondary
        totalLabel.text = String(
            format: NSLocalizedString("insight_habit_total", comment: ""),
            habit.totalCount
        )

        let rightStack = UIStackView(arrangedSubviews: [flameImageView, streakLabel, totalLabel])
        rightStack.axis = .horizontal
        rightStack.spacing = Layout.streakTotalSpacing
        rightStack.alignment = .center

        // Add to row
        rowView.addSubview(leftStack)
        rowView.addSubview(rightStack)

        leftStack.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualTo(rightStack.snp.left)
        }

        rightStack.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
        }

        return rowView
    }
}
