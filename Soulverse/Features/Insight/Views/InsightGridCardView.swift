//
//  InsightGridCardView.swift
//

import UIKit
import SnapKit

class InsightGridCardView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let nameFontSize: CGFloat = 13
        static let valueFontSize: CGFloat = 22
        static let verticalSpacing: CGFloat = 8
        static let borderWidth: CGFloat = 1
    }

    // MARK: - Style Constants

    private enum Style {
        static let activeBackground = UIColor.white.withAlphaComponent(0.15)
        static let lockedBackground = UIColor.white.withAlphaComponent(0.05)
    }

    // MARK: - Subviews

    private let backgroundColorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .themeTextPrimary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.nameFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.valueFontSize, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [iconImageView, nameLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = Layout.verticalSpacing
        stack.alignment = .leading
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
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = UIColor.themeSeparator.cgColor
        clipsToBounds = true

        addSubview(backgroundColorView)
        backgroundColorView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        addSubview(contentStack)

        contentStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.padding)
        }
    }

    // MARK: - Configuration

    func configure(with viewModel: InsightGridCardViewModel) {
        iconImageView.image = UIImage(systemName: viewModel.iconName)
        nameLabel.text = viewModel.name
        valueLabel.text = viewModel.value
        backgroundColorView.backgroundColor = viewModel.isLocked ? Style.lockedBackground : Style.activeBackground
    }
}
