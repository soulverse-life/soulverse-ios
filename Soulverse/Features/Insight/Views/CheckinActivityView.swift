//
//  CheckinActivityView.swift
//

import UIKit
import SnapKit

class CheckinActivityView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 20
        static let titleFontSize: CGFloat = 18
        static let subtitleFontSize: CGFloat = 13
        static let titleSubtitleSpacing: CGFloat = 4
        static let headerGridSpacing: CGFloat = 16
        static let gridSpacing: CGFloat = 12
        static let innerCardCornerRadius: CGFloat = 16
        static let innerCardPadding: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let nameFontSize: CGFloat = 13
        static let valueFontSize: CGFloat = 22
        static let innerVerticalSpacing: CGFloat = 8
        static let borderWidth: CGFloat = 1
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

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var gridStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = Layout.gridSpacing
        stackView.distribution = .fillEqually
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
        baseView.addSubview(gridStackView)

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

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleSubtitleSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
        }

        gridStackView.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.headerGridSpacing)
            make.left.right.equalToSuperview().inset(Layout.cardPadding)
            make.bottom.equalToSuperview().inset(Layout.cardPadding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: CheckinActivityViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle

        gridStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let journalCard = createGridCard(
            iconName: "doc.text.fill",
            name: NSLocalizedString("insight_journals", comment: ""),
            value: String(format: NSLocalizedString("insight_journal_entries", comment: ""), viewModel.journalCount)
        )

        let drawingCard = createGridCard(
            iconName: "drop.fill",
            name: NSLocalizedString("insight_drawings", comment: ""),
            value: String(format: NSLocalizedString("insight_drawing_pieces", comment: ""), viewModel.drawingCount)
        )

        gridStackView.addArrangedSubview(journalCard)
        gridStackView.addArrangedSubview(drawingCard)
    }

    // MARK: - Grid Card Builder

    private func createGridCard(iconName: String, name: String, value: String) -> UIView {
        let container = UIView()

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = .themeTextPrimary
        iconImageView.contentMode = .scaleAspectFit

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = UIFont.projectFont(ofSize: Layout.nameFontSize, weight: .regular)
        nameLabel.textColor = .themeTextSecondary

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.projectFont(ofSize: Layout.valueFontSize, weight: .bold)
        valueLabel.textColor = .themeTextPrimary

        let contentStack = UIStackView(arrangedSubviews: [iconImageView, nameLabel, valueLabel])
        contentStack.axis = .vertical
        contentStack.spacing = Layout.innerVerticalSpacing
        contentStack.alignment = .leading

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        if #available(iOS 26.0, *) {
            let innerEffect = UIVisualEffectView()
            let glassEffect = UIGlassEffect(style: .clear)
            innerEffect.effect = glassEffect
            innerEffect.layer.cornerRadius = Layout.innerCardCornerRadius
            innerEffect.clipsToBounds = true
            innerEffect.contentView.addSubview(contentStack)

            container.addSubview(innerEffect)

            innerEffect.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            contentStack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(Layout.innerCardPadding)
            }

            UIView.animate {
                innerEffect.effect = glassEffect
                innerEffect.overrideUserInterfaceStyle = .light
            }
        } else {
            container.layer.cornerRadius = Layout.innerCardCornerRadius
            container.layer.borderWidth = Layout.borderWidth
            container.layer.borderColor = UIColor.themeSeparator.cgColor
            container.backgroundColor = .themeCardBackground
            container.clipsToBounds = true

            container.addSubview(contentStack)

            contentStack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(Layout.innerCardPadding)
            }
        }

        return container
    }
}
