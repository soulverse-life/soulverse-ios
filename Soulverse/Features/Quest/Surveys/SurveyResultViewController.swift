//
//  SurveyResultViewController.swift
//  Soulverse
//
//  Generic post-submission result view. Shows the wellness-doc result message
//  for the user's stage / top-category. Accessible immediately after submit
//  and later via tap on a RecentResultCard (Plan 5).
//

import UIKit
import SnapKit

final class SurveyResultViewController: UIViewController {

    private enum Layout {
        static let outerInset: CGFloat = 24
        static let stackSpacing: CGFloat = 16
        static let doneHeight: CGFloat = 48
    }

    let result: SurveyComputedResult

    var onDone: (() -> Void)?

    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let doneButton = UIButton(type: .system)

    init(result: SurveyComputedResult) {
        self.result = result
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .themePrimary
        title = NSLocalizedString("quest_survey_result_title", comment: "")
        setupView()
        configure(for: result)
    }

    private func setupView() {
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textColor = .themeTextPrimary
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center

        messageLabel.font = .preferredFont(forTextStyle: .body)
        messageLabel.textColor = .themeTextSecondary
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center

        doneButton.setTitle(NSLocalizedString("quest_survey_result_done", comment: ""), for: .normal)
        doneButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        doneButton.setTitleColor(.themeButtonPrimaryText, for: .normal)
        doneButton.backgroundColor = .themeButtonPrimaryBackground
        doneButton.layer.cornerRadius = Layout.doneHeight / 2
        doneButton.addAction(UIAction { [weak self] _ in self?.onDone?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, doneButton])
        stack.axis = .vertical
        stack.spacing = Layout.stackSpacing
        stack.alignment = .fill
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalTo(view.safeAreaLayoutGuide)
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(Layout.outerInset)
        }
        doneButton.snp.makeConstraints { make in
            make.height.equalTo(Layout.doneHeight)
        }
    }

    private func configure(for result: SurveyComputedResult) {
        switch result {
        case let .importance(_, top, _):
            titleLabel.text = NSLocalizedString("quest_survey_result_importance_title", comment: "")
            messageLabel.text = String(
                format: NSLocalizedString("quest_importance_result_first_time_format", comment: ""),
                NSLocalizedString("quest_dimension_\(top.rawValue)", comment: "")
            )
        case let .eightDim(_, _, _, _, stageKey, messageKey):
            titleLabel.text = NSLocalizedString(stageKey, comment: "")
            messageLabel.text = NSLocalizedString(messageKey, comment: "")
        case let .stateOfChange(_, _, _, stageKey, stageMessageKey):
            titleLabel.text = NSLocalizedString(stageKey, comment: "")
            messageLabel.text = NSLocalizedString(stageMessageKey, comment: "")
        case let .satisfaction(_, top, lowest):
            titleLabel.text = NSLocalizedString("quest_survey_result_satisfaction_title", comment: "")
            messageLabel.text = String(
                format: NSLocalizedString("quest_satisfaction_result_first_time_format", comment: ""),
                NSLocalizedString("quest_dimension_\(top.rawValue)", comment: ""),
                NSLocalizedString("quest_dimension_\(lowest.rawValue)", comment: "")
            )
        }
    }
}
