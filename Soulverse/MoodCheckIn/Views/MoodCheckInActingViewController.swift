//
//  MoodCheckInActingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit
import SnapKit

enum MoodCheckInActingAction: String, CaseIterable {
    case draw
    case writeJournal

    var localizedTitle: String {
        switch self {
        case .draw:
            return NSLocalizedString("mood_checkin_acting_draw", comment: "")
        case .writeJournal:
            return NSLocalizedString("mood_checkin_acting_write_journal", comment: "")
        }
    }

    var isDefaultSelected: Bool {
        return self == .draw
    }

    var tagItemData: SoulverseTagsItemData {
        SoulverseTagsItemData(
            title: localizedTitle,
            isSelected: isDefaultSelected,
            tag: rawValue
        )
    }
}

class MoodCheckInActingViewController: ViewController {

    // MARK: - Layout

    private enum Layout {
        static let emotionRowHeight: CGFloat = 50
        static let emotionRowItemSpacing: CGFloat = 8
        static let actionViewSectionSpacing: CGFloat = 40
        static let actionViewSectionHorizontalPadding: CGFloat = 60
        static let sectionIntraSpacing: CGFloat = 16
        static let tagSpacing: CGFloat = 8
    }

    // MARK: - Properties

    weak var delegate: MoodCheckInActingViewControllerDelegate?

    private var moodCheckInData: MoodCheckInData?
    private var selectedAction: MoodCheckInActingAction? = MoodCheckInActingAction.allCases.first { $0.isDefaultSelected }
    private var actionTagViews: [MoodCheckInActingAction: ActionTagView] = [:]

    // MARK: - UI Elements

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        if #available(iOS 26.0, *) {
            button.setImage(UIImage(named: "naviconBack")?.withRenderingMode(.alwaysOriginal), for: .normal)
            button.imageView?.contentMode = .center
            button.imageView?.clipsToBounds = false
            button.clipsToBounds = false
        } else {
            button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            button.tintColor = .themeTextPrimary
        }
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var progressBar: SoulverseProgressBar = {
        let bar = SoulverseProgressBar(totalSteps: MoodCheckInLayout.totalSteps)
        bar.setProgress(currentStep: 5)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_acting_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_acting_subtitle", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var journeyLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_acting_journey", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private var emotionPlanetView: EmotionPlanetView?

    private lazy var plusLabel: UILabel = {
        let label = UILabel()
        label.text = "+"
        label.font = .projectFont(ofSize: 34, weight: .regular)
        label.textColor = .themeTextSecondary
        return label
    }()

    private lazy var emotionNameLabel: UILabel = {
        let label = UILabel()
        label.font = .projectFont(ofSize: 34, weight: .semibold)
        label.textColor = .themeTextPrimary
        return label
    }()

    private lazy var emotionRowContainer: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var moreActionsLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_acting_more_actions", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var actionTagsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Layout.tagSpacing
        stack.alignment = .center
        return stack
    }()

    private lazy var completeButton: SoulverseButton = {
        let button = SoulverseButton(title: NSLocalizedString("mood_checkin_acting_complete", comment: ""), style: .primary, delegate: self)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadMoodCheckInData()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(journeyLabel)
        view.addSubview(emotionRowContainer)
        view.addSubview(moreActionsLabel)
        view.addSubview(actionTagsStackView)
        view.addSubview(completeButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(MoodCheckInLayout.navigationTopOffset)
            make.left.equalToSuperview().offset(MoodCheckInLayout.navigationLeftOffset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.width.equalTo(ViewComponentConstants.progressViewWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(MoodCheckInLayout.titleTopOffset)
            make.left.right.equalToSuperview().inset(Layout.actionViewSectionHorizontalPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(MoodCheckInLayout.titleToSubtitleSpacing)
            make.left.right.equalToSuperview().inset(Layout.actionViewSectionHorizontalPadding)
        }

        journeyLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.actionViewSectionSpacing)
            make.centerX.equalToSuperview()
        }

        emotionRowContainer.snp.makeConstraints { make in
            make.top.equalTo(journeyLabel.snp.bottom).offset(Layout.sectionIntraSpacing)
            make.centerX.equalToSuperview()
            make.height.equalTo(Layout.emotionRowHeight)
        }

        moreActionsLabel.snp.makeConstraints { make in
            make.top.equalTo(emotionRowContainer.snp.bottom).offset(Layout.actionViewSectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        actionTagsStackView.snp.makeConstraints { make in
            make.top.equalTo(moreActionsLabel.snp.bottom).offset(Layout.sectionIntraSpacing)
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview().offset(Layout.actionViewSectionHorizontalPadding)
            make.right.lessThanOrEqualToSuperview().offset(-Layout.actionViewSectionHorizontalPadding)
        }

        completeButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(MoodCheckInLayout.bottomPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        setupActionTags()
    }

    private func setupActionTags() {
        for action in MoodCheckInActingAction.allCases {
            let tagView = ActionTagView(title: action.localizedTitle)
            tagView.setSelected(action.isDefaultSelected)

            let tap = UITapGestureRecognizer(target: self, action: #selector(actionTagTapped(_:)))
            tagView.addGestureRecognizer(tap)

            actionTagsStackView.addArrangedSubview(tagView)
            actionTagViews[action] = tagView
        }
    }

    private func loadMoodCheckInData() {
        guard let data = delegate?.getCurrentData(self) else { return }
        self.moodCheckInData = data

        if let emotion = data.recordedEmotion, let colorHex = data.colorHexString {
            let planetData = EmotionPlanetData(
                emotion: "",
                colorHex: colorHex,
                sizeMultiplier: 1.3
            )
            let planetView = EmotionPlanetView(data: planetData)
            self.emotionPlanetView = planetView

            emotionRowContainer.addSubview(planetView)
            emotionRowContainer.addSubview(plusLabel)
            emotionRowContainer.addSubview(emotionNameLabel)

            let planetSize = planetView.calculateSize()

            planetView.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(planetSize.width)
                make.height.equalTo(planetSize.height)
            }

            plusLabel.snp.makeConstraints { make in
                make.left.equalTo(planetView.snp.right).offset(Layout.emotionRowItemSpacing)
                make.centerY.equalToSuperview()
            }

            emotionNameLabel.text = emotion.displayName
            emotionNameLabel.snp.makeConstraints { make in
                make.left.equalTo(plusLabel.snp.right).offset(Layout.emotionRowItemSpacing)
                make.centerY.equalToSuperview()
                make.right.lessThanOrEqualToSuperview()
            }
        }

    }

    // MARK: - Selection

    private func selectAction(_ action: MoodCheckInActingAction) {
        // Toggle if tapping the already-selected action; otherwise switch
        selectedAction = (selectedAction == action) ? nil : action

        for (actionCase, tagView) in actionTagViews {
            tagView.setSelected(actionCase == selectedAction)
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

    @objc private func actionTagTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view as? ActionTagView,
              let action = actionTagViews.first(where: { $0.value === tappedView })?.key else { return }
        selectAction(action)
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInActingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        delegate?.didTapCompleteCheckIn(self, selectedAction: selectedAction)
    }
}
