//
//  ColorSummaryView.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

/// A view that displays the selected color from the previous step
/// Shows a color circle (with white background to prevent alpha mixing) and descriptive label
class ColorSummaryView: UIView {

    // MARK: - UI Elements

    private lazy var colorDisplayContainerView: UIView = {
        let containerView = UIView()

        // White background layer (prevents color mixing with parent background)
        let whiteBackgroundView = UIView()
        whiteBackgroundView.backgroundColor = .white
        whiteBackgroundView.layer.cornerRadius = ViewComponentConstants.colorDisplaySize / 2
        containerView.addSubview(whiteBackgroundView)

        whiteBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        // Colored view on top
        coloredView = UIView()
        coloredView.layer.cornerRadius = ViewComponentConstants.colorDisplaySize / 2
        containerView.addSubview(coloredView)

        coloredView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        return containerView
    }()

    private var coloredView: UIView!

    private lazy var colorLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_naming_color_selected", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        return label
    }()

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
        addSubview(colorDisplayContainerView)
        addSubview(colorLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        colorDisplayContainerView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalTo(ViewComponentConstants.colorDisplaySize)
        }

        colorLabel.snp.makeConstraints { make in
            make.left.equalTo(colorDisplayContainerView.snp.right).offset(12)
            make.centerY.equalTo(colorDisplayContainerView)
            make.right.lessThanOrEqualToSuperview()
        }
    }

    // MARK: - Public Methods

    /// Configure the view with a selected color
    /// - Parameter color: The color to display (including alpha component)
    func configure(color: UIColor) {
        coloredView.backgroundColor = color
    }
}
