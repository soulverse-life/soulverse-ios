//
//  InsightSummaryView.swift
//  Soulverse
//

import UIKit
import SnapKit

class InsightSummaryView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let emoPetSize: CGFloat = 40
        static let spacing: CGFloat = 12
        static let summaryFontSize: CGFloat = 14
    }

    // MARK: - Subviews

    private let emoPetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "basic_first_level")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.projectFont(ofSize: Layout.summaryFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

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
        backgroundColor = .clear

        addSubview(emoPetImageView)
        addSubview(summaryLabel)

        emoPetImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(Layout.emoPetSize)
        }

        summaryLabel.snp.makeConstraints { make in
            make.left.equalTo(emoPetImageView.snp.right).offset(Layout.spacing)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(with text: String) {
        summaryLabel.text = text
    }
}
