//
//  SceneDelegate.swift
//  KonoSummit
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var onboardingCoordinator: OnboardingCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = determineRootViewController()
        window.windowScene = windowScene
        window.makeKeyAndVisible()
        self.window = window
    }

    // MARK: - Root View Controller Determination

    private func determineRootViewController() -> UIViewController {
        
        let user = User.shared
        let shouldShowOnboarding = !user.isLoggedin || !user.hasCompletedOnboarding

        if shouldShowOnboarding {
            return createOnboardingFlow()
        }
        
        return MainViewController()
    }

    private func createOnboardingFlow() -> UIViewController {
        let navigationController = UINavigationController()
        navigationController.setNavigationBarHidden(true, animated: false)

        let coordinator = OnboardingCoordinator(navigationController: navigationController)
        coordinator.delegate = self

        self.onboardingCoordinator = coordinator
        coordinator.start()

        return navigationController
    }

    private func transitionToMainApp() {
        guard let window = self.window else { return }

        let mainViewController = MainViewController()
        window.rootViewController = mainViewController

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
    }

    func transitionToOnboarding() {
        guard let window = self.window else { return }

        let onboardingVC = createOnboardingFlow()
        window.rootViewController = onboardingVC

        UIView.transition(
            with: window,
            duration: 0.3,
            options: .transitionCrossDissolve,
            animations: nil,
            completion: nil
        )
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle URL schemes if needed
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}

// MARK: - OnboardingCoordinatorDelegate

extension SceneDelegate: OnboardingCoordinatorDelegate {

    func onboardingCoordinatorDidComplete(_ coordinator: OnboardingCoordinator, userData: OnboardingUserData) {
        print("[SceneDelegate] Onboarding completed successfully")
        onboardingCoordinator = nil
        transitionToMainApp()
    }
}
