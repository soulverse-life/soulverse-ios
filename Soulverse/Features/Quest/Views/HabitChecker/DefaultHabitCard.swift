//
//  DefaultHabitCard.swift
//  Soulverse
//
//  Visual card for one of the three fixed default habits. Renders the
//  habit's per-color accent (icon + today total + increment-button tints)
//  inside a subtle tinted sub-card.
//

import UIKit
import SnapKit

protocol DefaultHabitCardDelegate: AnyObject {
    /// Sent when one of the increment buttons on `card` is tapped. Returns
    /// `true` if the increment was applied, `false` if rejected (e.g., the
    /// minute-cap blocked it). The card uses the result to pick the
    /// success/rejection animation.
    func defaultHabitCard(_ card: DefaultHabitCard, didTapIncrement amount: Int) -> Bool
}

final class DefaultHabitCard: UIView {

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

    private var accentColor: UIColor = .themeTextPrimary
    /// Tracks the increment values currently rendered as buttons. Used by
    /// `configure` to skip the tear-down + rebuild when the array hasn't
    /// changed — otherwise every viewmodel publish would destroy the very
    /// button the user just tapped, killing the pulse animation mid-flight.
    private var currentIncrements: [Int] = []

    weak var delegate: DefaultHabitCardDelegate?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    /// Configure the card with the habit data + its per-habit accent style.
    /// (Card background uses a neutral theme surface; accent applies only to
    /// the today-total label and the increment-button tints.)
    func configure(_ model: HabitCardModel, accentColor: UIColor, iconName: String) {
        self.accentColor = accentColor

        iconImageView.image = UIImage(systemName: iconName)
        titleLabel.text = NSLocalizedString(model.titleKey, comment: "")
        totalLabel.text = String(
            format: NSLocalizedString("quest_habit_today_format", comment: ""),
            model.todayTotal,
            model.unit
        )
        totalLabel.textColor = accentColor

        if currentIncrements != model.increments {
            buttonStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for amount in model.increments {
                buttonStack.addArrangedSubview(makeIncrementButton(amount: amount))
            }
            currentIncrements = model.increments
        } else {
            // Increments unchanged — refresh existing button tints in case
            // the accentColor changed.
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

        let titleRow = UIStackView(arrangedSubviews: [iconImageView, titleLabel, totalLabel])
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
            let applied = self.delegate?.defaultHabitCard(self, didTapIncrement: amount) ?? false
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
