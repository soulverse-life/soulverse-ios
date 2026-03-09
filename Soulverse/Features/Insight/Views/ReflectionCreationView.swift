//
//  ReflectionCreationView.swift
//

import UIKit
import SnapKit

class ReflectionCreationView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let stackSpacing: CGFloat = 12
        static let cardCornerRadius: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let iconSize: CGFloat = 28
        static let verticalSpacing: CGFloat = 8
        static let numberFontSize: CGFloat = 28
        static let descriptionFontSize: CGFloat = 12
    }

    // MARK: - Subviews

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.stackSpacing
        stack.distribution = .fillEqually
        return stack
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
        addSubview(stackView)

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: ReflectionCreationViewModel) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let journalCard = createMiniCard(
            iconName: "book.fill",
            count: viewModel.journalCount,
            label: NSLocalizedString("insight_journals", comment: "")
        )

        let drawingCard = createMiniCard(
            iconName: "paintbrush.fill",
            count: viewModel.drawingCount,
            label: NSLocalizedString("insight_drawings", comment: "")
        )

        stackView.addArrangedSubview(journalCard)
        stackView.addArrangedSubview(drawingCard)
    }

    // MARK: - Mini Card Builder

    private func createMiniCard(iconName: String, count: Int, label: String) -> UIView {
        let baseView = UIView()

        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: iconName)
        iconImageView.tintColor = .themePrimary
        iconImageView.contentMode = .scaleAspectFit

        let numberLabel = UILabel()
        numberLabel.text = "\(count)"
        numberLabel.font = UIFont.projectFont(ofSize: Layout.numberFontSize, weight: .bold)
        numberLabel.textColor = .themeTextPrimary
        numberLabel.textAlignment = .center

        let descriptionLabel = UILabel()
        descriptionLabel.text = label
        descriptionLabel.font = UIFont.projectFont(ofSize: Layout.descriptionFontSize, weight: .regular)
        descriptionLabel.textColor = .themeTextSecondary
        descriptionLabel.textAlignment = .center

        let contentStack = UIStackView(arrangedSubviews: [iconImageView, numberLabel, descriptionLabel])
        contentStack.axis = .vertical
        contentStack.spacing = Layout.verticalSpacing
        contentStack.alignment = .center

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        if #available(iOS 26.0, *) {
            let visualEffectView = UIVisualEffectView()
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cardCornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(contentStack)

            baseView.addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            contentStack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(Layout.cardPadding)
            }

            UIView.animate {
                visualEffectView.effect = glassEffect
                visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            baseView.layer.cornerRadius = Layout.cardCornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .themeCardBackground
            baseView.clipsToBounds = true

            baseView.addSubview(contentStack)

            contentStack.snp.makeConstraints { make in
                make.edges.equalToSuperview().inset(Layout.cardPadding)
            }
        }

        return baseView
    }
}
