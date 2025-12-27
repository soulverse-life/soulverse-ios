//
//  OnboardingLandingViewController.swift
//  Soulverse
//
//

import UIKit
import SnapKit

protocol OnboardingLandingViewControllerDelegate: AnyObject {
    func onboardingLandingViewControllerDidAgreeToTerms(_ viewController: OnboardingLandingViewController)
    func onboardingLandingViewControllerDidTapTermsOfService(_ viewController: OnboardingLandingViewController)
    func onboardingLandingViewControllerDidTapPrivacyPolicy(_ viewController: OnboardingLandingViewController)
}

class OnboardingLandingViewController: ViewController {

    // MARK: - Layout Constants

    private enum Layout {
        static let logoHeight: CGFloat = 182
        static let logoWidth: CGFloat = 175
        static let horizontalPadding: CGFloat = 40
    }
    
    // MARK: - UI Components

    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = UIImage(named: "launch_logo")
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_landing_welcome_title", comment: "")
        label.font = .projectFont(ofSize: 34, weight: .light)
        label.textColor = .themeTextPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("onboarding_landing_welcome_subtitle", comment: "")
        label.font = .projectFont(ofSize: 17, weight: .regular)
        label.textColor = .themeTextSecondary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var featuresStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .leading
        stack.distribution = .fill
        return stack
    }()

    private lazy var checkboxButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        button.tintColor = .themeTextPrimary
        button.addTarget(self, action: #selector(checkboxTapped), for: .touchUpInside)
        return button
    }()

    private lazy var termsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isUserInteractionEnabled = true

        let termsText = NSLocalizedString("onboarding_landing_terms_of_service", comment: "")
        let privacyText = NSLocalizedString("onboarding_landing_privacy_policy", comment: "")
        let fullText = String(format: NSLocalizedString("onboarding_landing_terms_checkbox", comment: ""), termsText, privacyText)

        let attributedString = NSMutableAttributedString(
            string: fullText,
            attributes: [
                .font: UIFont.projectFont(ofSize: 14, weight: .regular),
                .foregroundColor: UIColor.themeTextPrimary
            ]
        )

        // Make "Terms of Service" tappable
        if let termsRange = fullText.range(of: termsText) {
            let nsRange = NSRange(termsRange, in: fullText)
            attributedString.addAttributes([
                .foregroundColor: UIColor.themeTextPrimary,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        // Make "Privacy" tappable
        if let privacyRange = fullText.range(of: privacyText) {
            let nsRange = NSRange(privacyRange, in: fullText)
            attributedString.addAttributes([
                .foregroundColor: UIColor.themeTextPrimary,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: nsRange)
        }

        label.attributedText = attributedString

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(termsLabelTapped(_:)))
        label.addGestureRecognizer(tapGesture)

        return label
    }()

    private lazy var beginButton: SoulverseButton = {
        let button = SoulverseButton(
            title: NSLocalizedString("onboarding_landing_begin_button", comment: ""),
            style: .primary,
            delegate: self
        )
        button.isEnabled = false
        return button
    }()

    // MARK: - Properties

    weak var delegate: OnboardingLandingViewControllerDelegate?
    private var isTermsAccepted: Bool = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupFeatures()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(logoImageView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(featuresStackView)
        view.addSubview(checkboxButton)
        view.addSubview(termsLabel)
        view.addSubview(beginButton)

        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(64)
            make.height.equalTo(Layout.logoHeight)
            make.width.equalTo(Layout.logoWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(24)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(Layout.horizontalPadding)
        }

        featuresStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(subtitleLabel.snp.bottom).offset(16)
        }

        checkboxButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Layout.horizontalPadding)
            make.bottom.equalTo(beginButton.snp.top).offset(-30)
            make.size.equalTo(24)
        }

        termsLabel.snp.makeConstraints { make in
            make.left.equalTo(checkboxButton.snp.right).offset(12)
            make.right.equalToSuperview().offset(-Layout.horizontalPadding)
            make.centerY.equalTo(checkboxButton)
        }

        beginButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.left.right.equalToSuperview().inset(ViewComponentConstants.horizontalPadding)
            make.height.equalTo(ViewComponentConstants.actionButtonHeight)
        }
    }

    private func setupFeatures() {
        let features = [
            NSLocalizedString("onboarding_landing_feature_anonymous", comment: ""),
            NSLocalizedString("onboarding_landing_feature_community", comment: ""),
            NSLocalizedString("onboarding_landing_feature_privacy", comment: "")
        ]

        for feature in features {
            let featureView = createFeatureView(text: feature)
            featuresStackView.addArrangedSubview(featureView)
        }
    }

    private func createFeatureView(text: String) -> UIView {
        let containerView = UIView()

        let bulletLabel = UILabel()
        bulletLabel.text = "⭐"
        bulletLabel.font = .projectFont(ofSize: 13, weight: .regular)
        bulletLabel.textColor = .themeTextPrimary

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .projectFont(ofSize: 17, weight: .semibold)
        textLabel.textColor = .themeTextPrimary
        textLabel.numberOfLines = 1

        containerView.addSubview(bulletLabel)
        containerView.addSubview(textLabel)

        bulletLabel.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.equalTo(20)
        }

        textLabel.snp.makeConstraints { make in
            make.left.equalTo(bulletLabel.snp.right).offset(8)
            make.right.top.bottom.equalToSuperview()
        }

        return containerView
    }

    // MARK: - Actions

    @objc private func checkboxTapped() {
        isTermsAccepted.toggle()
        checkboxButton.isSelected = isTermsAccepted
        beginButton.isEnabled = isTermsAccepted
    }

    @objc private func termsLabelTapped(_ gesture: UITapGestureRecognizer) {
        guard let text = termsLabel.text else { return }

        let termsText = NSLocalizedString("onboarding_landing_terms_of_service", comment: "")
        let privacyText = NSLocalizedString("onboarding_landing_privacy_policy", comment: "")

        let tapLocation = gesture.location(in: termsLabel)
        let textContainer = NSTextContainer(size: termsLabel.bounds.size)
        let layoutManager = NSLayoutManager()
        let textStorage = NSTextStorage(attributedString: termsLabel.attributedText!)

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        textContainer.lineFragmentPadding = 0
        textContainer.maximumNumberOfLines = termsLabel.numberOfLines
        textContainer.lineBreakMode = termsLabel.lineBreakMode

        let characterIndex = layoutManager.characterIndex(
            for: tapLocation,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        // Check if tapped on "Terms of Service"
        if let termsRange = text.range(of: termsText) {
            let nsRange = NSRange(termsRange, in: text)
            if NSLocationInRange(characterIndex, nsRange) {
                delegate?.onboardingLandingViewControllerDidTapTermsOfService(self)
                return
            }
        }

        // Check if tapped on "Privacy"
        if let privacyRange = text.range(of: privacyText) {
            let nsRange = NSRange(privacyRange, in: text)
            if NSLocationInRange(characterIndex, nsRange) {
                delegate?.onboardingLandingViewControllerDidTapPrivacyPolicy(self)
                return
            }
        }
    }
}

// MARK: - SoulverseButtonDelegate

extension OnboardingLandingViewController: SoulverseButtonDelegate {
    func clickSoulverseButton(_ button: SoulverseButton) {
        guard isTermsAccepted else { return }
        delegate?.onboardingLandingViewControllerDidAgreeToTerms(self)
    }
}
