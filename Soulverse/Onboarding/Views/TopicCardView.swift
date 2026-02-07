//
//  TopicCardView.swift
//  Soulverse
//
//

import UIKit
import SnapKit

class TopicCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let iconSize: CGFloat = 28
        static let iconTopOffset: CGFloat = 12
        static let titleTopOffset: CGFloat = 4
        static let selectedBorderWidth: CGFloat = 3
    }

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    var isCardSelected: Bool = false {
        didSet {
            updateSelectionState()
        }
    }

    init(topic: Topic) {
        super.init(frame: .zero)

        backgroundColor = topic.mainColor
        layer.cornerRadius = Layout.cornerRadius
        layer.masksToBounds = true

        addSubview(iconImageView)
        addSubview(titleLabel)

        iconImageView.image = topic.iconImage
        titleLabel.text = topic.localizedTitle

        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(Layout.iconTopOffset)
            make.width.height.equalTo(Layout.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(Layout.titleTopOffset)
            make.left.right.equalToSuperview().inset(12)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateSelectionState() {
        UIView.animate(withDuration: AnimationConstant.defaultDuration) {
            if self.isCardSelected {
                self.layer.borderWidth = Layout.selectedBorderWidth
                self.layer.borderColor = UIColor.white.cgColor
                self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            } else {
                self.layer.borderWidth = 0
                self.transform = .identity
            }
        }
    }
}
