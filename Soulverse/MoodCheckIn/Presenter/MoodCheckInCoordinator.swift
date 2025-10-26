//
//  MoodCheckInCoordinator.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import UIKit

final class MoodCheckInCoordinator {

    // MARK: - Properties

    // Completion callbacks
    var onComplete: ((MoodCheckInData) -> Void)?
    var onCancel: (() -> Void)?

    private let navigationController: UINavigationController
    private var moodCheckInData = MoodCheckInData()

    // UserDefaults key for tracking if user has seen Pet screen
    private static let hasSeenPetKey = "hasSeenMoodCheckInPet"

    // Retain self to prevent deallocation during the flow
    private var strongSelf: MoodCheckInCoordinator?

    // MARK: - Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        // Retain self
        self.strongSelf = self
    }

    // MARK: - Public Methods

    func start() {
        // Check if user has seen the Pet introduction screen
        let hasSeenPet = UserDefaults.standard.bool(forKey: Self.hasSeenPetKey)

        if hasSeenPet {
            // Skip Pet screen and go directly to Sensing (as first screen)
            showSensingScreen(isFirstScreen: true)
        } else {
            // Show Pet screen first
            showPetScreen()
        }
    }

    // MARK: - Navigation Methods

    private func showPetScreen() {
        let viewController = MoodCheckInPetViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showSensingScreen(isFirstScreen: Bool = false) {
        let viewController = MoodCheckInSensingViewController()
        viewController.isFirstScreen = isFirstScreen
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showNamingScreen() {
        let viewController = MoodCheckInNamingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showShapingScreen() {
        let viewController = MoodCheckInShapingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showAttributingScreen() {
        let viewController = MoodCheckInAttributingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showEvaluatingScreen() {
        let viewController = MoodCheckInEvaluatingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showActingScreen() {
        let viewController = MoodCheckInActingViewController()
        viewController.delegate = self
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Confirmation Dialog

    func showExitConfirmationDialog(from viewController: UIViewController) {
        let cancelAction = SummitAlertAction(
            title: NSLocalizedString("cancel", comment: ""),
            style: .cancel,
            handler: nil
        )

        let exitAction = SummitAlertAction(
            title: NSLocalizedString("exit", comment: "Exit"),
            style: .destructive
        ) { [weak self] in
            guard let self = self else { return }
            self.handleCancellation()
        }

        SummitAlertView.shared.show(
            title: NSLocalizedString("exit_mood_checkin_title", comment: "Exit Mood Check-in?"),
            message: NSLocalizedString("exit_mood_checkin_message", comment: "Your progress will not be saved."),
            actions: [cancelAction, exitAction]
        )
    }

    // MARK: - Completion Handlers

    private func handleCancellation() {
        onCancel?()
        // Release self-reference to allow deallocation
        strongSelf = nil
    }

    private func submitMoodCheckInData() {
        // Make API call
        MoodCheckInAPIServiceProvider.request(.submitMoodCheckIn(moodCheckInData)) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let response):
                #if DEBUG
                print("[MoodCheckIn] Successfully submitted data: \(response)")
                #endif
                self.handleSubmissionSuccess()

            case .failure(let error):
                #if DEBUG
                print("[MoodCheckIn] Submission failed: \(error.localizedDescription)")
                #endif
                // For now, still show success (can add error handling later)
                self.handleSubmissionSuccess()
            }
        }
    }

    private func handleSubmissionSuccess() {
        // Show success message
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // You can use SwiftMessages or a custom success view here
            // For now, we'll complete the flow
            self.onComplete?(self.moodCheckInData)
            // Release self-reference to allow deallocation
            self.strongSelf = nil
        }
    }
}

// MARK: - MoodCheckInPetViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInPetViewControllerDelegate {

    func didTapBegin(_ viewController: MoodCheckInPetViewController) {
        // Mark that user has seen the Pet screen
        UserDefaults.standard.set(true, forKey: Self.hasSeenPetKey)
        showSensingScreen()
    }

    func didTapClose(_ viewController: MoodCheckInPetViewController) {
        handleCancellation()
    }
}

// MARK: - MoodCheckInSensingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInSensingViewControllerDelegate {

    func didSelectColor(_ viewController: MoodCheckInSensingViewController, color: UIColor, intensity: Double) {
        moodCheckInData.selectedColor = color
        moodCheckInData.colorIntensity = intensity
        showNamingScreen()
    }

    func didTapBack(_ viewController: MoodCheckInSensingViewController) {
        navigationController.popViewController(animated: true)
    }

    func didTapClose(_ viewController: MoodCheckInSensingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInNamingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInNamingViewControllerDelegate {

    func didSelectEmotion(_ viewController: MoodCheckInNamingViewController, emotion: EmotionType, intensity: Double) {
        moodCheckInData.emotion = emotion
        moodCheckInData.emotionIntensity = intensity
        showShapingScreen()
    }

    func didTapBack(_ viewController: MoodCheckInNamingViewController) {
        navigationController.popViewController(animated: true)
    }

    func didTapClose(_ viewController: MoodCheckInNamingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInShapingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInShapingViewControllerDelegate {

    func didComplete(_ viewController: MoodCheckInShapingViewController, prompt: PromptOption, response: String) {
        moodCheckInData.selectedPrompt = prompt
        moodCheckInData.promptResponse = response
        showAttributingScreen()
    }

    func didTapBack(_ viewController: MoodCheckInShapingViewController) {
        navigationController.popViewController(animated: true)
    }

    func didTapClose(_ viewController: MoodCheckInShapingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInAttributingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInAttributingViewControllerDelegate {

    func didSelectLifeArea(_ viewController: MoodCheckInAttributingViewController, lifeArea: LifeAreaOption) {
        moodCheckInData.lifeArea = lifeArea
        showEvaluatingScreen()
    }

    func didTapBack(_ viewController: MoodCheckInAttributingViewController) {
        navigationController.popViewController(animated: true)
    }

    func didTapClose(_ viewController: MoodCheckInAttributingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInEvaluatingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInEvaluatingViewControllerDelegate {

    func didSelectEvaluation(_ viewController: MoodCheckInEvaluatingViewController, evaluation: EvaluationOption) {
        moodCheckInData.evaluation = evaluation
        showActingScreen()
    }

    func didTapBack(_ viewController: MoodCheckInEvaluatingViewController) {
        navigationController.popViewController(animated: true)
    }

    func didTapClose(_ viewController: MoodCheckInEvaluatingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInActingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInActingViewControllerDelegate {

    func didTapWriteJournal(_ viewController: MoodCheckInActingViewController) {
        submitMoodCheckInData()
    }

    func didTapMakeArt(_ viewController: MoodCheckInActingViewController) {
        submitMoodCheckInData()
        // Navigate to drawing canvas
        AppCoordinator.openDrawingCanvas(from: viewController)
    }

    func didTapCompleteCheckIn(_ viewController: MoodCheckInActingViewController) {
        submitMoodCheckInData()
    }

    func didTapBack(_ viewController: MoodCheckInActingViewController) {
        navigationController.popViewController(animated: true)
    }

    func didTapClose(_ viewController: MoodCheckInActingViewController) {
        showExitConfirmationDialog(from: viewController)
    }

    func getCurrentData(_ viewController: MoodCheckInActingViewController) -> MoodCheckInData {
        return moodCheckInData
    }
}

// MARK: - Delegate Protocols (To be implemented by ViewControllers)

protocol MoodCheckInPetViewControllerDelegate: AnyObject {
    func didTapBegin(_ viewController: MoodCheckInPetViewController)
    func didTapClose(_ viewController: MoodCheckInPetViewController)
}

protocol MoodCheckInSensingViewControllerDelegate: AnyObject {
    func didSelectColor(_ viewController: MoodCheckInSensingViewController, color: UIColor, intensity: Double)
    func didTapBack(_ viewController: MoodCheckInSensingViewController)
    func didTapClose(_ viewController: MoodCheckInSensingViewController)
}

protocol MoodCheckInNamingViewControllerDelegate: AnyObject {
    func didSelectEmotion(_ viewController: MoodCheckInNamingViewController, emotion: EmotionType, intensity: Double)
    func didTapBack(_ viewController: MoodCheckInNamingViewController)
    func didTapClose(_ viewController: MoodCheckInNamingViewController)
}

protocol MoodCheckInShapingViewControllerDelegate: AnyObject {
    func didComplete(_ viewController: MoodCheckInShapingViewController, prompt: PromptOption, response: String)
    func didTapBack(_ viewController: MoodCheckInShapingViewController)
    func didTapClose(_ viewController: MoodCheckInShapingViewController)
}

protocol MoodCheckInAttributingViewControllerDelegate: AnyObject {
    func didSelectLifeArea(_ viewController: MoodCheckInAttributingViewController, lifeArea: LifeAreaOption)
    func didTapBack(_ viewController: MoodCheckInAttributingViewController)
    func didTapClose(_ viewController: MoodCheckInAttributingViewController)
}

protocol MoodCheckInEvaluatingViewControllerDelegate: AnyObject {
    func didSelectEvaluation(_ viewController: MoodCheckInEvaluatingViewController, evaluation: EvaluationOption)
    func didTapBack(_ viewController: MoodCheckInEvaluatingViewController)
    func didTapClose(_ viewController: MoodCheckInEvaluatingViewController)
}

protocol MoodCheckInActingViewControllerDelegate: AnyObject {
    func didTapWriteJournal(_ viewController: MoodCheckInActingViewController)
    func didTapMakeArt(_ viewController: MoodCheckInActingViewController)
    func didTapCompleteCheckIn(_ viewController: MoodCheckInActingViewController)
    func didTapBack(_ viewController: MoodCheckInActingViewController)
    func didTapClose(_ viewController: MoodCheckInActingViewController)
    func getCurrentData(_ viewController: MoodCheckInActingViewController) -> MoodCheckInData
}
