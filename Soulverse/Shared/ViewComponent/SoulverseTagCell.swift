//
//  SoulverseTagCell.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import SnapKit
import UIKit

/// A custom tag cell that mimics SoulverseButton styling
class SoulverseTagCell: UICollectionViewCell {

    static let reuseIdentifier = "SoulverseTagCell"

    // MARK: - Layout Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 24
        static let labelHorizontalInset: CGFloat = 18
        static let minHeight: CGFloat = 50
        static let animationDuration: TimeInterval = 0.1
        static let highlightedScale: CGFloat = 0.95
        static let fontSize: CGFloat = 17.0
        static let labelHorizontalTotalInset: CGFloat = labelHorizontalInset * 2
    }

    // MARK: - UI Components

    private let baseView = UIView()
    private let visualEffectView = UIVisualEffectView()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textAlignment = .center
        return label
    }()

    // MARK: - Properties

    override var isHighlighted: Bool {
        didSet {
            animateScale(isHighlighted: isHighlighted)
        }
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: - Setup

    private func setupView() {
        // Clear background of the cell proper
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        // Setup Base View
        contentView.addSubview(baseView)
        baseView.layer.cornerRadius = Layout.cornerRadius
        baseView.clipsToBounds = true

        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Setup Visual Effect View
        visualEffectView.layer.cornerRadius = Layout.cornerRadius
        visualEffectView.clipsToBounds = true
        visualEffectView.isUserInteractionEnabled = false
        baseView.addSubview(visualEffectView)

        visualEffectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Configure hierarchy based on iOS version
        if #available(iOS 26.0, *) {
            // iOS 26+: Use glass effect always
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.isHidden = false
            visualEffectView.overrideUserInterfaceStyle = .light

            // Add label to visual effect content view
            visualEffectView.contentView.addSubview(titleLabel)
        } else {
            // < iOS 26: No glass effect
            visualEffectView.isHidden = true

            // Add label directly to base view
            baseView.addSubview(titleLabel)
        }

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0, left: Layout.labelHorizontalInset, bottom: 0,
                    right: Layout.labelHorizontalInset))
            make.height.greaterThanOrEqualTo(Layout.minHeight)
        }
    }

    // MARK: - Configuration

    func configure(item: SoulverseTagsItemData) {
        titleLabel.text = item.title
        updateAppearance(isSelected: item.isSelected, isEnabled: item.isEnabled)
    }

    private func updateAppearance(isSelected: Bool, isEnabled: Bool) {
        if isSelected {
            titleLabel.font = .projectFont(ofSize: Layout.fontSize, weight: .semibold)
            baseView.backgroundColor = .themeButtonPrimaryBackground
            titleLabel.textColor = .themeButtonPrimaryText
        } else {
            titleLabel.font = .projectFont(ofSize: Layout.fontSize, weight: .regular)
            baseView.backgroundColor = .themeButtonSecondaryBackground
            titleLabel.textColor = .themeButtonSecondaryText
        }

        baseView.layer.borderWidth = 0
    }

    // MARK: - Animation

    private func animateScale(isHighlighted: Bool) {
        UIView.animate(withDuration: Layout.animationDuration) {
            let scale: CGFloat = isHighlighted ? Layout.highlightedScale : 1.0
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }

    // MARK: - Sizing

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {
        // Calculate size based on label content + padding
        let labelSize = titleLabel.systemLayoutSizeFitting(
            CGSize(
                width: targetSize.width - Layout.labelHorizontalTotalInset,
                height: targetSize.height),
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel
        )

        let width = labelSize.width + Layout.labelHorizontalTotalInset
        let height = max(Layout.minHeight, labelSize.height)  // maintain minimum height 50

        return CGSize(width: width, height: height)
    }

    override var intrinsicContentSize: CGSize {
        return systemLayoutSizeFitting(
            UIView.layoutFittingCompressedSize, withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .fittingSizeLevel)
    }
}
