//
//  JournalEmotionHeaderView.swift
//  Soulverse
//
//  Top section of the journal editor — shows a localized subtitle plus
//  an emotion planet + emotion name describing the active check-in.
//

import UIKit
import SnapKit

final class JournalEmotionHeaderView: UIView {

    // MARK: - Layout Constants

    private enum Layout {
        static let subtitleFontSize: CGFloat = 22
        static let emotionNameFontSize: CGFloat = 34
        static let subtitleToPlanetRowSpacing: CGFloat = 16
        static let planetRowSpacing: CGFloat = 8
    }

    // MARK: - Initialization

    init(colorHex: String, intensity: Double, emotionName: String) {
        super.init(frame: .zero)
        setupView(colorHex: colorHex, intensity: intensity, emotionName: emotionName)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView(colorHex: String, intensity: Double, emotionName: String) {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        subtitleLabel.textColor = .themeTextPrimary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = NSLocalizedString("journal_editor_subtitle", comment: "")

        let planetData = EmotionPlanetData(
            emotion: "",
            colorHex: colorHex,
            sizeMultiplier: 1.0,
            intensity: intensity
        )
        let planet = EmotionPlanetView(data: planetData)
        let planetSize = planet.calculateSize()

        let emotionNameLabel = UILabel()
        emotionNameLabel.font = .projectFont(ofSize: Layout.emotionNameFontSize, weight: .semibold)
        emotionNameLabel.textColor = .themeTextPrimary
        emotionNameLabel.textAlignment = .center
        emotionNameLabel.text = emotionName

        let planetRowContainer = UIView()

        addSubview(subtitleLabel)
        addSubview(planetRowContainer)
        planetRowContainer.addSubview(planet)
        planetRowContainer.addSubview(emotionNameLabel)

        subtitleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
        }

        planetRowContainer.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.subtitleToPlanetRowSpacing)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
            make.bottom.equalToSuperview()
        }

        planet.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(planetSize.width)
            make.height.equalTo(planetSize.height)
        }

        emotionNameLabel.snp.makeConstraints { make in
            make.left.equalTo(planet.snp.right).offset(Layout.planetRowSpacing)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }
}
