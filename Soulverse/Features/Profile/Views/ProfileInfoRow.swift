//
//  ProfileInfoRow.swift
//  Soulverse
//

import SnapKit
import UIKit

class ProfileInfoRow: UIView {

    private enum Layout {
        static let labelSpacing: CGFloat = 4
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .themeTextPrimary
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(titleLabel)
        addSubview(valueLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.labelSpacing)
            make.left.right.bottom.equalToSuperview()
        }
    }

    func configure(label: String, value: String?) {
        titleLabel.text = label
        valueLabel.text = value ?? "—"
    }
}
