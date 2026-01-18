//
//  OnboardingCoordinator.swift
//  Soulverse
//

import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingCoordinatorDidComplete(_ coordinator: OnboardingCoordinator, userData: OnboardingUserData)
}

final class OnboardingCoordinator {

    // MARK: - Properties

    weak var delegate: OnboardingCoordinatorDelegate?

    private let navigationController: UINavigationController
    private var userData = OnboardingUserData()

    // Authentication services
    private let appleAuthService = AppleUserAuthService()
    private let googleAuthService = GoogleUserAuthService()

    // MARK: - Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    // MARK: - Public Methods

    func start() {
        showLandingScreen()
    }

    // MARK: - Navigation

    private func showLandingScreen() {
        let viewController = OnboardingLandingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showSignInScreen() {
        let viewController = OnboardingSignInViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showBirthdayScreen() {
        let viewController = OnboardingBirthdayViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showGenderScreen() {
        let viewController = OnboardingGenderViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showNamingScreen() {
        let viewController = OnboardingNamingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showTopicSelectionScreen() {
        let viewController = OnboardingTopicViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Authentication

    private func handleGoogleAuthentication() {
        
        handleAuthenticationSuccess()
    
        /*
        //Todo: fill in require setting for google sign in
        googleAuthService.authenticate { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .AuthSuccess:
                self.handleAuthenticationSuccess()
            case .UserCancel:
                print("[Onboarding] User cancelled Google sign-in")
            default:
                self.handleAuthenticationError(result)
            }
        }
         */
    }

    private func handleAppleAuthentication() {
        handleAuthenticationSuccess()
        /*
        appleAuthService.authenticate { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .AuthSuccess:
                self.handleAuthenticationSuccess()
            case .UserCancel:
                print("[Onboarding] User cancelled Apple sign-in")
            default:
                self.handleAuthenticationError(result)
            }
        }
         */
    }

    private func handleAuthenticationSuccess() {
        userData.isSignedIn = true
        //User.shared.isLoggedin = true
        showBirthdayScreen()
    }

    private func handleAuthenticationError(_ error: AuthResult) {
        print("[Onboarding] Authentication failed: \(error.description)")
        // TODO: Show error alert to user
    }

    // MARK: - Data Submission

    private func submitOnboardingData() {
        
        User.shared.hasCompletedOnboarding = true
        User.shared.planetName = userData.planetName
        User.shared.emoPetName = userData.emoPetName
        self.handleOnboardingCompletion()
        
        /* TODO: Integrate the API
        
        UserService.submitOnboardingData(userData) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.handleOnboardingCompletion()
            case .failure(let error):
                self.handleDataSubmissionError(error)
            }
        }
         */
    }

    private func handleDataSubmissionError(_ error: ApiError) {
        print("[Onboarding] Data submission failed: \(error.description)")
        // TODO: Show error alert with retry option
        // For now, still complete onboarding for testing
        handleOnboardingCompletion()
    }

    private func handleOnboardingCompletion() {
        delegate?.onboardingCoordinatorDidComplete(self, userData: userData)
    }
}

// MARK: - OnboardingLandingViewControllerDelegate

extension OnboardingCoordinator: OnboardingLandingViewControllerDelegate {

    func onboardingLandingViewControllerDidAgreeToTerms(_ viewController: OnboardingLandingViewController) {
        showSignInScreen()
    }

    func onboardingLandingViewControllerDidTapTermsOfService(_ viewController: OnboardingLandingViewController) {
        // TODO: Open Terms of Service URL
        // For now, you can use WebViewController or Safari
        print("[Onboarding] User tapped Terms of Service")
    }

    func onboardingLandingViewControllerDidTapPrivacyPolicy(_ viewController: OnboardingLandingViewController) {
        // TODO: Open Privacy Policy URL
        // For now, you can use WebViewController or Safari
        print("[Onboarding] User tapped Privacy Policy")
    }
}

// MARK: - OnboardingSignInViewControllerDelegate

extension OnboardingCoordinator: OnboardingSignInViewControllerDelegate {

    func didTapGoogleSignIn(_ viewController: OnboardingSignInViewController) {
        handleGoogleAuthentication()
    }

    func didTapAppleSignIn(_ viewController: OnboardingSignInViewController) {
        handleAppleAuthentication()
    }
}

// MARK: - OnboardingBirthdayViewControllerDelegate

extension OnboardingCoordinator: OnboardingBirthdayViewControllerDelegate {

    func onboardingBirthdayViewController(_ viewController: OnboardingBirthdayViewController, didSelectBirthday date: Date) {
        userData.birthday = date
        showGenderScreen()
    }
}

// MARK: - OnboardingGenderViewControllerDelegate

extension OnboardingCoordinator: OnboardingGenderViewControllerDelegate {

    func onboardingGenderViewController(_ viewController: OnboardingGenderViewController, didSelectGender gender: GenderOption) {
        userData.gender = gender
        showNamingScreen()
    }
}

// MARK: - OnboardingNamingViewControllerDelegate

extension OnboardingCoordinator: OnboardingNamingViewControllerDelegate {

    func onboardingNamingViewController(_ viewController: OnboardingNamingViewController, didCompletePlanetName planetName: String, emoPetName: String) {
        userData.planetName = planetName
        userData.emoPetName = emoPetName
        showTopicSelectionScreen()
    }
}

// MARK: - OnboardingTopicViewControllerDelegate

extension OnboardingCoordinator: OnboardingTopicViewControllerDelegate {

    func onboardingTopicViewController(_ viewController: OnboardingTopicViewController, didSelectTopic topic: TopicOption) {
        userData.selectedTopic = topic
        submitOnboardingData()
    }
}
