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
    private let authenticationService: OnboardingAuthenticationServiceProtocol
    private let dataService: OnboardingDataServiceProtocol
    private let sessionService: OnboardingSessionServiceProtocol
    private var userData = OnboardingUserData()

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        authenticationService: OnboardingAuthenticationServiceProtocol,
        dataService: OnboardingDataServiceProtocol,
        sessionService: OnboardingSessionServiceProtocol
    ) {
        self.navigationController = navigationController
        self.authenticationService = authenticationService
        self.dataService = dataService
        self.sessionService = sessionService
    }

    // MARK: - Public Methods

    func start() {
        showSignInScreen()
    }

    // MARK: - Navigation

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
        authenticationService.authenticateWithGoogle { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.userData.isSignedIn = true
                self.showBirthdayScreen()
            case .failure(let error):
                self.handleAuthenticationError(error)
            }
        }
    }

    private func handleAppleAuthentication() {
        authenticationService.authenticateWithApple { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.userData.isSignedIn = true
                self.showBirthdayScreen()
            case .failure(let error):
                self.handleAuthenticationError(error)
            }
        }
    }

    private func handleAuthenticationError(_ error: AuthenticationError) {
        print("[Onboarding] Authentication failed: \(error.localizedDescription)")
        // TODO: Show error alert to user
    }

    // MARK: - Data Submission

    private func submitOnboardingData() {
        dataService.submitOnboardingData(userData) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.handleOnboardingCompletion()
            case .failure(let error):
                self.handleDataSubmissionError(error)
            }
        }
    }

    private func handleDataSubmissionError(_ error: OnboardingDataError) {
        print("[Onboarding] Data submission failed: \(error.localizedDescription)")
        // TODO: Show error alert with retry option
        // For now, still complete onboarding for testing
        handleOnboardingCompletion()
    }

    private func handleOnboardingCompletion() {
        sessionService.markOnboardingAsCompleted()
        delegate?.onboardingCoordinatorDidComplete(self, userData: userData)
    }
}

// MARK: - OnboardingSignInViewControllerDelegate

extension OnboardingCoordinator: OnboardingSignInViewControllerDelegate {

    func onboardingSignInViewControllerDidTapGoogleSignIn(_ viewController: OnboardingSignInViewController) {
        handleGoogleAuthentication()
    }

    func onboardingSignInViewControllerDidTapAppleSignIn(_ viewController: OnboardingSignInViewController) {
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

    func onboardingTopicViewController(_ viewController: OnboardingTopicViewController, didSelectTopics topics: [TopicOption]) {
        userData.selectedTopics = topics
        submitOnboardingData()
    }
}
