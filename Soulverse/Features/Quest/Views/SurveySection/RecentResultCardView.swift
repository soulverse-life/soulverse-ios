//
//  RecentResultCardView.swift
//  Soulverse
//
//  Single completed-recently card.
//

import UIKit
import SnapKit

final class RecentResultCardView: UIView {

    private enum Layout {
        static let padding: CGFloat = 14
        static let titleFontSize: CGFloat = 15
        static let summaryFontSize: CGFloat = 13
        static let dateFontSize: CGFloat = 11
    }

    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let dateLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    var onTap: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .themeCardBackground
        layer.cornerRadius = QuestLayout.cardCornerRadius
        layer.masksToBounds = true

        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .regular)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.numberOfLines = 1

        summaryLabel.font = .projectFont(ofSize: Layout.summaryFontSize, weight: .regular)
        summaryLabel.textColor = .themeTextSecondary
        summaryLabel.numberOfLines = 2

        dateLabel.font = .projectFont(ofSize: Layout.dateFontSize, weight: .regular)
        dateLabel.textColor = .themeTextSecondary

        chevron.tintColor = .themeTextSecondary
        chevron.contentMode = .scaleAspectFit

        let leftStack = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, dateLabel])
        leftStack.axis = .vertical
        leftStack.spacing = 4
        addSubview(leftStack)
        addSubview(chevron)

        chevron.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(Layout.padding)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        leftStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.padding)
            make.left.equalToSuperview().inset(Layout.padding)
            make.right.equalTo(chevron.snp.left).offset(-8)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    @objc private func handleTap() { onTap?() }

    func configure(model: RecentResultCardModel) {
        titleLabel.text = NSLocalizedString(model.titleKey, comment: "")
        summaryLabel.text = NSLocalizedString(model.summaryKey, comment: "")
        dateLabel.text = Self.dateFormatter.string(from: model.submittedAt)
    }

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()
}
