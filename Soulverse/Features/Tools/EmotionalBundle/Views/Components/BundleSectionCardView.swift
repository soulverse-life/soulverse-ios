//
//  BundleSectionCardView.swift
//  Soulverse
//
//  Created on 2026/4/16.
//

import UIKit
import SnapKit

final class BundleSectionCardView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let contentInsetVertical: CGFloat = 16
        static let contentInsetHorizontal: CGFloat = 20
        static let checkmarkSize: CGFloat = 24
        static let titleFontSize: CGFloat = 16
        static let minimumHeight: CGFloat = ViewComponentConstants.navigationButtonSize
        static let titleToCheckmarkSpacing: CGFloat = 12
    }

    // MARK: - Properties

    var onTap: (() -> Void)?

    // MARK: - UI Elements

    private let baseView: UIView = {
        let view = UIView()
        view.backgroundColor = .themeCardBackground
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.titleFontSize, weight: .medium)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 1
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
        baseView.addSubview(titleLabel)
        baseView.addSubview(checkmarkImageView)

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = Layout.cornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.greaterThanOrEqualTo(Layout.minimumHeight)
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            addSubview(baseView)
            baseView.layer.cornerRadius = Layout.cornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.clipsToBounds = true

            baseView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
                make.height.greaterThanOrEqualTo(Layout.minimumHeight)
            }
        }

        setupConstraints()
    }

    private func setupConstraints() {
        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.top.bottom.equalToSuperview().inset(Layout.contentInsetVertical)
            make.trailing.lessThanOrEqualTo(checkmarkImageView.snp.leading).offset(-Layout.titleToCheckmarkSpacing)
        }

        checkmarkImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.contentInsetHorizontal)
            make.centerY.equalToSuperview()
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

    func configure(title: String, isCompleted: Bool) {
        titleLabel.text = title
        checkmarkImageView.isHidden = !isCompleted
    }
}
