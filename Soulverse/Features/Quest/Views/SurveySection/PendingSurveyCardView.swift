//
//  PendingSurveyCardView.swift
//  Soulverse
//
//  Single deck card. Used both as the front (tappable) and as a stacked
//  background slice (non-interactive, slightly inset).
//

import UIKit
import SnapKit

final class PendingSurveyCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let padding: CGFloat = 16
        static let titleSpacing: CGFloat = 6
        static let titleFontSize: CGFloat = 17
        static let bodyFontSize: CGFloat = 13
    }

    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let chevronImageView = UIImageView()

    var onTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .themeCardBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.masksToBounds = true

        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.numberOfLines = 0

        bodyLabel.font = .projectFont(ofSize: Layout.bodyFontSize, weight: .regular)
        bodyLabel.textColor = .themeTextSecondary
        bodyLabel.numberOfLines = 0

        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .themeTextSecondary
        chevronImageView.contentMode = .scaleAspectFit

        addSubview(titleLabel)
        addSubview(bodyLabel)
        addSubview(chevronImageView)

        chevronImageView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Layout.padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.padding)
            make.left.equalToSuperview().offset(Layout.padding)
            make.right.equalTo(chevronImageView.snp.left).offset(-8)
        }
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.titleSpacing)
            make.left.equalTo(titleLabel)
            make.right.equalTo(titleLabel)
            make.bottom.equalToSuperview().inset(Layout.padding)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() { onTap?() }

    func configure(title: String, body: String, isInteractive: Bool) {
        titleLabel.text = title
        bodyLabel.text = body
        chevronImageView.isHidden = !isInteractive
        isUserInteractionEnabled = isInteractive
        if !isInteractive {
            alpha = 0.6
        }
    }
}
