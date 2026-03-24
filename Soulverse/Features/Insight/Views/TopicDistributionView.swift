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
        static let subtitleFontSize: CGFloat = 14
        static let topicNameFontSize: CGFloat = 14
        static let barHeight: CGFloat = 15
        static let barCornerRadius: CGFloat = 7.5
        static let rowHeight: CGFloat = 20
        static let rowSpacing: CGFloat = 10
        static let titleBottomSpacing: CGFloat = 8
        static let subtitleBottomSpacing: CGFloat = 16
        static let nameToBarSpacing: CGFloat = 8
        static let barWidthRatio: CGFloat = 0.55
        static let barRightInset: CGFloat = 20
        static let trackBackgroundAlpha: CGFloat = 0.2
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
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
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
        baseView.addSubview(subtitleLabel)
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

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        rowsStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.subtitleBottomSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: TopicDistributionViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle

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

        // Topic name label
        let nameLabel = UILabel()
        nameLabel.text = item.topic.localizedTitle
        nameLabel.font = UIFont.projectFont(ofSize: Layout.topicNameFontSize, weight: .regular)
        nameLabel.textColor = .themeTextSecondary
        nameLabel.lineBreakMode = .byClipping
        rowView.addSubview(nameLabel)

        // Bar track (background) — uses the topic's own dimmed color
        let barTrackView = UIView()
        barTrackView.backgroundColor = item.topic.mainColor.withAlphaComponent(Layout.trackBackgroundAlpha)
        barTrackView.layer.cornerRadius = Layout.barCornerRadius
        barTrackView.clipsToBounds = true
        rowView.addSubview(barTrackView)

        // Bar fill
        let barFillView = UIView()
        barFillView.backgroundColor = item.topic.mainColor
        barFillView.layer.cornerRadius = Layout.barCornerRadius
        barTrackView.addSubview(barFillView)

        // Layout
        nameLabel.setContentHuggingPriority(.required, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        barTrackView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Layout.barRightInset)
            make.centerY.equalToSuperview()
            make.height.equalTo(Layout.barHeight)
            make.width.equalToSuperview().multipliedBy(Layout.barWidthRatio)
        }

        let fillPercentage = item.percentage
        barFillView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            if fillPercentage > 0 {
                make.width.equalTo(barTrackView).multipliedBy(fillPercentage)
            } else {
                make.width.equalTo(0)
            }
        }

        rowView.snp.makeConstraints { make in
            make.height.equalTo(Layout.rowHeight)
        }

        return rowView
    }
}
