//
//  ActionTagView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import SnapKit
import UIKit

/// A lightweight tag button view matching SoulverseTagCell styling.
/// Use in a UIStackView for simple, centered tag layouts.
class ActionTagView: UIView {

    // MARK: - Layout

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let horizontalInset: CGFloat = 18
        static let minHeight: CGFloat = 44
        static let fontSize: CGFloat = 17.0
    }

    // MARK: - Properties

    private(set) var isSelectedState: Bool = false

    private let baseView = UIView()
    private let visualEffectView = UIVisualEffectView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    // MARK: - Initialization

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        addSubview(baseView)
        baseView.layer.cornerRadius = Layout.cornerRadius
        baseView.clipsToBounds = true

        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        visualEffectView.layer.cornerRadius = Layout.cornerRadius
        visualEffectView.clipsToBounds = true
        visualEffectView.isUserInteractionEnabled = false
        baseView.addSubview(visualEffectView)

        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.isHidden = false
            visualEffectView.overrideUserInterfaceStyle = .light
            visualEffectView.contentView.addSubview(titleLabel)
        } else {
            visualEffectView.isHidden = true
            baseView.addSubview(titleLabel)
        }

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(top: 0, left: Layout.horizontalInset, bottom: 0, right: Layout.horizontalInset))
            make.height.greaterThanOrEqualTo(Layout.minHeight)
        }

        updateAppearance()
    }

    // MARK: - Public

    func setSelected(_ selected: Bool) {
        guard isSelectedState != selected else { return }
        isSelectedState = selected
        updateAppearance()
    }

    // MARK: - Private

    private func updateAppearance() {
        if isSelectedState {
            titleLabel.font = .projectFont(ofSize: Layout.fontSize, weight: .semibold)
            baseView.backgroundColor = .themeButtonPrimaryBackground
            titleLabel.textColor = .themeButtonPrimaryText
        } else {
            titleLabel.font = .projectFont(ofSize: Layout.fontSize, weight: .regular)
            baseView.backgroundColor = .themeButtonSecondaryBackground
            titleLabel.textColor = .themeButtonSecondaryText
        }
    }
}
