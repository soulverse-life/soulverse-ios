//
//  OnboardingTopicViewController.swift
//  Soulverse
//
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

    var localizedTitle: String {
        switch self {
        case .physical:
            return NSLocalizedString("onboarding_topics_physical", comment: "")
        case .emotional:
            return NSLocalizedString("onboarding_topics_emotional", comment: "")
        case .social:
            return NSLocalizedString("onboarding_topics_social", comment: "")
        case .intellectual:
            return NSLocalizedString("onboarding_topics_intellectual", comment: "")
        case .spiritual:
            return NSLocalizedString("onboarding_topics_spiritual", comment: "")
        case .occupational:
            return NSLocalizedString("onboarding_topics_occupational", comment: "")
        case .environment:
            return NSLocalizedString("onboarding_topics_environment", comment: "")
        case .financial:
            return NSLocalizedString("onboarding_topics_financial", comment: "")
        }
    }
}

protocol OnboardingTopicViewControllerDelegate: AnyObject {
    func onboardingTopicViewController(_ viewController: OnboardingTopicViewController, didSelectTopic topic: TopicOption)
}

class OnboardingTopicViewController: ViewController {

    // MARK: - UI Components

    private lazy var progressView: SoulverseProgressBar = {
        let progressBar = SoulverseProgressBar(totalSteps: 5)
        progressBar.setProgress(currentStep: 5)
        return progressBar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_topics_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_topics_subtitle", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 3
        return label
    }()

    private lazy var topicsGridView: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_continue_button", comment: ""),
            style: .primary,
            delegate: self
        )
        button.isEnabled = false
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingTopicViewControllerDelegate?
    private var selectedTopic: TopicOption?
    private var topicButtons: [UIButton] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTopicButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateThemeColors()
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
            make.centerX.equalToSuperview()
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
                make.top.equalToSuperview().offset(CGFloat(row) * (buttonHeight + verticalSpacing))
                make.height.equalTo(buttonHeight)

                // Position buttons in 2-column grid
                if column == 0 {
                    // Left column
                    make.left.equalToSuperview()
                    make.right.equalTo(topicsGridView.snp.centerX).offset(-horizontalSpacing / 2)
                } else {
                    // Right column
                    make.left.equalTo(topicsGridView.snp.centerX).offset(horizontalSpacing / 2)
                    make.right.equalToSuperview()
                }
            }

            topicButtons.append(button)
        }
    }

    private func createTopicButton(for topic: TopicOption) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(topic.localizedTitle, for: .normal)
        button.setTitle(topic.localizedTitle, for: .selected)
        button.titleLabel?.font = .projectFont(ofSize: 16, weight: .medium)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 30

        button.addTarget(self, action: #selector(topicButtonTapped(_:)), for: .touchUpInside)

        // Store the topic option as a tag
        button.tag = TopicOption.allCases.firstIndex(of: topic) ?? 0

        return button
    }

    private func applyButtonTheme(_ button: UIButton, isSelected: Bool) {
        if isSelected {
            button.backgroundColor = .themeButtonPrimaryBackground
            button.setTitleColor(.themeButtonPrimaryText, for: .normal)
            button.setTitleColor(.themeButtonPrimaryText, for: .selected)
            button.layer.borderColor = UIColor.themeButtonPrimaryBackground.cgColor
        } else {
            button.backgroundColor = .themeButtonDisabledBackground
            button.setTitleColor(.themeButtonDisabledText, for: .normal)
            button.setTitleColor(.themeButtonPrimaryText, for: .selected)
            button.layer.borderColor = UIColor.themeButtonDisabledBackground.cgColor
        }
    }

    private func selectTopicButton(_ button: UIButton, for topic: TopicOption) {
        // Deselect all buttons first
        topicButtons.forEach { btn in
            btn.isSelected = false
            applyButtonTheme(btn, isSelected: false)
        }

        // Select the tapped button
        button.isSelected = true
        applyButtonTheme(button, isSelected: true)

        selectedTopic = topic

        // Enable continue button
        continueButton.isEnabled = true
    }

    private func updateThemeColors() {
        // Update title and subtitle colors
        titleLabel.textColor = .themeTextPrimary
        subtitleLabel.textColor = .themeTextSecondary

        // Update all topic buttons
        topicButtons.forEach { button in
            applyButtonTheme(button, isSelected: button.isSelected)
        }
    }

    // MARK: - Actions

    @objc private func topicButtonTapped(_ sender: UIButton) {
        let topic = TopicOption.allCases[sender.tag]
        selectTopicButton(sender, for: topic)
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingTopicViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let selectedTopic = selectedTopic else { return }
        delegate?.onboardingTopicViewController(self, didSelectTopic: selectedTopic)
    }
}
