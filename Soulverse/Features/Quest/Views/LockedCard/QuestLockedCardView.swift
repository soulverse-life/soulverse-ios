//
//  QuestLockedCardView.swift
//  Soulverse
//

import UIKit
import SnapKit

final class QuestLockedCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 18
        static let contentInset: CGFloat = 24
        static let lockIconSize: CGFloat = 28
        static let titleTopSpacing: CGFloat = 12
        static let hintTopSpacing: CGFloat = 4
        static let titleFontSize: CGFloat = 16
        static let hintFontSize: CGFloat = 13
    }

    var titleText: String { return titleLabel.text ?? "" }
    var hintText: String { return hintLabel.text ?? "" }
    var isHintHidden: Bool { return hintLabel.isHidden }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private let cardContent = UIView()

    private let lockIconView: UIImageView = {
        let v = UIImageView(image: UIImage(systemName: "lock.fill"))
        v.tintColor = .themeTextSecondary
        v.contentMode = .scaleAspectFit
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.titleFontSize, weight: .semibold)
        l.textColor = .themeTextPrimary
        l.numberOfLines = 1
        l.textAlignment = .center
        return l
    }()

    private let hintLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.hintFontSize, weight: .regular)
        l.textColor = .themeTextSecondary
        l.numberOfLines = 0
        l.textAlignment = .center
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        cardContent.addSubview(lockIconView)
        cardContent.addSubview(titleLabel)
        cardContent.addSubview(hintLabel)

        ViewComponentConstants.applyGlassCardEffect(
            to: self,
            visualEffectView: visualEffectView,
            contentView: cardContent,
            cornerRadius: Layout.cornerRadius
        )

        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        lockIconView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.contentInset)
            make.centerX.equalToSuperview()
            make.size.equalTo(Layout.lockIconSize)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(lockIconView.snp.bottom).offset(Layout.titleTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.contentInset)
        }
        hintLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.hintTopSpacing)
            make.left.right.equalToSuperview().inset(Layout.contentInset)
            make.bottom.equalToSuperview().inset(Layout.contentInset)
        }
    }

    func configure(title: String, hint: String) {
        titleLabel.text = title
        if hint.isEmpty {
            hintLabel.text = nil
            hintLabel.isHidden = true
        } else {
            hintLabel.text = hint
            hintLabel.isHidden = false
        }
    }
}
