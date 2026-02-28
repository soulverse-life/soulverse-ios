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
    var onComplete: ((MoodCheckInData, MoodCheckInActingAction?) -> Void)?
    var onCancel: (() -> Void)?

    private let navigationController: UINavigationController
    private var moodCheckInData = MoodCheckInData()
    private var selectedAction: MoodCheckInActingAction?
    private(set) var lastSubmittedCheckinId: String?

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
        // Pass the selected color with intensity (alpha) from previous step
        if let selectedColor = moodCheckInData.selectedColor {
            let colorWithAlpha = selectedColor.withAlphaComponent(moodCheckInData.colorIntensity)
            viewController.setSelectedColor(colorWithAlpha)
        }
        navigationController.pushViewController(viewController, animated: true)
    }

    private func showShapingScreen() {
        let viewController = MoodCheckInShapingViewController()
        viewController.delegate = self
        // Pass the selected color with intensity (alpha) and recorded emotion from previous steps
        if let selectedColor = moodCheckInData.selectedColor,
           let recordedEmotion = moodCheckInData.recordedEmotion {
            let colorWithAlpha = selectedColor.withAlphaComponent(moodCheckInData.colorIntensity)
            viewController.setSelectedColorAndEmotion(color: colorWithAlpha, emotion: recordedEmotion)
        }
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
        guard let uid = User.shared.userId else {
            handleSubmissionSuccess()
            return
        }

        FirestoreMoodCheckInService.shared.submitMoodCheckIn(uid: uid, data: moodCheckInData) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let checkinId):
                self.lastSubmittedCheckinId = checkinId
                self.handleSubmissionSuccess()

            case .failure(let error):
                debugPrint("[MoodCheckIn] Firestore submission failed: \(error.localizedDescription)")
                // Still complete the flow so user isn't stuck; data may sync on retry
                self.handleSubmissionSuccess()
            }
        }
    }

    private func handleSubmissionSuccess() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.onComplete?(self.moodCheckInData, self.selectedAction)
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

    func didSelectEmotion(_ viewController: MoodCheckInNamingViewController, emotion: RecordedEmotion) {
        moodCheckInData.recordedEmotion = emotion
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

    func didComplete(_ viewController: MoodCheckInShapingViewController, prompt: PromptOption?, response: String?) {
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

    func didSelectTopic(_ viewController: MoodCheckInAttributingViewController, topic: Topic) {
        moodCheckInData.selectedTopic = topic
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

    func didTapCompleteCheckIn(_ viewController: MoodCheckInActingViewController, selectedAction: MoodCheckInActingAction?) {
        self.selectedAction = selectedAction
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
    func didSelectEmotion(_ viewController: MoodCheckInNamingViewController, emotion: RecordedEmotion)
    func didTapBack(_ viewController: MoodCheckInNamingViewController)
    func didTapClose(_ viewController: MoodCheckInNamingViewController)
}

protocol MoodCheckInShapingViewControllerDelegate: AnyObject {
    func didComplete(_ viewController: MoodCheckInShapingViewController, prompt: PromptOption?, response: String?)
    func didTapBack(_ viewController: MoodCheckInShapingViewController)
    func didTapClose(_ viewController: MoodCheckInShapingViewController)
}

protocol MoodCheckInAttributingViewControllerDelegate: AnyObject {
    func didSelectTopic(_ viewController: MoodCheckInAttributingViewController, topic: Topic)
    func didTapBack(_ viewController: MoodCheckInAttributingViewController)
    func didTapClose(_ viewController: MoodCheckInAttributingViewController)
}

protocol MoodCheckInEvaluatingViewControllerDelegate: AnyObject {
    func didSelectEvaluation(_ viewController: MoodCheckInEvaluatingViewController, evaluation: EvaluationOption)
    func didTapBack(_ viewController: MoodCheckInEvaluatingViewController)
    func didTapClose(_ viewController: MoodCheckInEvaluatingViewController)
}

protocol MoodCheckInActingViewControllerDelegate: AnyObject {
    func didTapCompleteCheckIn(_ viewController: MoodCheckInActingViewController, selectedAction: MoodCheckInActingAction?)
    func didTapBack(_ viewController: MoodCheckInActingViewController)
    func didTapClose(_ viewController: MoodCheckInActingViewController)
    func getCurrentData(_ viewController: MoodCheckInActingViewController) -> MoodCheckInData
}
