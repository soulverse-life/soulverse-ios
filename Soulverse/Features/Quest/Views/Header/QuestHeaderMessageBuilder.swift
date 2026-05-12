//
//  QuestHeaderMessageBuilder.swift
//  Soulverse
//
//  Produces the markdown-formatted text rendered inside the QuestHeaderView's
//  EmoPet dialog. Encapsulates: stage → localization key mapping and
//  "N remaining" parameter substitution.
//
//  Intentionally scoped to text content only. Typography (font sizes,
//  weights, colors), the pet image, and dialog alignment are the view's
//  concerns — not the message builder's.
//

import Foundation

enum QuestHeaderMessageBuilder {

    /// Returns the localized, parameter-substituted message containing
    /// Markdown-style `**bold**` spans. Callers render via
    /// `EmoPetChatMarkdown.attributed(...)` with their chosen typography.
    static func text(for viewModel: QuestViewModel) -> String {
        let formatString = NSLocalizedString(
            markdownKey(for: viewModel.stage),
            comment: "Quest EmoPet stage message"
        )
        return render(formatString: formatString, distinctCheckInDays: viewModel.state.distinctCheckInDays)
    }

    // MARK: - Internals

    static func markdownKey(for stage: QuestStage) -> String {
        switch stage {
        case .stage1:    return "quest_progress_emo_stage_1_format"
        case .stage2:    return "quest_progress_emo_stage_2_format"
        case .stage3:    return "quest_progress_emo_stage_3_format"
        case .completed: return "quest_progress_emo_completed"
        }
    }

    static func render(formatString: String, distinctCheckInDays days: Int) -> String {
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
