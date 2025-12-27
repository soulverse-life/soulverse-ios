//
//  OnboardingSignInViewController.swift
//  Soulverse
//
//

import UIKit
import SnapKit

protocol OnboardingSignInViewControllerDelegate: AnyObject {
    func didTapGoogleSignIn(_ viewController: OnboardingSignInViewController)
    func didTapAppleSignIn(_ viewController: OnboardingSignInViewController)
}

class OnboardingSignInViewController: ViewController {

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
        progressBar.setProgress(currentStep: 1)
        return progressBar
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "envelope.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .themeTextPrimary
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_signin_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .regular)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_signin_subtitle", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
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
        view.addSubview(backButton)
        view.addSubview(progressView)
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(googleSignInButton)
        view.addSubview(appleSignInButton)

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
            make.left.right.equalToSuperview().inset(48)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }

        googleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }

        appleSignInButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(googleSignInButton.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
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
