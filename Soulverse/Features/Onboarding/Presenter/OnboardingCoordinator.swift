//
//  OnboardingCoordinator.swift
//  Soulverse
//
//  Created by Claude on 2024.
//

import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingDidComplete(_ userData: OnboardingUserData)
}

class OnboardingCoordinator: NSObject {

    // MARK: - Properties

    weak var delegate: OnboardingCoordinatorDelegate?
    private var navigationController: UINavigationController
    private var userData = OnboardingUserData()

    // MARK: - Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        super.init()
    }

    // MARK: - Public Methods

    func start() {
        showSignInPage()
    }

    // MARK: - Navigation Methods

    private func showSignInPage() {
        let signInVC = OnboardingSignInViewController()
        signInVC.delegate = self
        navigationController.pushViewController(signInVC, animated: true)
    }

    private func showBirthdayPage() {
        let birthdayVC = OnboardingBirthdayViewController()
        birthdayVC.delegate = self
        navigationController.pushViewController(birthdayVC, animated: true)
    }

    private func showGenderPage() {
        let genderVC = OnboardingGenderViewController()
        genderVC.delegate = self
        navigationController.pushViewController(genderVC, animated: true)
    }

    private func showNamingPage() {
        let namingVC = OnboardingNamingViewController()
        namingVC.delegate = self
        navigationController.pushViewController(namingVC, animated: true)
    }

    private func showTopicPage() {
        let topicVC = OnboardingTopicViewController()
        topicVC.delegate = self
        navigationController.pushViewController(topicVC, animated: true)
    }

    private func completeOnboarding() {
        delegate?.onboardingDidComplete(userData)
    }

    // MARK: - Authentication Helper

    private func performAuthentication(provider: AuthProvider) {
        // TODO: Integrate with existing auth services
        // For now, simulate successful authentication
        userData.isSignedIn = true
        showBirthdayPage()
    }
}

// MARK: - OnboardingSignInViewControllerDelegate

extension OnboardingCoordinator: OnboardingSignInViewControllerDelegate {

    func didCompleteSignIn() {
        showBirthdayPage()
    }

    func didTapGoogleSignIn() {
        performAuthentication(provider: .google)
    }

    func didTapAppleSignIn() {
        performAuthentication(provider: .apple)
    }
}

// MARK: - OnboardingBirthdayViewControllerDelegate

extension OnboardingCoordinator: OnboardingBirthdayViewControllerDelegate {

    func didSelectBirthday(_ date: Date) {
        userData.birthday = date
        showGenderPage()
    }
}

// MARK: - OnboardingGenderViewControllerDelegate

extension OnboardingCoordinator: OnboardingGenderViewControllerDelegate {

    func didSelectGender(_ gender: GenderOption) {
        userData.gender = gender
        showNamingPage()
    }
}

// MARK: - OnboardingNamingViewControllerDelegate

extension OnboardingCoordinator: OnboardingNamingViewControllerDelegate {

    func didCompletNaming(planetName: String, emoPetName: String) {
        userData.planetName = planetName
        userData.emoPetName = emoPetName
        showTopicPage()
    }
}

// MARK: - OnboardingTopicViewControllerDelegate

extension OnboardingCoordinator: OnboardingTopicViewControllerDelegate {

    func didCompleteOnboarding(selectedTopics: [TopicOption]) {
        userData.selectedTopics = selectedTopics
        completeOnboarding()
    }
}

// MARK: - Supporting Types

enum AuthProvider {
    case google
    case apple
}