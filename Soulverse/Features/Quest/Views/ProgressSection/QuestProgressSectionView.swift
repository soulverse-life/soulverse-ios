//
//  QuestProgressSectionView.swift
//  Soulverse
//
//  Quest tab header. Composes:
//    1. The "Your personal growth mission hub" subtitle
//    2. An EmoPetChatView dialog whose copy is driven by the current stage
//    3. A 7-dot row representing the current stage's days (not all 21)
//
//  The daily-check-in CTA was removed in favour of the global Mood Check-In
//  entry point — Quest is a read-only mission hub.
//

import UIKit
import SnapKit

final class QuestProgressSectionView: UIView {

    private enum Layout {
        static let containerInset: CGFloat = ViewComponentConstants.horizontalPadding
        static let subtitleToDialogSpacing: CGFloat = 16
        static let dialogToDotsSpacing: CGFloat = 18
        static let subtitleFontSize: CGFloat = 16
        static let dialogHeight: CGFloat = 54
    }

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = UIFont.projectFont(ofSize: Layout.subtitleFontSize, weight: .regular)
        l.textColor = .themeTextPrimary
        l.textAlignment = .center
        l.numberOfLines = 0
        l.text = NSLocalizedString("quest_progress_subtitle", comment: "Quest tab subtitle")
        return l
    }()

    private let petDialog: EmoPetChatView = {
        let v = EmoPetChatView(frame: .zero)
        return v
    }()

    private let dotsView = QuestProgressDotsView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// Kept for back-compat with QuestViewController's existing API. The CTA
    /// has been retired; this is a no-op and may be removed in a follow-up.
    var onCTAtap: (() -> Void)?

    private func setupView() {
        let stack = UIStackView(arrangedSubviews: [subtitleLabel, petDialog, dotsView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Layout.subtitleToDialogSpacing
        stack.setCustomSpacing(Layout.dialogToDotsSpacing, after: petDialog)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.containerInset)
        }
        petDialog.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Layout.dialogHeight)
        }
        dotsView.snp.makeConstraints { make in
            // Dots align centre but stack is .fill — wrap with a centring
            // container row to avoid stretching.
        }
    }

    func configure(viewModel: QuestViewModel) {
        isHidden = !viewModel.progressSectionVisible

        // Build the stage-aware EmoPet message.
        let markdownKey = QuestProgressMessageBuilder.markdownKey(for: viewModel.stage)
        let formatString = NSLocalizedString(markdownKey, comment: "Quest EmoPet stage message")
        let rendered = QuestProgressMessageBuilder.render(
            formatString: formatString,
            distinctCheckInDays: viewModel.state.distinctCheckInDays
        )
        let attributed = EmoPetChatMarkdown.attributed(
            from: rendered,
            baseFont: .projectFont(ofSize: 14, weight: .regular),
            boldFont: .projectFont(ofSize: 14, weight: .bold),
            color: .themeTextPrimary
        )
        petDialog.update(config: EmoPetChatConfig(
            image: UIImage(named: "EMOPet/basic_first_level"),
            message: rendered,
            attributedMessage: attributed,
            alignment: .imageTrailing
        ))

        dotsView.configure(currentDot: viewModel.currentDot, stage: viewModel.stage)
    }
}

/// Maps QuestStage to the localization key and substitutes the dynamic
/// "N times remaining" / "Day N" parameter into the format string.
///
/// We do this at the call site rather than inside `EmoPetChatView` so the
/// dialog stays a pure presentation component (per spec §10.3 — reusable
/// page component, no Quest-specific knowledge).
enum QuestProgressMessageBuilder {

    static func markdownKey(for stage: QuestStage) -> String {
        switch stage {
        case .stage1:    return "quest_progress_emo_stage_1_format"
        case .stage2:    return "quest_progress_emo_stage_2_format"
        case .stage3:    return "quest_progress_emo_stage_3_format"
        case .completed: return "quest_progress_emo_completed"
        }
    }

    static func render(formatString: String, distinctCheckInDays days: Int) -> String {
        // Stage 1: needs 7 - days more check-ins to unlock Phase 1
        // Stage 2: needs 14 - days more check-ins to unlock Phase 2
        // Stage 3: needs 21 - days more check-ins to complete the quest
        let remaining: Int
        switch QuestStage.from(distinctCheckInDays: days) {
        case .stage1:    remaining = max(0, 7 - days)
        case .stage2:    remaining = max(0, 14 - days)
        case .stage3:    remaining = max(0, 21 - days)
        case .completed: remaining = 0
        }
        return String(format: formatString, remaining)
    }
}
