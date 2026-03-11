//
//  MoodCheckinActivityView.swift
//  Soulverse
//

import UIKit
import SnapKit

class MoodCheckinActivityView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let numberFontSize: CGFloat = 28
        static let descriptionFontSize: CGFloat = 12
        static let titleBottomSpacing: CGFloat = 16
        static let statsSpacing: CGFloat = 0
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

    private lazy var statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = Layout.statsSpacing
        return stackView
    }()

    private lazy var totalCheckinColumn: UIStackView = makeStatColumn(
        numberLabel: totalNumberLabel,
        descriptionLabel: totalDescriptionLabel
    )

    private lazy var streakColumn: UIStackView = makeStatColumn(
        numberLabel: streakNumberLabel,
        descriptionLabel: streakDescriptionLabel
    )

    private lazy var avgPerWeekColumn: UIStackView = makeStatColumn(
        numberLabel: avgNumberLabel,
        descriptionLabel: avgDescriptionLabel
    )

    private lazy var totalNumberLabel: UILabel = makeNumberLabel()
    private lazy var totalDescriptionLabel: UILabel = makeDescriptionLabel()
    private lazy var streakNumberLabel: UILabel = makeNumberLabel()
    private lazy var streakDescriptionLabel: UILabel = makeDescriptionLabel()
    private lazy var avgNumberLabel: UILabel = makeNumberLabel()
    private lazy var avgDescriptionLabel: UILabel = makeDescriptionLabel()

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
        statsStackView.addArrangedSubview(totalCheckinColumn)
        statsStackView.addArrangedSubview(streakColumn)
        statsStackView.addArrangedSubview(avgPerWeekColumn)

        baseView.addSubview(titleLabel)
        baseView.addSubview(statsStackView)

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
            baseView.layer.borderWidth = 1
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

        statsStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Factory Helpers

    private func makeNumberLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.numberFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }

    private func makeDescriptionLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.descriptionFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        return label
    }

    private func makeStatColumn(numberLabel: UILabel, descriptionLabel: UILabel) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [numberLabel, descriptionLabel])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 4
        return stackView
    }

    // MARK: - Configuration

    func configure(with viewModel: MoodCheckinActivityViewModel) {
        titleLabel.text = viewModel.title

        totalNumberLabel.text = "\(viewModel.totalCheckins)"
        totalDescriptionLabel.text = NSLocalizedString("insight_total_checkins", comment: "")

        streakNumberLabel.text = "\(viewModel.currentStreak)"
        streakDescriptionLabel.text = NSLocalizedString("insight_current_streak", comment: "")

        avgNumberLabel.text = String(format: "%.1f", viewModel.averagePerWeek)
        avgDescriptionLabel.text = NSLocalizedString("insight_avg_per_week", comment: "")
    }
}
