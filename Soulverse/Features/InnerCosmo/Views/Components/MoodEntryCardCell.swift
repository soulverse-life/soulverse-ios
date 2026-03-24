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

    private var currentEntry: MoodEntryCardCellViewModel?

    // MARK: - UI Components

    private let baseView: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()

    private let visualEffectView = UIVisualEffectView()

    private let emotionLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 22, weight: .bold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 12, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .right
        return label
    }()

    private let quoteLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.numberOfLines = 2
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

    private lazy var artworkImageViews: [UIImageView] = {
        (0..<4).map { _ in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = InnerCosmoLayout.moodEntryImageCornerRadius
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
            imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
            imageView.isHidden = true
            return imageView
        }
    }()

    private let emptyDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("inner_cosmo_mood_entry_empty_description", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var drawCTAButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("inner_cosmo_mood_entry_draw_cta", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 17, weight: .medium)
        button.setTitleColor(.themeButtonPrimaryText, for: .normal)
        button.backgroundColor = .themeButtonPrimaryBackground
        button.layer.cornerRadius = InnerCosmoLayout.moodEntryDrawCTACornerRadius
        button.isHidden = true
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
        for imageView in artworkImageViews {
            imageView.kf.cancelDownloadTask()
            imageView.image = nil
            imageView.isHidden = true
        }
        emptyDescriptionLabel.isHidden = true
        drawCTAButton.isHidden = true
        currentEntry = nil
    }

    // MARK: - Setup

    private func setupUI() {
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

        for imageView in artworkImageViews {
            artworkContainerView.addSubview(imageView)
        }
        artworkContainerView.addSubview(emptyDescriptionLabel)
        artworkContainerView.addSubview(drawCTAButton)
    }

    private func setupConstraints() {
        let padding = InnerCosmoLayout.moodEntryCardPadding

        emotionLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(padding)
            make.trailing.lessThanOrEqualTo(dateLabel.snp.leading).offset(-8)
        }

        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(InnerCosmoLayout.moodEntryDateTopOffset)
            make.trailing.equalToSuperview().offset(-padding)
        }

        quoteLabel.snp.makeConstraints { make in
            make.top.equalTo(emotionLabel.snp.bottom).offset(8)
            make.height.equalTo(InnerCosmoLayout.moodEntryQuoteLabelHeight)
            make.leading.trailing.equalToSuperview().inset(padding)
        }

        artworkContainerView.snp.makeConstraints { make in
            make.top.equalTo(quoteLabel.snp.bottom).offset(padding)
            make.leading.trailing.equalToSuperview().inset(padding)
            make.bottom.equalToSuperview().offset(-padding)
        }
    }

    // MARK: - Configuration

    func configure(with entry: MoodEntryCardCellViewModel) {
        currentEntry = entry

        emotionLabel.text = entry.emotion?.displayName
        dateLabel.text = entry.formattedDate
        quoteLabel.text = entry.journalTitle ?? entry.journalContent

        let urls = entry.artworkURLs

        if urls.isEmpty {
            layoutEmptyState()
        } else {
            emptyDescriptionLabel.isHidden = true
            drawCTAButton.isHidden = true
            artworkContainerView.backgroundColor = .clear

            for (index, urlString) in urls.enumerated() {
                let imageView = artworkImageViews[index]
                imageView.isHidden = false
                imageView.backgroundColor = .white
                if let url = URL(string: urlString) {
                    imageView.kf.setImage(with: url)
                }
            }

            layoutArtworkGrid(count: urls.count)
        }
    }

    // MARK: - Layout Methods

    private func layoutEmptyState() {
        // Hide all image views
        for imageView in artworkImageViews {
            imageView.isHidden = true
        }

        emptyDescriptionLabel.isHidden = false
        drawCTAButton.isHidden = (currentEntry?.checkinId == nil)

        emptyDescriptionLabel.snp.remakeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview().offset(-20)
        }

        drawCTAButton.snp.remakeConstraints { make in
            make.top.equalTo(emptyDescriptionLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
            make.height.equalTo(InnerCosmoLayout.moodEntryDrawCTAHeight)
        }
    }

    private func layoutArtworkGrid(count: Int) {
        let ratio = InnerCosmoLayout.moodEntryImageAspectRatio
        let largeGap = InnerCosmoLayout.moodEntryImageGridGap
        let smallGap = InnerCosmoLayout.moodEntryImageGridGap / 2

        switch count {
        case 1:
            // Single image centered with fixed aspect ratio
            artworkImageViews[0].snp.remakeConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(artworkImageViews[0].snp.height).multipliedBy(ratio)
                make.height.equalToSuperview()
            }

        case 2:
            // Two images side by side, 16pt horizontal gap, centered
            artworkImageViews[0].snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalTo(artworkImageViews[0].snp.height).multipliedBy(ratio)
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-largeGap / 2)
            }
            artworkImageViews[1].snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalTo(artworkImageViews[1].snp.height).multipliedBy(ratio)
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(largeGap / 2)
            }

        case 3:
            // Large image [0] on left, two small images [1][2] stacked on right
            // 16pt horizontal gap, 8pt vertical gap
            artworkImageViews[0].snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
                make.width.equalTo(artworkImageViews[0].snp.height).multipliedBy(ratio)
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-largeGap / 2)
            }
            artworkImageViews[1].snp.remakeConstraints { make in
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(largeGap / 2)
                make.top.equalToSuperview()
                make.bottom.equalTo(artworkContainerView.snp.centerY).offset(-smallGap / 2)
                make.width.equalTo(artworkImageViews[1].snp.height).multipliedBy(ratio)
            }
            artworkImageViews[2].snp.remakeConstraints { make in
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(largeGap / 2)
                make.top.equalTo(artworkContainerView.snp.centerY).offset(smallGap / 2)
                make.bottom.equalToSuperview()
                make.width.equalTo(artworkImageViews[2].snp.height).multipliedBy(ratio)
            }

        case 4:
            // 2x2 grid, 8pt spacing both ways, centered
            let halfSmall = smallGap / 2
            artworkImageViews[0].snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalTo(artworkContainerView.snp.centerY).offset(-halfSmall)
                make.width.equalTo(artworkImageViews[0].snp.height).multipliedBy(ratio)
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-halfSmall)
            }
            artworkImageViews[1].snp.remakeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalTo(artworkContainerView.snp.centerY).offset(-halfSmall)
                make.width.equalTo(artworkImageViews[1].snp.height).multipliedBy(ratio)
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfSmall)
            }
            artworkImageViews[2].snp.remakeConstraints { make in
                make.top.equalTo(artworkContainerView.snp.centerY).offset(halfSmall)
                make.bottom.equalToSuperview()
                make.width.equalTo(artworkImageViews[2].snp.height).multipliedBy(ratio)
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-halfSmall)
            }
            artworkImageViews[3].snp.remakeConstraints { make in
                make.top.equalTo(artworkContainerView.snp.centerY).offset(halfSmall)
                make.bottom.equalToSuperview()
                make.width.equalTo(artworkImageViews[3].snp.height).multipliedBy(ratio)
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfSmall)
            }

        default:
            break
        }
    }

    // MARK: - Actions

    @objc private func drawButtonTapped() {
        delegate?.moodEntryCardDidTapDraw(self, checkinId: currentEntry?.checkinId)
    }
}

// MARK: - Delegate Protocol

protocol MoodEntryCardCellDelegate: AnyObject {
    func moodEntryCardDidTapDraw(_ cell: MoodEntryCardCell, checkinId: String?)
}
