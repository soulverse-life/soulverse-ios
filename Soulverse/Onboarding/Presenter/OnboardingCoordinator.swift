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
    #if DEBUG
    private let devAuthService = DevAuthService()
    #endif

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

    // MARK: - Authentication

    private func handleGoogleAuthentication() {
        googleAuthService.authenticate { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .AuthSuccess(let isNewUser):
                self.handleAuthenticationSuccess(isNewUser: isNewUser)
            case .UserCancel:
                print("[Onboarding] User cancelled Google sign-in")
            default:
                self.handleAuthenticationError(result)
            }
        }
    }

    private func handleAppleAuthentication() {
        appleAuthService.authenticate { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .AuthSuccess(let isNewUser):
                self.handleAuthenticationSuccess(isNewUser: isNewUser)
            case .UserCancel:
                print("[Onboarding] User cancelled Apple sign-in")
            default:
                self.handleAuthenticationError(result)
            }
        }
    }

    #if DEBUG
    private func handleDevAuthentication() {
        devAuthService.authenticate { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .AuthSuccess(let isNewUser):
                self.handleAuthenticationSuccess(isNewUser: isNewUser)
            default:
                self.handleAuthenticationError(result)
            }
        }
    }
    #endif

    private func handleAuthenticationSuccess(isNewUser: Bool) {
        userData.isSignedIn = true
        if isNewUser {
            showBirthdayScreen()
        } else {
            // Returning user — fetch profile to check onboarding status
            if let uid = User.shared.userId {
                FirestoreUserService.fetchUserProfile(uid: uid) { [weak self] result in
                    guard let self = self else { return }
                    switch result {
                    case .success(let profile):
                        User.shared.populate(from: profile)
                        let completed = profile.hasCompletedOnboarding ?? false

                        if completed {
                            self.delegate?.onboardingCoordinatorDidComplete(self, userData: self.userData)
                        } else {
                            self.showBirthdayScreen()
                        }
                    case .failure:
                        // Fetch failed — safer to continue onboarding
                        self.showBirthdayScreen()
                    }
                }
            } else {
                showBirthdayScreen()
            }
        }
    }

    private func handleAuthenticationError(_ error: AuthResult) {
        print("[Onboarding] Authentication failed: \(error.description)")
        // TODO: Show error alert to user
    }

    // MARK: - Data Submission

    private func submitOnboardingData() {
        guard let uid = User.shared.userId else {
            print("[Onboarding] No user ID available for submission")
            handleOnboardingCompletion()
            return
        }

        FirestoreUserService.submitOnboardingData(uid: uid, data: userData) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.handleOnboardingCompletion()
            case .failure(let error):
                print("[Onboarding] Firestore submission failed: \(error.localizedDescription)")
                // Still complete onboarding for now — data can sync later
                self.handleOnboardingCompletion()
            }
        }
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
        print("[Onboarding] User tapped Terms of Service")
    }

    func onboardingLandingViewControllerDidTapPrivacyPolicy(_ viewController: OnboardingLandingViewController) {
        // TODO: Open Privacy Policy URL
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

    #if DEBUG
    func didTapDevSignIn(_ viewController: OnboardingSignInViewController) {
        handleDevAuthentication()
    }
    #endif
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
        submitOnboardingData()
    }
}
