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

    private lazy var progressView: SoulverseProgressBar = {
        let progressBar = SoulverseProgressBar(totalSteps: 5)
        progressBar.setProgress(currentStep: 4)
        return progressBar
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "circle.hexagonpath")
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

    private lazy var planetImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.layer.cornerRadius = 50
        return view
    }()

    private lazy var planetNameLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_naming_planet_label", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var planetNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("onboarding_naming_planet_placeholder", comment: "")
        textField.font = .projectFont(ofSize: 16, weight: .regular)
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 8
        textField.backgroundColor = .white
        textField.delegate = self
        return textField
    }()

    private lazy var emoPetImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        view.layer.cornerRadius = 20

        // Create a teardrop shape using a custom path
        let shapeLayer = CAShapeLayer()
        let path = UIBezierPath()

        // Create teardrop path
        path.move(to: CGPoint(x: 20, y: 0))
        path.addCurve(to: CGPoint(x: 40, y: 20), controlPoint1: CGPoint(x: 31, y: 0), controlPoint2: CGPoint(x: 40, y: 9))
        path.addCurve(to: CGPoint(x: 20, y: 40), controlPoint1: CGPoint(x: 40, y: 31), controlPoint2: CGPoint(x: 31, y: 40))
        path.addCurve(to: CGPoint(x: 0, y: 20), controlPoint1: CGPoint(x: 9, y: 40), controlPoint2: CGPoint(x: 0, y: 31))
        path.addCurve(to: CGPoint(x: 20, y: 0), controlPoint1: CGPoint(x: 0, y: 9), controlPoint2: CGPoint(x: 9, y: 0))
        path.close()

        shapeLayer.path = path.cgPath
        shapeLayer.fillColor = UIColor.darkGray.cgColor
        view.layer.addSublayer(shapeLayer)

        return view
    }()

    private lazy var emoPetNameLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_naming_emopet_label", comment: "")
        label.font = .projectFont(ofSize: 14, weight: .medium)
        label.textColor = .themeTextPrimary
        label.textAlignment = .left
        return label
    }()

    private lazy var emoPetNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = NSLocalizedString("onboarding_naming_emopet_placeholder", comment: "")
        textField.font = .projectFont(ofSize: 16, weight: .regular)
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 8
        textField.backgroundColor = .white
        textField.delegate = self
        return textField
    }()

    private lazy var continueButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_continue_button", comment: ""),
            style: .primary,
            delegate: self
        )
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
        view.backgroundColor = .white

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
            make.centerX.equalToSuperview()
        }

        iconImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(50)
            make.width.height.equalTo(60)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconImageView.snp.bottom).offset(16)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        planetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            make.size.equalTo(100)
        }

        planetNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(40)
            make.top.equalTo(planetImageView.snp.bottom).offset(20)
        }

        planetNameTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(planetNameLabel.snp.bottom).offset(8)
            make.height.equalTo(44)
        }

        emoPetImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(planetNameTextField.snp.bottom).offset(30)
            make.size.equalTo(40)
        }

        emoPetNameLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(40)
            make.top.equalTo(emoPetImageView.snp.bottom).offset(20)
        }

        emoPetNameTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(40)
            make.top.equalTo(emoPetNameLabel.snp.bottom).offset(8)
            make.height.equalTo(44)
        }

        continueButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        view.endEditing(true)
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
        let planetName = planetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? NSLocalizedString("onboarding_naming_planet_placeholder", comment: "")
        let emoPetName = emoPetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? NSLocalizedString("onboarding_naming_emopet_placeholder", comment: "")

        delegate?.onboardingNamingViewController(self, didCompletePlanetName: planetName, emoPetName: emoPetName)
    }
}
