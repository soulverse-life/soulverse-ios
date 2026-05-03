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
        static let subtitleFontSize: CGFloat = 17
        static let emotionNameFontSize: CGFloat = 28
        static let subtitleToPlanetRowSpacing: CGFloat = 16
        static let planetRowSpacing: CGFloat = 8
    }

    // MARK: - UI Elements

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = NSLocalizedString("journal_editor_subtitle", comment: "")
        return label
    }()

    private let planetRowContainer: UIView = {
        let view = UIView()
        return view
    }()

    private let emotionNameLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: Layout.emotionNameFontSize, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private var planetView: EmotionPlanetView?

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
        addSubview(subtitleLabel)
        addSubview(planetRowContainer)

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
    }

    // MARK: - Public API

    /// Configure with the active check-in's emotion. Hides itself if either
    /// `colorHex` or `emotionName` is missing.
    /// - Parameter intensity: kept for API symmetry with the check-in detail page;
    ///   the planet itself uses the colorHex as-is to match existing screens.
    func configure(colorHex: String?, intensity: Double, emotionName: String?) {
        let trimmedName = emotionName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard let colorHex = colorHex, !colorHex.isEmpty, !trimmedName.isEmpty else {
            isHidden = true
            snp.remakeConstraints { _ in }
            return
        }

        isHidden = false
        rebuildPlanetRow(colorHex: colorHex, emotionName: trimmedName)
    }

    // MARK: - Private

    private func rebuildPlanetRow(colorHex: String, emotionName: String) {
        // Tear down any previous content
        planetRowContainer.subviews.forEach { $0.removeFromSuperview() }
        planetView = nil

        let planetData = EmotionPlanetData(
            emotion: "",
            colorHex: colorHex,
            sizeMultiplier: 1.0
        )
        let planet = EmotionPlanetView(data: planetData)
        let size = planet.calculateSize()

        emotionNameLabel.text = emotionName

        planetRowContainer.addSubview(planet)
        planetRowContainer.addSubview(emotionNameLabel)

        planet.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }

        emotionNameLabel.snp.makeConstraints { make in
            make.left.equalTo(planet.snp.right).offset(Layout.planetRowSpacing)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }

        self.planetView = planet
    }
}
