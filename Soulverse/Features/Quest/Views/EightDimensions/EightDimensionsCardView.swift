//
//  EightDimensionsCardView.swift
//  Soulverse
//
//  Single glass card containing:
//    - title "Your 8 Dimensions"
//    - subtitle "Unlock more dimensions by checkins"
//    - octagonal radar with per-axis lock icons
//    - large center lock overlay + dimmed scrim when whole card is locked
//    - bottom row "{focus} current stage" with 5-stage indicator
//
//  Per the design (~/Desktop/quest_1.png), the radar is ALWAYS visible —
//  pre-day-7 lock is a translucent overlay on top, not a content swap.
//

import UIKit
import SnapKit

final class EightDimensionsCardView: UIView {

    private enum Layout {
        static let cornerRadius: CGFloat = 16
        static let outerInset: CGFloat = 16
        static let titleToSubtitle: CGFloat = 4
        static let subtitleToRadar: CGFloat = 12
        static let radarHeight: CGFloat = 240
        static let radarToBottom: CGFloat = 16
        static let bottomLabelHeight: CGFloat = 18
        static let stageIndicatorHeight: CGFloat = 44
        static let centerLockSize: CGFloat = 80
    }

    private let visualEffectView = UIVisualEffectView(effect: nil)
    private let cardContent = UIView()

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let radarOverlay = QuestRadarOverlayView()
    private let currentStageLabel = UILabel()
    private let stageDotsView = QuestEightDimStageIndicator()

    // Lock overlay (visible only when whole card is pre-day-7-locked).
    private let lockScrim = UIView()
    private let centerLockImageView = UIImageView()

    init() {
        super.init(frame: .zero)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupView() {
        layer.cornerRadius = Layout.cornerRadius
        clipsToBounds = true

        titleLabel.text = NSLocalizedString("quest_eight_dim_card_title", comment: "")
        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.textColor = .themeTextPrimary

        subtitleLabel.text = NSLocalizedString("quest_eight_dim_card_subtitle", comment: "")
        subtitleLabel.font = .preferredFont(forTextStyle: .footnote)
        subtitleLabel.textColor = .themeTextSecondary
        subtitleLabel.numberOfLines = 0

        currentStageLabel.font = .preferredFont(forTextStyle: .footnote)
        currentStageLabel.textColor = .themeTextSecondary

        centerLockImageView.image = UIImage(systemName: "lock.fill")
        centerLockImageView.tintColor = .themeTextPrimary
        centerLockImageView.contentMode = .scaleAspectFit

        lockScrim.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        lockScrim.isHidden = true

        let topStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        topStack.axis = .vertical
        topStack.spacing = Layout.titleToSubtitle

        let bottomStack = UIStackView(arrangedSubviews: [currentStageLabel, stageDotsView])
        bottomStack.axis = .vertical
        bottomStack.spacing = 8

        let mainStack = UIStackView(arrangedSubviews: [topStack, radarOverlay, bottomStack])
        mainStack.axis = .vertical
        mainStack.spacing = Layout.subtitleToRadar
        mainStack.setCustomSpacing(Layout.radarToBottom, after: radarOverlay)

        cardContent.addSubview(mainStack)
        cardContent.addSubview(lockScrim)
        cardContent.addSubview(centerLockImageView)

        mainStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.outerInset)
        }
        radarOverlay.snp.makeConstraints { make in
            make.height.equalTo(Layout.radarHeight)
        }
        currentStageLabel.snp.makeConstraints { make in
            make.height.equalTo(Layout.bottomLabelHeight)
        }
        stageDotsView.snp.makeConstraints { make in
            make.height.equalTo(Layout.stageIndicatorHeight)
        }
        lockScrim.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        centerLockImageView.snp.makeConstraints { make in
            make.center.equalTo(radarOverlay)
            make.size.equalTo(Layout.centerLockSize)
        }

        ViewComponentConstants.applyGlassCardEffect(
            to: self,
            visualEffectView: visualEffectView,
            contentView: cardContent,
            cornerRadius: Layout.cornerRadius
        )
        cardContent.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func configure(model: EightDimensionsRenderModel, lockedHint: String) {
        radarOverlay.configure(model: model)

        // Bottom row — show focus dim's stage (or a hint when locked).
        let focusDim = Topic.allCases.enumerated().first { (_, dim) in
            switch model.axes[Topic.allCases.firstIndex(of: dim)!] {
            case .currentFocusNoSoC, .currentFocusWithSoC: return true
            default: return false
            }
        }?.element
        if let focus = focusDim {
            currentStageLabel.text = String(
                format: NSLocalizedString("quest_eight_dim_current_stage_format", comment: ""),
                focus.localizedTitle
            )
            // Active stage from SoC indicator (mirror), fallback to 1.
            let activeStage = model.stateOfChangeIndicator?.activeStage ?? 1
            stageDotsView.configure(activeStage: activeStage)
            currentStageLabel.isHidden = false
            stageDotsView.isHidden = false
        } else {
            currentStageLabel.isHidden = true
            stageDotsView.isHidden = true
        }

        // Lock overlay — center lock + scrim when pre-day-7.
        lockScrim.isHidden = !model.isCardLocked
        centerLockImageView.isHidden = !model.isCardLocked
    }
}

// MARK: - Bottom 5-stage indicator (Stage 1 … Stage 5)

/// Small horizontal indicator drawn under the radar. Five dots with a
/// matching "Stage N" label per dot — independent of the State-of-Change
/// labels (those still live in `StateOfChangeIndicatorView`).
final class QuestEightDimStageIndicator: UIView {

    private enum Layout {
        static let dotSize: CGFloat = 8
        static let columnSpacing: CGFloat = 4
        static let labelTopSpacing: CGFloat = 4
    }

    private var columns: [UIStackView] = []
    private var dots: [UIView] = []
    private var labels: [UILabel] = []

    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        addSubview(row)
        row.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        for i in 0..<5 {
            let dot = UIView()
            dot.layer.cornerRadius = Layout.dotSize / 2
            dot.backgroundColor = .themeButtonDisabledBackground
            dot.snp.makeConstraints { make in
                make.size.equalTo(Layout.dotSize)
            }
            dots.append(dot)

            let label = UILabel()
            label.font = .preferredFont(forTextStyle: .caption2)
            label.textColor = .themeTextSecondary
            label.textAlignment = .center
            label.text = String(
                format: NSLocalizedString("quest_eight_dim_stage_label_format", comment: ""),
                i + 1
            )
            labels.append(label)

            let column = UIStackView(arrangedSubviews: [dot, label])
            column.axis = .vertical
            column.alignment = .center
            column.spacing = Layout.labelTopSpacing
            columns.append(column)
            row.addArrangedSubview(column)
        }
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(activeStage: Int) {
        for (i, dot) in dots.enumerated() {
            let stage = i + 1
            dot.backgroundColor = (stage == activeStage)
                ? .themeButtonPrimaryBackground
                : .themeButtonDisabledBackground
        }
    }
}
