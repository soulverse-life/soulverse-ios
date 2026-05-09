//
//  EightDimensionsCardView.swift
//  Soulverse
//
//  Composite card: section title + radar overlay + State-of-Change indicator.
//  Replaces the placeholder host in Plan 2's QuestViewController.
//

import UIKit
import SnapKit

final class EightDimensionsCardView: UIView {

    private enum Layout {
        static let outerInset: CGFloat = 12
        static let cornerRadius: CGFloat = 16
        static let radarHeight: CGFloat = 220
        static let socHeight: CGFloat = 56
        static let titleHeight: CGFloat = 24
    }

    private let titleLabel = UILabel()
    private let radarOverlay = QuestRadarOverlayView()
    private let socIndicator = StateOfChangeIndicatorView()
    private let lockedView = QuestLockedCardView()

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        backgroundColor = .themeCardBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.masksToBounds = true

        titleLabel.text = NSLocalizedString("quest_eight_dim_card_title", comment: "")
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .themeTextPrimary

        let stack = UIStackView(arrangedSubviews: [titleLabel, radarOverlay, socIndicator])
        stack.axis = .vertical
        stack.spacing = 12
        addSubview(stack)
        addSubview(lockedView)

        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        radarOverlay.snp.makeConstraints { make in
            make.height.equalTo(Layout.radarHeight)
        }
        socIndicator.snp.makeConstraints { make in
            make.height.equalTo(Layout.socHeight)
        }
        titleLabel.snp.makeConstraints { make in
            make.height.equalTo(Layout.titleHeight)
        }
        lockedView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(model: EightDimensionsRenderModel, lockedHint: String) {
        if model.isCardLocked {
            lockedView.isHidden = false
            lockedView.configure(
                title: NSLocalizedString("quest_eight_dim_card_title", comment: ""),
                hint: lockedHint
            )
            radarOverlay.isHidden = true
            socIndicator.isHidden = true
            titleLabel.isHidden = true
        } else {
            lockedView.isHidden = true
            radarOverlay.isHidden = false
            titleLabel.isHidden = false
            radarOverlay.configure(model: model)
            socIndicator.configure(model: model.stateOfChangeIndicator)
        }
    }
}
