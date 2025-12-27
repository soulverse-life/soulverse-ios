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

    var iconName: String {
        switch self {
        case .physical: return "figure.run"
        case .emotional: return "heart.circle"
        case .social: return "person.2"
        case .intellectual: return "brain.head.profile"
        case .spiritual: return "sparkles"
        case .occupational: return "briefcase"
        case .environment: return "leaf"
        case .financial: return "dollarsign.circle"
        }
    }

    var cardColor: UIColor {
        switch self {
        case .physical: return UIColor(red: 255/255, green: 82/255, blue: 82/255, alpha: 1)
        case .emotional: return UIColor(red: 255/255, green: 183/255, blue: 77/255, alpha: 1)
        case .social: return UIColor(red: 103/255, green: 183/255, blue: 220/255, alpha: 1)
        case .intellectual: return UIColor(red: 118/255, green: 209/255, blue: 145/255, alpha: 1)
        case .spiritual: return UIColor(red: 138/255, green: 129/255, blue: 207/255, alpha: 1)
        case .occupational: return UIColor(red: 255/255, green: 235/255, blue: 59/255, alpha: 1)
        case .environment: return UIColor(red: 102/255, green: 204/255, blue: 204/255, alpha: 1)
        case .financial: return UIColor(red: 224/255, green: 151/255, blue: 255/255, alpha: 1)
        }
    }
}

protocol OnboardingTopicViewControllerDelegate: AnyObject {
    func onboardingTopicViewController(_ viewController: OnboardingTopicViewController, didSelectTopic topic: TopicOption)
}

class OnboardingTopicViewController: ViewController {

    // MARK: - UI Components

    private lazy var backButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "naviconBack")
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        button.accessibilityLabel = NSLocalizedString("navigation_back_button", comment: "Back button")
        return button
    }()

    private lazy var progressView: SoulverseProgressBar = {
        let progressBar = SoulverseProgressBar(totalSteps: 5)
        progressBar.setProgress(currentStep: 5)
        return progressBar
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "t.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themeTextPrimary
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_topics_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_topics_subtitle", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
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
    private var topicCards: [TopicCardView] = []

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

        view.addSubview(backButton)
        view.addSubview(progressView)
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(topicsGridView)
        view.addSubview(continueButton)

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.width.equalTo(ViewComponentConstants.onboardingProgressViewWidth)
            make.height.equalTo(4)
            make.centerX.equalToSuperview()
        }

        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(8)
            make.centerY.equalTo(progressView.snp.centerY)
            make.width.height.equalTo(ViewComponentConstants.navigationButtonSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(50)
            make.width.height.equalTo(40)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(60)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        topicsGridView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(60)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(20)
            make.height.equalTo(356) // 4 rows * (80 + 12) - 12
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupTopicButtons() {
        let topics = TopicOption.allCases
        let numberOfColumns = 2
        let cardHeight: CGFloat = 80
        let horizontalSpacing: CGFloat = 12
        let verticalSpacing: CGFloat = 12

        for (index, topic) in topics.enumerated() {
            let card = TopicCardView(topic: topic)

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(topicCardTapped(_:)))
            card.addGestureRecognizer(tapGesture)
            card.isUserInteractionEnabled = true
            card.tag = index

            let row = index / numberOfColumns
            let column = index % numberOfColumns

            topicsGridView.addSubview(card)

            card.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(CGFloat(row) * (cardHeight + verticalSpacing))
                make.height.equalTo(cardHeight)

                // Position cards in 2-column grid
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

            topicCards.append(card)
        }
    }

    private func selectTopicCard(_ card: TopicCardView, for topic: TopicOption) {
        topicCards.forEach { $0.isCardSelected = false }
        card.isCardSelected = true
        selectedTopic = topic
        continueButton.isEnabled = true
    }

    private func updateThemeColors() {
        titleLabel.textColor = .themeTextPrimary
        subtitleLabel.textColor = .themeTextSecondary
        iconImageView.tintColor = .themeTextPrimary
        // Topic cards use static colors, no theme updates needed
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func topicCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view as? TopicCardView else { return }
        let topic = TopicOption.allCases[card.tag]
        selectTopicCard(card, for: topic)
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingTopicViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard let selectedTopic = selectedTopic else { return }
        delegate?.onboardingTopicViewController(self, didSelectTopic: selectedTopic)
    }
}
