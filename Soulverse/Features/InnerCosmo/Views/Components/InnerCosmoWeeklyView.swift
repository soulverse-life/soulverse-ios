//
//  InnerCosmoWeeklyView.swift
//  Soulverse
//

import SnapKit
import UIKit

/// Placeholder view for weekly emotion data
/// TODO: Implement weekly view based on design specifications
class InnerCosmoWeeklyView: UIView {

    // MARK: - UI Components

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("inner_cosmo_period_weekly", comment: "")
        label.font = UIFont.projectFont(ofSize: 18, weight: .medium)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
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
        backgroundColor = .clear

        addSubview(placeholderLabel)

        placeholderLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
