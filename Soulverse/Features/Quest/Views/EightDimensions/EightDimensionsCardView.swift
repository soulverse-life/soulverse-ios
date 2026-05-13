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
        static let bottomStackSpacing: CGFloat = 8
        static let titleFontSize: CGFloat = 20
        static let subtitleFontSize: CGFloat = 16
        static let currentStageFontSize: CGFloat = 16
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
        titleLabel.font = .projectFont(ofSize: Layout.titleFontSize, weight: .bold)
        titleLabel.textColor = .themeTextPrimary

        subtitleLabel.text = NSLocalizedString("quest_eight_dim_card_subtitle", comment: "")
        subtitleLabel.font = .projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        subtitleLabel.textColor = .themeTextSecondary

        currentStageLabel.font = .projectFont(ofSize: Layout.currentStageFontSize, weight: .regular)
        currentStageLabel.textColor = .themeTextSecondary

        centerLockImageView.image = UIImage(systemName: "lock.fill")
        centerLockImageView.tintColor = .themeTextPrimary
        centerLockImageView.contentMode = .scaleAspectFit

        lockScrim.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        lockScrim.isHidden = true

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = Layout.titleToSubtitle

        let currentStageStack = UIStackView(arrangedSubviews: [currentStageLabel, stageDotsView])
        currentStageStack.axis = .vertical
        currentStageStack.spacing = Layout.bottomStackSpacing

        let mainStack = UIStackView(arrangedSubviews: [headerStack, radarOverlay, currentStageStack])
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
            // Active stage from SoC indicator (mirror). Fall back to 0
            // (no stages reached → all dots at 30%) when SoC hasn't been
            // submitted yet, matching the radar's currentFocusNoSoC dot row.
            let activeStage = model.stateOfChangeIndicator?.activeStage ?? 0
            stageDotsView.configure(activeStage: activeStage, color: focus.mainColor)
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
        static let dotSize: CGFloat = 12
        static let columnSpacing: CGFloat = 4
        static let labelTopSpacing: CGFloat = 4
        static let labelFontSize: CGFloat = 11
        /// Alpha applied to the focus dim's color for stages that have NOT
        /// been reached yet. Reached stages render at full opacity.
        static let unreachedDotAlpha: CGFloat = 0.30
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
            label.font = .projectFont(ofSize: Layout.labelFontSize, weight: .regular)
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

    /// Configure the indicator. The `color` parameter is the focus
    /// dimension's `Topic.mainColor`. Stages 1…activeStage render at full
    /// opacity; later stages at `Layout.unreachedDotAlpha`.
    func configure(activeStage: Int, color: UIColor) {
        for (i, dot) in dots.enumerated() {
            let stage = i + 1
            let isReached = stage <= activeStage
            dot.backgroundColor = isReached
                ? color
                : color.withAlphaComponent(Layout.unreachedDotAlpha)
        }
    }
}
