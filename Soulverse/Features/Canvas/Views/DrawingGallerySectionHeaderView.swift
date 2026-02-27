//
//  DrawingGallerySectionHeaderView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class DrawingGallerySectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = "DrawingGallerySectionHeaderView"

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-4)
        }
    }

    // MARK: - Configuration

    func configure(title: String) {
        titleLabel.text = title
    }
}
