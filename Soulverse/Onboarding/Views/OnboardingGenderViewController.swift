//
//  OnboardingGenderViewController.swift
//  Soulverse
//
//

import SnapKit
import UIKit

enum GenderOption: String, CaseIterable {
    case man = "Man"
    case woman = "Woman"
    case nonBinary = "Non-binary"
    case transgender = "Transgender"
    case preferNotToSay = "Prefer not to say"

    var localizedTitle: String {
        switch self {
        case .man:
            return NSLocalizedString("onboarding_gender_man", comment: "")
        case .woman:
            return NSLocalizedString("onboarding_gender_woman", comment: "")
        case .nonBinary:
            return NSLocalizedString("onboarding_gender_nonbinary", comment: "")
        case .transgender:
            return NSLocalizedString("onboarding_gender_transgender", comment: "")
        case .preferNotToSay:
            return NSLocalizedString("onboarding_gender_prefer_not_to_say", comment: "")
        }
    }
}

protocol OnboardingGenderViewControllerDelegate: AnyObject {
    func onboardingGenderViewController(
        _ viewController: OnboardingGenderViewController, didSelectGender gender: GenderOption)
}

class OnboardingGenderViewController: ViewController {

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
        progressBar.setProgress(currentStep: 3)
        return progressBar
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themeTextPrimary
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_gender_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_gender_subtitle", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var genderTagsView: SoulverseTagsView = {
        let tagsView = SoulverseTagsView.create()
        tagsView.selectionMode = .single
        tagsView.delegate = self
        return tagsView
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_continue_button_title", comment: ""),
            style: .primary,
            delegate: self
        )
        button.isEnabled = false
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingGenderViewControllerDelegate?
    private var genderOptions: [GenderOption] = GenderOption.allCases
    private var selectedGenderIndex: Int?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGenderOptions()
    }

    // MARK: - Setup

    private func setupUI() {

        view.addSubview(backButton)
        view.addSubview(progressView)
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(genderTagsView)
        view.addSubview(continueButton)

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.width.equalTo(ViewComponentConstants.progressViewWidth)
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
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        genderTagsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.height.equalTo(200)  // Approximate height for multiple rows
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupGenderOptions() {
        // Convert gender options to item data
        let items = genderOptions.map {
            SoulverseTagsItemData(title: $0.localizedTitle, isSelected: false)
        }
        genderTagsView.setItems(items)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - SoulverseTagsViewDelegate

// MARK: - SoulverseTagsViewDelegate

extension OnboardingGenderViewController: SoulverseTagsViewDelegate {
    func soulverseTagsView(
        _ view: SoulverseTagsView, didUpdateSelectedItems items: [SoulverseTagsItemData]
    ) {
        guard let selectedItem = items.first else {
            selectedGenderIndex = nil
            continueButton.isEnabled = false
            return
        }

        // Find the index of the selected item
        if let index = genderOptions.firstIndex(where: { $0.localizedTitle == selectedItem.title })
        {
            selectedGenderIndex = index
            continueButton.isEnabled = true
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingGenderViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        // This is the continue button
        guard let selectedIndex = selectedGenderIndex else { return }
        let selectedGender = genderOptions[selectedIndex]
        delegate?.onboardingGenderViewController(self, didSelectGender: selectedGender)
    }
}
