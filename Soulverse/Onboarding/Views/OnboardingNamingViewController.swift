//
//  OnboardingNamingViewController.swift
//  Soulverse
//
//

import UIKit
import SnapKit

protocol OnboardingNamingViewControllerDelegate: AnyObject {
    func onboardingNamingViewController(_ viewController: OnboardingNamingViewController, didCompletePlanetName planetName: String, emoPetName: String)
}

class OnboardingNamingViewController: ViewController {

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
        progressBar.setProgress(currentStep: 4)
        return progressBar
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "smallcircle.filled.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themeTextPrimary
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_naming_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_naming_subtitle", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var planetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "planet_small")
        imageView.contentMode = .center
        imageView.clipsToBounds = false
        imageView.frame.size = CGSize(width: 80, height: 80)
        return imageView
    }()

    private lazy var planetNameLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_naming_planet_label", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var planetNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("onboarding_naming_planet_placeholder", comment: "")
        textField.font = .projectFont(ofSize: 16, weight: .regular)
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 20
        textField.backgroundColor = .white
        textField.textColor = ThemeManager.shared.currentTheme.neutralDark
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // Add left padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        return textField
    }()

    private lazy var emoPetImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "basic_first_level")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var emoPetNameLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_naming_emopet_label", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var emoPetNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("onboarding_naming_emopet_placeholder", comment: "")
        textField.font = .projectFont(ofSize: 16, weight: .regular)
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 20
        textField.backgroundColor = .white
        textField.delegate = self
        textField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)

        // Add left padding
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: textField.frame.height))
        textField.leftView = paddingView
        textField.leftViewMode = .always

        return textField
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

    weak var delegate: OnboardingNamingViewControllerDelegate?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupKeyboardDismissal()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(backButton)
        view.addSubview(progressView)
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(planetImageView)
        view.addSubview(planetNameLabel)
        view.addSubview(planetNameTextField)
        view.addSubview(emoPetImageView)
        view.addSubview(emoPetNameLabel)
        view.addSubview(emoPetNameTextField)
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
            make.left.right.equalToSuperview().inset(48)
            make.top.equalTo(iconImageView.snp.bottom).offset(8)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(48)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        planetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            make.size.equalTo(80)
        }

        planetNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.top.equalTo(planetImageView.snp.bottom).offset(8)
        }

        planetNameTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.top.equalTo(planetNameLabel.snp.bottom).offset(8)
            make.height.equalTo(48)
        }

        emoPetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(planetNameTextField.snp.bottom).offset(20)
            make.size.equalTo(80)
        }

        emoPetNameLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.top.equalTo(emoPetImageView.snp.bottom).offset(8)
        }

        emoPetNameTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.top.equalTo(emoPetNameLabel.snp.bottom).offset(8)
            make.height.equalTo(48)
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    @objc private func textFieldDidChange() {
        validateInput()
    }

    // MARK: - Validation

    private func validateInput() {
        let isPlanetNameValid = !(planetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        let isEmoPetNameValid = !(emoPetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)

        continueButton.isEnabled = isPlanetNameValid && isEmoPetNameValid
    }
}

// MARK: - UITextFieldDelegate

extension OnboardingNamingViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == planetNameTextField {
            emoPetNameTextField.becomeFirstResponder()
        } else if textField == emoPetNameTextField {
            textField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingNamingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        // Double-check validation before proceeding
        guard let planetName = planetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !planetName.isEmpty,
              let emoPetName = emoPetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !emoPetName.isEmpty else {
            return
        }

        delegate?.onboardingNamingViewController(self, didCompletePlanetName: planetName, emoPetName: emoPetName)
    }
}
