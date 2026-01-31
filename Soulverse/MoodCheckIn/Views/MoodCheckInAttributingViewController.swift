//
//  MoodCheckInAttributingViewController.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import SnapKit
import UIKit

class MoodCheckInAttributingViewController: ViewController {

    // MARK: - Properties

    weak var delegate: MoodCheckInAttributingViewControllerDelegate?

    private var selectedTopic: Topic?

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
        bar.setProgress(currentStep: 4)
        return bar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_attributing_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .semibold)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("mood_checkin_attributing_subtitle", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var topicList: SoulverseTopicList = {
        let list = SoulverseTopicList(targetSelectedCount: 1)
        list.delegate = self
        return list
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(title: "Continue", style: .primary, delegate: self)
        button.isEnabled = false
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        view.addSubview(backButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(topicList)
        view.addSubview(continueButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(MoodCheckInLayout.navigationTopOffset)
            make.left.equalToSuperview().offset(MoodCheckInLayout.navigationLeftOffset)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
            make.width.equalTo(ViewComponentConstants.onboardingProgressViewWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(MoodCheckInLayout.titleTopOffset)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(MoodCheckInLayout.titleToSubtitleSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        topicList.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(MoodCheckInLayout.horizontalPadding)
            make.top.greaterThanOrEqualTo(topicList.snp.bottom).offset(MoodCheckInLayout.sectionSpacing)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-MoodCheckInLayout.bottomPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }
}

// MARK: - SoulverseTopicListDelegate

extension MoodCheckInAttributingViewController: SoulverseTopicListDelegate {
    func topicList(_ topicList: SoulverseTopicList, didUpdateSelection selectedTopics: [Topic]) {
        continueButton.isEnabled = !selectedTopics.isEmpty
        selectedTopic = selectedTopics.first
    }
}

// MARK: - SoulverseButtonDelegate

extension MoodCheckInAttributingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let topic = selectedTopic else { return }
        delegate?.didSelectTopic(self, topic: topic)
    }
}
