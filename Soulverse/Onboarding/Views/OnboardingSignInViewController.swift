//
//  OnboardingSignInViewController.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit
import SnapKit

protocol OnboardingSignInViewControllerDelegate: AnyObject {
    func didTapGoogleSignIn(_ viewController: OnboardingSignInViewController)
    func didTapAppleSignIn(_ viewController: OnboardingSignInViewController)
}

class OnboardingSignInViewController: UIViewController {

    // MARK: - UI Components

    private lazy var progressView: SoulverseProgressBar = {
        let progressBar = SoulverseProgressBar(totalSteps: 5)
        progressBar.setProgress(currentStep: 1)
        return progressBar
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_signin_title", comment: "")
        label.font = .projectFont(ofSize: 32, weight: .light)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_signin_subtitle", comment: "")
        label.font = .projectFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()

    private lazy var googleSignInButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_signin_google_button", comment: ""),
            style: .thirdPartyAuth(.google()),
            delegate: self
        )
        return button
    }()

    private lazy var appleSignInButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_signin_apple_button", comment: ""),
            style: .thirdPartyAuth(.apple()),
            delegate: self
        )
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
            make.centerX.equalToSuperview()
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
}

// MARK: - SoulverseButtonDelegate

extension OnboardingSignInViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        if button == googleSignInButton {
            delegate?.didTapGoogleSignIn(self)
        } else if button == appleSignInButton {
            delegate?.didTapAppleSignIn(self)
        }
    }
}
