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

    private lazy var artworkImageViews: [UIImageView] = {
        (0..<4).map { _ in
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = InnerCosmoLayout.moodEntryImageCornerRadius
            imageView.isHidden = true
            return imageView
        }
    }()

    private let emptyDescriptionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("inner_cosmo_mood_entry_empty_description", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private lazy var drawCTAButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(NSLocalizedString("inner_cosmo_mood_entry_draw_cta", comment: ""), for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 14, weight: .semibold)
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
    }

    // MARK: - Configuration

    func configure(with entry: MoodEntry) {
        currentEntry = entry

        emotionLabel.text = entry.emotion.displayName
        dateLabel.text = entry.formattedDate
        quoteLabel.text = entry.journal

        let urls = Array(entry.artworkURLs.prefix(4))

        if urls.isEmpty {
            layoutEmptyState(color: entry.color)
        } else {
            emptyDescriptionLabel.isHidden = true
            drawCTAButton.isHidden = true
            artworkContainerView.backgroundColor = .clear

            for (index, urlString) in urls.enumerated() {
                let imageView = artworkImageViews[index]
                imageView.isHidden = false
                if let url = URL(string: urlString) {
                    imageView.kf.setImage(with: url)
                }
            }

            layoutArtworkGrid(count: urls.count)
        }
    }

    // MARK: - Layout Methods

    private func layoutEmptyState(color: UIColor) {
        // Hide all image views
        for imageView in artworkImageViews {
            imageView.isHidden = true
        }

        artworkContainerView.backgroundColor = color.withAlphaComponent(0.3)

        emptyDescriptionLabel.isHidden = false
        drawCTAButton.isHidden = false

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
        let gap = InnerCosmoLayout.moodEntryImageGridGap
        let halfGap = gap / 2

        switch count {
        case 1:
            artworkImageViews[0].snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }

        case 2:
            artworkImageViews[0].snp.remakeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-halfGap)
            }
            artworkImageViews[1].snp.remakeConstraints { make in
                make.top.bottom.trailing.equalToSuperview()
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfGap)
            }

        case 3:
            artworkImageViews[0].snp.remakeConstraints { make in
                make.top.bottom.leading.equalToSuperview()
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-halfGap)
            }
            artworkImageViews[1].snp.remakeConstraints { make in
                make.top.trailing.equalToSuperview()
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfGap)
                make.bottom.equalTo(artworkContainerView.snp.centerY).offset(-halfGap)
            }
            artworkImageViews[2].snp.remakeConstraints { make in
                make.bottom.trailing.equalToSuperview()
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfGap)
                make.top.equalTo(artworkContainerView.snp.centerY).offset(halfGap)
            }

        case 4:
            artworkImageViews[0].snp.remakeConstraints { make in
                make.top.leading.equalToSuperview()
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-halfGap)
                make.bottom.equalTo(artworkContainerView.snp.centerY).offset(-halfGap)
            }
            artworkImageViews[1].snp.remakeConstraints { make in
                make.top.trailing.equalToSuperview()
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfGap)
                make.bottom.equalTo(artworkContainerView.snp.centerY).offset(-halfGap)
            }
            artworkImageViews[2].snp.remakeConstraints { make in
                make.bottom.leading.equalToSuperview()
                make.trailing.equalTo(artworkContainerView.snp.centerX).offset(-halfGap)
                make.top.equalTo(artworkContainerView.snp.centerY).offset(halfGap)
            }
            artworkImageViews[3].snp.remakeConstraints { make in
                make.bottom.trailing.equalToSuperview()
                make.leading.equalTo(artworkContainerView.snp.centerX).offset(halfGap)
                make.top.equalTo(artworkContainerView.snp.centerY).offset(halfGap)
            }

        default:
            break
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
