//
//  QuestHeaderView.swift
//  Soulverse
//
//  Quest tab page header. Lives above the progress section (the 7-dot rail)
//  and renders:
//    1. The page tagline ("Your personal growth mission hub")
//    2. A reusable EmoPetChatView dialog whose message reflects the current
//       Quest stage (and, in future, other subsystems — habits, surveys, etc.)
//
//  Separated from QuestProgressSectionView because the tagline + dialog are
//  page-level identity, not part of the day-progress rail. The dialog's
//  config assembly lives in QuestHeaderMessageBuilder.
//

import UIKit
import SnapKit

final class QuestHeaderView: UIView {

    private enum Layout {
        static let containerInset: CGFloat = 64
        static let subtitleToDialogSpacing: CGFloat = 32
        static let subtitleFontSize: CGFloat = 17
        static let dialogDefaultHeight: CGFloat = 54
        static let dialogFontSize: CGFloat = 14
        static let petImageName: String = "basic_first_level"
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

    private let petDialog: EmoPetChatView = EmoPetChatView(frame: .zero)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupView() {
        let stack = UIStackView(arrangedSubviews: [subtitleLabel, petDialog])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Layout.subtitleToDialogSpacing
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(Layout.containerInset)
            make.verticalEdges.equalToSuperview()
        }
        petDialog.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(Layout.dialogDefaultHeight)
        }
    }

    func configure(viewModel: QuestViewModel) {
        let text = QuestHeaderMessageBuilder.text(for: viewModel)
        let attributed = EmoPetChatMarkdown.attributed(
            from: text,
            baseFont: .projectFont(ofSize: Layout.dialogFontSize, weight: .regular),
            boldFont: .projectFont(ofSize: Layout.dialogFontSize, weight: .bold),
            color: .themeTextPrimary
        )
        petDialog.update(config: EmoPetChatConfig(
            image: UIImage(named: Layout.petImageName),
            message: attributed.string,
            attributedMessage: attributed,
            alignment: .imageTrailing
        ))
    }
}
