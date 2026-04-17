//
//  BundleSectionCardView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class BundleSectionCardView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let contentInsetVertical: CGFloat = 16
        static let contentInsetHorizontal: CGFloat = 16
        static let iconSize: CGFloat = 24
        static let iconToTitleSpacing: CGFloat = 12
        static let titleFontSize: CGFloat = 14
        static let checkmarkSize: CGFloat = 20
        static let checkmarkTopInset: CGFloat = 12
        static let checkmarkTrailingInset: CGFloat = 12
        static let cardHeight: CGFloat = 105
        static let borderWidth: CGFloat = 0.5
    }

    // MARK: - Properties

    var onTap: (() -> Void)?

    // MARK: - UI Elements

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themeTextSecondary
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .medium)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 2
        return label
    }()

    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themePrimary
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.isHidden = true
        return imageView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .themeCardBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.borderColor = UIColor.themeSeparator.cgColor
        clipsToBounds = true

        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(checkmarkImageView)

        setupConstraints()
    }

    private func setupConstraints() {
        snp.makeConstraints { make in
            make.height.equalTo(Layout.cardHeight)
        }

        iconImageView.snp.makeConstraints { make in
            make.bottom.equalTo(titleLabel.snp.top).offset(-Layout.iconToTitleSpacing)
            make.leading.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.width.height.equalTo(Layout.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.bottom.equalToSuperview().inset(Layout.contentInsetVertical)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.checkmarkTopInset)
            make.trailing.equalToSuperview().inset(Layout.checkmarkTrailingInset)
            make.width.height.equalTo(Layout.checkmarkSize)
        }
    }

    private func setupGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
        isUserInteractionEnabled = true
    }

    // MARK: - Actions

    @objc private func handleTap() {
        onTap?()
    }

    // MARK: - Configuration

    func configure(title: String, iconName: String, isCompleted: Bool) {
        titleLabel.text = title
        iconImageView.image = UIImage(systemName: iconName)
        checkmarkImageView.isHidden = !isCompleted
    }
}
