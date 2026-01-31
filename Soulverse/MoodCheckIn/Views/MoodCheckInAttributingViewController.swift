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
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var progressBar: SoulverseProgressBar = {
        let bar = SoulverseProgressBar(totalSteps: 6)
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
        view.addSubview(closeButton)
        view.addSubview(progressBar)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(topicList)
        view.addSubview(continueButton)

        backButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(44)
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(44)
        }

        progressBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(backButton)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(progressBar.snp.bottom).offset(40)
            make.left.right.equalToSuperview().inset(40)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(40)
        }

        topicList.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(32)
            make.left.right.equalToSuperview().inset(40)
        }

        continueButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.greaterThanOrEqualTo(topicList.snp.bottom).offset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        delegate?.didTapBack(self)
    }

    @objc private func closeButtonTapped() {
        delegate?.didTapClose(self)
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
