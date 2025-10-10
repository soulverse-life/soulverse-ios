//
//  OnboardingSignInViewController.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit
import SnapKit

protocol OnboardingSignInViewControllerDelegate: AnyObject {
    func didCompleteSignIn()
    func didTapGoogleSignIn()
    func didTapAppleSignIn()
}

class OnboardingSignInViewController: UIViewController {

    // MARK: - UI Components

    private lazy var progressView: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .black
        progress.trackTintColor = .lightGray
        progress.progress = 0.2 // Step 2 of 5
        return progress
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Join the Soulverse community"
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()

    private lazy var googleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Google", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        button.layer.cornerRadius = 25

        // Add Google icon
        let googleIcon = UIImageView()
        googleIcon.contentMode = .scaleAspectFit
        button.addSubview(googleIcon)
        googleIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(button.titleLabel!.snp.left).offset(-8)
            make.size.equalTo(20)
        }

        button.addTarget(self, action: #selector(googleSignInTapped), for: .touchUpInside)
        return button
    }()

    private lazy var appleSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Apple", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .projectFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .black
        button.layer.cornerRadius = 25

        // Add Apple icon
        let appleIcon = UIImageView()
        appleIcon.contentMode = .scaleAspectFit
        appleIcon.tintColor = .white
        button.addSubview(appleIcon)
        appleIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(button.titleLabel!.snp.left).offset(-8)
            make.size.equalTo(20)
        }

        button.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingSignInViewControllerDelegate?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(progressView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(googleSignInButton)
        view.addSubview(appleSignInButton)

        progressView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(4)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(progressView.snp.bottom).offset(80)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        googleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(60)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }

        appleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(googleSignInButton.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(40)
            make.height.equalTo(50)
        }
    }

    // MARK: - Actions

    @objc private func googleSignInTapped() {
        delegate?.didTapGoogleSignIn()
    }

    @objc private func appleSignInTapped() {
        delegate?.didTapAppleSignIn()
    }
}