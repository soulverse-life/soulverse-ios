//
//  OnboardingNamingViewController.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit
import SnapKit

protocol OnboardingNamingViewControllerDelegate: AnyObject {
    func onboardingNamingViewController(_ viewController: OnboardingNamingViewController, didCompletePlanetName planetName: String, emoPetName: String)
}

class OnboardingNamingViewController: UIViewController {

    // MARK: - UI Components

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .black
        progress.trackTintColor = .lightGray
        progress.progress = 0.8 // Step 5 of 5
        return progress
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Naming"
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Name your world, name your friend.\nGive your planet a cosmic identity\nand your emopet a loyal name to join\nyou on this journey."
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        label.numberOfLines = 4
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
        label.text = "Name your planet"
        label.font = .projectFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()

    private lazy var planetNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Vancouver"
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
        label.text = "Name your EmoPet"
        label.font = .projectFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.textAlignment = .left
        return label
    }()

    private lazy var emoPetNameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Pocky"
        textField.font = .projectFont(ofSize: 16, weight: .regular)
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.layer.cornerRadius = 8
        textField.backgroundColor = .white
        textField.delegate = self
        return textField
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
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(40)
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

    @objc private func continueTapped() {
        let planetName = planetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Vancouver"
        let emoPetName = emoPetNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Pocky"

        delegate?.onboardingNamingViewController(self, didCompletePlanetName: planetName, emoPetName: emoPetName)
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