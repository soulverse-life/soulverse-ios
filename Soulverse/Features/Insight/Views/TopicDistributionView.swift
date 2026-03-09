//
//  TopicDistributionView.swift
//  Soulverse
//

import UIKit
import SnapKit

class TopicDistributionView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let topicNameFontSize: CGFloat = 14
        static let countFontSize: CGFloat = 14
        static let iconSize: CGFloat = 20
        static let barHeight: CGFloat = 8
        static let barCornerRadius: CGFloat = 4
        static let rowSpacing: CGFloat = 10
        static let titleBottomSpacing: CGFloat = 16
        static let iconToNameSpacing: CGFloat = 8
        static let nameToBarSpacing: CGFloat = 8
        static let barToCountSpacing: CGFloat = 8
        static let nameWidth: CGFloat = 70
        static let countWidth: CGFloat = 28
        static let trackAlpha: CGFloat = 0.3
        static let minimumBarPercentage: Double = 0.02
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

        rowsStackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: TopicDistributionViewModel) {
        titleLabel.text = viewModel.title

        // Remove existing rows
        rowsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in viewModel.items {
            let rowView = createRowView(for: item)
            rowsStackView.addArrangedSubview(rowView)
        }
    }

    // MARK: - Row Construction

    private func createRowView(for item: TopicDistributionViewModel.TopicDistributionItem) -> UIView {
        let rowView = UIView()

        // Icon
        let iconImageView = UIImageView()
        iconImageView.image = item.topic.iconImage.withRenderingMode(.alwaysTemplate)
        iconImageView.tintColor = item.topic.mainColor
        iconImageView.contentMode = .scaleAspectFit
        rowView.addSubview(iconImageView)

        // Topic name label
        let nameLabel = UILabel()
        nameLabel.text = item.topic.localizedTitle
        nameLabel.font = UIFont.projectFont(ofSize: Layout.topicNameFontSize, weight: .regular)
        nameLabel.textColor = .themeTextSecondary
        rowView.addSubview(nameLabel)

        // Bar track (background)
        let barTrackView = UIView()
        barTrackView.backgroundColor = UIColor.themeSeparator.withAlphaComponent(Layout.trackAlpha)
        barTrackView.layer.cornerRadius = Layout.barCornerRadius
        barTrackView.clipsToBounds = true
        rowView.addSubview(barTrackView)

        // Bar fill
        let barFillView = UIView()
        barFillView.backgroundColor = item.topic.mainColor
        barFillView.layer.cornerRadius = Layout.barCornerRadius
        barTrackView.addSubview(barFillView)

        // Count label
        let countLabel = UILabel()
        countLabel.text = "\(item.count)"
        countLabel.font = UIFont.projectFont(ofSize: Layout.countFontSize, weight: .medium)
        countLabel.textColor = .themeTextPrimary
        countLabel.textAlignment = .right
        rowView.addSubview(countLabel)

        // Layout
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.iconSize)
        }

        nameLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(Layout.iconToNameSpacing)
            make.centerY.equalToSuperview()
            make.width.equalTo(Layout.nameWidth)
        }

        barTrackView.snp.makeConstraints { make in
            make.left.equalTo(nameLabel.snp.right).offset(Layout.nameToBarSpacing)
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.barHeight)
            make.right.equalTo(countLabel.snp.left).offset(-Layout.barToCountSpacing)
        }

        let clampedPercentage = max(item.percentage, Layout.minimumBarPercentage)
        barFillView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(barTrackView).multipliedBy(clampedPercentage)
        }

        countLabel.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(Layout.countWidth)
        }

        rowView.snp.makeConstraints { make in
            make.height.equalTo(Layout.iconSize)
        }

        return rowView
    }
}
