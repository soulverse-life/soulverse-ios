//
//  MoodEntryCardCell.swift
//  Soulverse
//
//  Card cell for displaying mood entry in horizontal scroll view.
//

import Kingfisher
import SnapKit
import UIKit

class MoodEntryCardCell: UICollectionViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "MoodEntryCardCell"

    weak var delegate: MoodEntryCardCellDelegate?

    private var currentEntry: MoodEntry?

    // MARK: - UI Components

    private let baseView: UIView = {
        let view = UIView()
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private let emotionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 18, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        return label
    }()

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 3
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let artworkContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = InnerCosmoLayout.moodEntryImageCornerRadius
        view.clipsToBounds = true
        view.backgroundColor = .clear
        return view
    }()

    private let artworkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private lazy var drawCTAButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("inner_cosmo_mood_entry_draw_cta", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 14, weight: .semibold)
        button.setTitleColor(.themeTextPrimary, for: .normal)
        button.backgroundColor = .themeButtonSecondaryBackground
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(drawButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        artworkImageView.image = nil
        artworkImageView.kf.cancelDownloadTask()
        currentEntry = nil
    }

    // MARK: - Setup

    private func setupUI() {
        // Ensure transparent backgrounds for glass effect to work
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        setupBaseView()
        setupContentViews()
        setupConstraints()
    }

    private func setupBaseView() {
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: .clear)
            visualEffectView.effect = glassEffect
            visualEffectView.layer.cornerRadius = InnerCosmoLayout.moodEntryCardCornerRadius
            visualEffectView.clipsToBounds = true
            visualEffectView.contentView.addSubview(baseView)
            contentView.addSubview(visualEffectView)

            visualEffectView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }

            UIView.animate {
                self.visualEffectView.effect = glassEffect
                self.visualEffectView.overrideUserInterfaceStyle = .light
            }
        } else {
            // Fallback: Use blur effect to simulate glass appearance
            contentView.addSubview(baseView)
            baseView.layer.cornerRadius = InnerCosmoLayout.moodEntryCardCornerRadius
            baseView.layer.borderWidth = 1
            baseView.layer.borderColor = UIColor.themeSeparator.cgColor
            baseView.backgroundColor = .white.withAlphaComponent(0.1)
            baseView.clipsToBounds = true
        }

        baseView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupContentViews() {
        baseView.addSubview(emotionLabel)
        baseView.addSubview(dateLabel)
        baseView.addSubview(quoteLabel)
        baseView.addSubview(artworkContainerView)

        artworkContainerView.addSubview(artworkImageView)
        artworkContainerView.addSubview(drawCTAButton)
    }

    private func setupConstraints() {
        let padding = InnerCosmoLayout.moodEntryCardPadding

        emotionLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(padding)
            make.trailing.lessThanOrEqualTo(dateLabel.snp.leading).offset(-8)
        }

        dateLabel.snp.makeConstraints { make in
            make.centerY.equalTo(emotionLabel)
            make.trailing.equalToSuperview().offset(-padding)
        }

        quoteLabel.snp.makeConstraints { make in
            make.top.equalTo(emotionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(padding)
        }

        artworkContainerView.snp.makeConstraints { make in
            make.top.equalTo(quoteLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.bottom.equalToSuperview().offset(-padding)
        }

        artworkImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        drawCTAButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(80)
            make.height.equalTo(32)
        }
    }

    // MARK: - Configuration

    func configure(with entry: MoodEntry) {
        currentEntry = entry

        emotionLabel.text = entry.emotion.displayName
        dateLabel.text = entry.formattedDate
        quoteLabel.text = entry.promptResponse

        if entry.hasArtwork, let urlString = entry.artworkURL, let url = URL(string: urlString) {
            // Has artwork - show image, hide blur and CTA
            artworkImageView.kf.setImage(with: url)
            artworkImageView.backgroundColor = .clear
            drawCTAButton.isHidden = true
        } else {
            // No artwork - show placeholder with blur and CTA
            artworkImageView.image = nil
            artworkImageView.backgroundColor = entry.color.withAlphaComponent(0.3)
            drawCTAButton.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func drawButtonTapped() {
        guard let entry = currentEntry else { return }
        delegate?.moodEntryCardDidTapDraw(self, entry: entry)
    }
}

// MARK: - Delegate Protocol

protocol MoodEntryCardCellDelegate: AnyObject {
    func moodEntryCardDidTapDraw(_ cell: MoodEntryCardCell, entry: MoodEntry)
}
