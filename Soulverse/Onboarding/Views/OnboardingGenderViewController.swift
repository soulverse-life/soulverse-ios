//
//  OnboardingGenderViewController.swift
//  Soulverse
//
//

import UIKit
import SnapKit

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
    func onboardingGenderViewController(_ viewController: OnboardingGenderViewController, didSelectGender gender: GenderOption)
}

class OnboardingGenderViewController: ViewController {

    // MARK: - UI Components

    private lazy var progressView: SoulverseProgressBar = {
        let progressBar = SoulverseProgressBar(totalSteps: 5)
        progressBar.setProgress(currentStep: 3)
        return progressBar
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
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_gender_instruction", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var genderTagsView: SoulverseTagsView = {
        let tagsView = SoulverseTagsView.create()
        tagsView.delegate = self
        return tagsView
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

    weak var delegate: OnboardingGenderViewControllerDelegate?
    private var genderOptions: [GenderOption] = GenderOption.allCases

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGenderOptions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(instructionLabel)
        view.addSubview(genderTagsView)
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

        instructionLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(40)
            make.top.equalTo(subtitleLabel.snp.bottom).offset(40)
        }

        genderTagsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(instructionLabel.snp.bottom).offset(20)
            make.height.equalTo(200) // Approximate height for multiple rows
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    private func setupGenderOptions() {
        // Convert gender options to item data
        let items = genderOptions.map { SoulverseTagsItemData(title: $0.localizedTitle, isSelected: false) }
        genderTagsView.setItems(items)
    }
}

// MARK: - SoulverseTagsViewDelegate

extension OnboardingGenderViewController: SoulverseTagsViewDelegate {
    func soulverseTagsView(_ view: SoulverseTagsView, didSelectItemAt index: Int) {
        continueButton.isEnabled = true
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingGenderViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        // This is the continue button
        guard let selectedIndex = genderTagsView.getSelectedIndex() else { return }
        let selectedGender = genderOptions[selectedIndex]
        delegate?.onboardingGenderViewController(self, didSelectGender: selectedGender)
    }
}
