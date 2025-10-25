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
            // Skip Pet screen and go directly to Sensing
            showSensingScreen()
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

    private func showSensingScreen() {
        let viewController = MoodCheckInSensingViewController()
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

    func moodCheckInPetViewControllerDidTapBegin(_ viewController: MoodCheckInPetViewController) {
        // Mark that user has seen the Pet screen
        UserDefaults.standard.set(true, forKey: Self.hasSeenPetKey)
        showSensingScreen()
    }

    func moodCheckInPetViewControllerDidTapClose(_ viewController: MoodCheckInPetViewController) {
        handleCancellation()
    }
}

// MARK: - MoodCheckInSensingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInSensingViewControllerDelegate {

    func moodCheckInSensingViewController(_ viewController: MoodCheckInSensingViewController, didSelectColor color: UIColor, intensity: Float) {
        moodCheckInData.selectedColor = color
        moodCheckInData.colorIntensity = intensity
        showNamingScreen()
    }

    func moodCheckInSensingViewControllerDidTapBack(_ viewController: MoodCheckInSensingViewController) {
        navigationController.popViewController(animated: true)
    }

    func moodCheckInSensingViewControllerDidTapClose(_ viewController: MoodCheckInSensingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInNamingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInNamingViewControllerDelegate {

    func moodCheckInNamingViewController(_ viewController: MoodCheckInNamingViewController, didSelectEmotion emotion: EmotionType, intensity: Float) {
        moodCheckInData.emotion = emotion
        moodCheckInData.emotionIntensity = intensity
        showShapingScreen()
    }

    func moodCheckInNamingViewControllerDidTapBack(_ viewController: MoodCheckInNamingViewController) {
        navigationController.popViewController(animated: true)
    }

    func moodCheckInNamingViewControllerDidTapClose(_ viewController: MoodCheckInNamingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInShapingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInShapingViewControllerDelegate {

    func moodCheckInShapingViewController(_ viewController: MoodCheckInShapingViewController, didCompleteWithPrompt prompt: PromptOption, response: String) {
        moodCheckInData.selectedPrompt = prompt
        moodCheckInData.promptResponse = response
        showAttributingScreen()
    }

    func moodCheckInShapingViewControllerDidTapBack(_ viewController: MoodCheckInShapingViewController) {
        navigationController.popViewController(animated: true)
    }

    func moodCheckInShapingViewControllerDidTapClose(_ viewController: MoodCheckInShapingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInAttributingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInAttributingViewControllerDelegate {

    func moodCheckInAttributingViewController(_ viewController: MoodCheckInAttributingViewController, didSelectLifeArea lifeArea: LifeAreaOption) {
        moodCheckInData.lifeArea = lifeArea
        showEvaluatingScreen()
    }

    func moodCheckInAttributingViewControllerDidTapBack(_ viewController: MoodCheckInAttributingViewController) {
        navigationController.popViewController(animated: true)
    }

    func moodCheckInAttributingViewControllerDidTapClose(_ viewController: MoodCheckInAttributingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInEvaluatingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInEvaluatingViewControllerDelegate {

    func moodCheckInEvaluatingViewController(_ viewController: MoodCheckInEvaluatingViewController, didSelectEvaluation evaluation: EvaluationOption) {
        moodCheckInData.evaluation = evaluation
        showActingScreen()
    }

    func moodCheckInEvaluatingViewControllerDidTapBack(_ viewController: MoodCheckInEvaluatingViewController) {
        navigationController.popViewController(animated: true)
    }

    func moodCheckInEvaluatingViewControllerDidTapClose(_ viewController: MoodCheckInEvaluatingViewController) {
        showExitConfirmationDialog(from: viewController)
    }
}

// MARK: - MoodCheckInActingViewControllerDelegate

extension MoodCheckInCoordinator: MoodCheckInActingViewControllerDelegate {

    func moodCheckInActingViewControllerDidTapWriteJournal(_ viewController: MoodCheckInActingViewController) {
        submitMoodCheckInData()
    }

    func moodCheckInActingViewControllerDidTapMakeArt(_ viewController: MoodCheckInActingViewController) {
        submitMoodCheckInData()
        // Navigate to drawing canvas
        AppCoordinator.openDrawingCanvas(from: viewController)
    }

    func moodCheckInActingViewControllerDidTapCompleteCheckIn(_ viewController: MoodCheckInActingViewController) {
        submitMoodCheckInData()
    }

    func moodCheckInActingViewControllerDidTapBack(_ viewController: MoodCheckInActingViewController) {
        navigationController.popViewController(animated: true)
    }

    func moodCheckInActingViewControllerDidTapClose(_ viewController: MoodCheckInActingViewController) {
        showExitConfirmationDialog(from: viewController)
    }

    func moodCheckInActingViewControllerGetCurrentData(_ viewController: MoodCheckInActingViewController) -> MoodCheckInData {
        return moodCheckInData
    }
}

// MARK: - Delegate Protocols (To be implemented by ViewControllers)

protocol MoodCheckInPetViewControllerDelegate: AnyObject {
    func moodCheckInPetViewControllerDidTapBegin(_ viewController: MoodCheckInPetViewController)
    func moodCheckInPetViewControllerDidTapClose(_ viewController: MoodCheckInPetViewController)
}

protocol MoodCheckInSensingViewControllerDelegate: AnyObject {
    func moodCheckInSensingViewController(_ viewController: MoodCheckInSensingViewController, didSelectColor color: UIColor, intensity: Float)
    func moodCheckInSensingViewControllerDidTapBack(_ viewController: MoodCheckInSensingViewController)
    func moodCheckInSensingViewControllerDidTapClose(_ viewController: MoodCheckInSensingViewController)
}

protocol MoodCheckInNamingViewControllerDelegate: AnyObject {
    func moodCheckInNamingViewController(_ viewController: MoodCheckInNamingViewController, didSelectEmotion emotion: EmotionType, intensity: Float)
    func moodCheckInNamingViewControllerDidTapBack(_ viewController: MoodCheckInNamingViewController)
    func moodCheckInNamingViewControllerDidTapClose(_ viewController: MoodCheckInNamingViewController)
}

protocol MoodCheckInShapingViewControllerDelegate: AnyObject {
    func moodCheckInShapingViewController(_ viewController: MoodCheckInShapingViewController, didCompleteWithPrompt prompt: PromptOption, response: String)
    func moodCheckInShapingViewControllerDidTapBack(_ viewController: MoodCheckInShapingViewController)
    func moodCheckInShapingViewControllerDidTapClose(_ viewController: MoodCheckInShapingViewController)
}

protocol MoodCheckInAttributingViewControllerDelegate: AnyObject {
    func moodCheckInAttributingViewController(_ viewController: MoodCheckInAttributingViewController, didSelectLifeArea lifeArea: LifeAreaOption)
    func moodCheckInAttributingViewControllerDidTapBack(_ viewController: MoodCheckInAttributingViewController)
    func moodCheckInAttributingViewControllerDidTapClose(_ viewController: MoodCheckInAttributingViewController)
}

protocol MoodCheckInEvaluatingViewControllerDelegate: AnyObject {
    func moodCheckInEvaluatingViewController(_ viewController: MoodCheckInEvaluatingViewController, didSelectEvaluation evaluation: EvaluationOption)
    func moodCheckInEvaluatingViewControllerDidTapBack(_ viewController: MoodCheckInEvaluatingViewController)
    func moodCheckInEvaluatingViewControllerDidTapClose(_ viewController: MoodCheckInEvaluatingViewController)
}

protocol MoodCheckInActingViewControllerDelegate: AnyObject {
    func moodCheckInActingViewControllerDidTapWriteJournal(_ viewController: MoodCheckInActingViewController)
    func moodCheckInActingViewControllerDidTapMakeArt(_ viewController: MoodCheckInActingViewController)
    func moodCheckInActingViewControllerDidTapCompleteCheckIn(_ viewController: MoodCheckInActingViewController)
    func moodCheckInActingViewControllerDidTapBack(_ viewController: MoodCheckInActingViewController)
    func moodCheckInActingViewControllerDidTapClose(_ viewController: MoodCheckInActingViewController)
    func moodCheckInActingViewControllerGetCurrentData(_ viewController: MoodCheckInActingViewController) -> MoodCheckInData
}
