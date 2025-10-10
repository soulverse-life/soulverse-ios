//
//  OnboardingTopicViewController.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit
import SnapKit

enum TopicOption: String, CaseIterable {
    case physical = "Physical"
    case emotional = "Emotional"
    case social = "Social"
    case intellectual = "Intellectual"
    case spiritual = "Spiritual"
    case occupational = "Occupational"
    case environment = "Environment"
    case financial = "Financial"
}

protocol OnboardingTopicViewControllerDelegate: AnyObject {
    func didCompleteOnboarding(selectedTopics: [TopicOption])
}

class OnboardingTopicViewController: UIViewController {

    // MARK: - UI Components

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .black
        progress.trackTintColor = .lightGray
        progress.progress = 1.0 // Step 6 of 6 (completed)
        return progress
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Selecting Topics"
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "These guide your journey, shaping\nreflections, insights, and support\ntailored to your soulverse."
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 3
        return label
    }()

    private lazy var topicsGridView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.black.cgColor
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingTopicViewControllerDelegate?
    private var selectedTopics: Set<TopicOption> = []
    private var topicButtons: [UIButton] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTopicButtons()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(topicsGridView)
        view.addSubview(continueButton)

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(60)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        topicsGridView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
            make.height.equalTo(280) // Enough space for 4 rows
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    private func setupTopicButtons() {
        let topics = TopicOption.allCases
        let numberOfColumns = 2
        let buttonHeight: CGFloat = 60
        let horizontalSpacing: CGFloat = 12
        let verticalSpacing: CGFloat = 12

        for (index, topic) in topics.enumerated() {
            let button = createTopicButton(for: topic)

            let row = index / numberOfColumns
            let column = index % numberOfColumns

            topicsGridView.addSubview(button)

            button.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(CGFloat(column) * (topicsGridView.frame.width / 2 + horizontalSpacing / 2))
                make.top.equalToSuperview().offset(CGFloat(row) * (buttonHeight + verticalSpacing))
                make.height.equalTo(buttonHeight)
            }

            // Set width constraints based on position
            if numberOfColumns == 2 {
                button.snp.makeConstraints { make in
                    if column == 0 {
                        make.right.equalTo(topicsGridView.snp.centerX).offset(-horizontalSpacing / 2)
                    } else {
                        make.left.equalTo(topicsGridView.snp.centerX).offset(horizontalSpacing / 2)
                        make.right.equalToSuperview()
                    }
                }
            }

            topicButtons.append(button)
        }

        // Pre-select "Emotional" as shown in the design
        if let emotionalButton = topicButtons.first(where: { btn in
            let topic = TopicOption.allCases[btn.tag]
            return topic == .emotional
        }) {
            selectTopicButton(emotionalButton, for: .emotional)
        }
    }

    private func createTopicButton(for topic: TopicOption) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(topic.rawValue, for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.setTitleColor(.white, for: .selected)
        button.titleLabel?.font = .projectFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 30

        button.addTarget(self, action: #selector(topicButtonTapped(_:)), for: .touchUpInside)

        // Store the topic option as a tag
        button.tag = TopicOption.allCases.firstIndex(of: topic) ?? 0

        return button
    }

    private func selectTopicButton(_ button: UIButton, for topic: TopicOption) {
        if selectedTopics.contains(topic) {
            // Deselect
            selectedTopics.remove(topic)
            button.isSelected = false
            button.backgroundColor = .white
            button.setTitleColor(.black, for: .normal)
            button.layer.borderColor = UIColor.lightGray.cgColor
        } else {
            // Select
            selectedTopics.insert(topic)
            button.isSelected = true
            button.backgroundColor = .black
            button.setTitleColor(.white, for: .normal)
            button.layer.borderColor = UIColor.black.cgColor
        }

        // Enable/disable continue button based on selection
        continueButton.isEnabled = !selectedTopics.isEmpty
        continueButton.alpha = selectedTopics.isEmpty ? 0.5 : 1.0
    }

    // MARK: - Actions

    @objc private func topicButtonTapped(_ sender: UIButton) {
        let topic = TopicOption.allCases[sender.tag]
        selectTopicButton(sender, for: topic)
    }

    @objc private func continueTapped() {
        let selectedTopicsArray = Array(selectedTopics)
        delegate?.didCompleteOnboarding(selectedTopics: selectedTopicsArray)
    }
}