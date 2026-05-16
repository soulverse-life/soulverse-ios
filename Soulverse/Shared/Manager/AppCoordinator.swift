//
//  AppCoordinator.swift
//

import Foundation
import UIKit
import MessageUI
import DeviceKit

enum RoutingDestination: String {
    case TOC = "toc"
    case AudioPlayer = "track"
    case SummaryText = "article"
    case Profile = "profile"
    case MembershipPurchase = "purchase"
    case ExternalLink = "external_link"
    case Quest = "quest"
    case None

    var hasData: Bool {
        switch self {
        case .TOC, .AudioPlayer, .SummaryText, .ExternalLink:
            return true
        default:
            return false
        }
    }
}

enum SurveyType {
    case suggestTitle
    case deleteAccount
    
    var title: String {
        switch self {
        case .suggestTitle:
            return NSLocalizedString("vote_recommend_title", comment: "")
        case .deleteAccount:
            return NSLocalizedString("personal_info_row_delete_account", comment: "")
        }
    }
    
    var surveyURL: String {
        switch self {
        case .suggestTitle:
            return HostAppContants.suggestTitleURL
        case .deleteAccount:
            return HostAppContants.deleteAccountURL
        }
    }
}

class AppCoordinator {

    static func inAppRouting(_ params: [String: Any]?) {
        guard let params = params else { return }

        // Quest pushes from Cloud Functions carry `notificationKey`.
        // Treat any present value as a Quest tab deep-link.
        if let notificationKey = params["notificationKey"] as? String {
            print("[FCM] Routing Quest notification: \(notificationKey)")
            routeToQuestTab()
            return
        }

        guard let currentVC = UIViewController.getLastPresentedViewController() else { return }
        _ = currentVC // legacy paths below may consume it

        if let payload = params["payload"] as? String {
            let dest = RoutingDestination(rawValue: payload) ?? .None
            if dest.hasData {
                if let data = params["data"] as? String {
                    switch dest {
                    case .ExternalLink:
                        AppCoordinator.openWebBrowser(to: data)
                    default:
                        break
                    }
                }
            }
        }
    }

    /// Selects the Quest tab on the root tab bar controller.
    /// Called by `inAppRouting` when an FCM payload contains `notificationKey`.
    private static func routeToQuestTab() {
        DispatchQueue.main.async {
            guard
                let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
                let window = scene.windows.first(where: { $0.isKeyWindow }),
                let tabBar = window.rootViewController as? UITabBarController
            else { return }

            // Quest tab is index 4 per MainViewController layout.
            tabBar.selectedIndex = 4
        }
    }
    
    
    static func openWebBrowser(to url: String) {
        guard let targetURL = URL(string: url) else { return }
        UIApplication.shared.open(targetURL)
    }
    
    
    static func openCheckInDetail(from sourceVC: UIViewController, checkIns: [MoodCheckInModel], initialIndex: Int = 0) {
        let detailVC = CheckInDetailViewController(checkIns: checkIns, initialIndex: initialIndex)
        detailVC.hidesBottomBarWhenPushed = true
        sourceVC.navigationController?.pushViewController(detailVC, animated: true)
    }

    static func openDrawingCanvas(from sourceVC: UIViewController, drawingsPrompt: DrawingsPrompt? = nil, checkinId: String? = nil) {
        let drawingCanvasVC = DrawingCanvasViewController()
        drawingCanvasVC.hidesBottomBarWhenPushed = true
        drawingCanvasVC.checkinId = checkinId
        drawingCanvasVC.drawingsPrompt = drawingsPrompt

        guard let navigationVC = sourceVC.navigationController else {
            sourceVC.show(drawingCanvasVC, sender: nil)
            return
        }

        navigationVC.pushViewController(drawingCanvasVC, animated: true)
    }

    static func openDrawingGallery(from sourceVC: UIViewController) {
        let galleryVC = DrawingGalleryViewController()
        galleryVC.hidesBottomBarWhenPushed = true

        guard let navigationVC = sourceVC.navigationController else {
            sourceVC.show(galleryVC, sender: nil)
            return
        }

        navigationVC.pushViewController(galleryVC, animated: true)
    }

    static func presentDrawingReflection(
        viewModel: DrawingReflectionViewModel,
        from sourceVC: UIViewController,
        popSourceOnPresent: Bool = false
    ) {
        let reflectionVC = DrawingReflectionViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: reflectionVC)
        navigationController.modalPresentationStyle = .fullScreen

        sourceVC.present(navigationController, animated: true) {
            // Only the post-save flow needs to pop the underlying canvas, so
            // cancelling out of reflection doesn't drop the user back into
            // the canvas. Re-entry flows (e.g. CheckInDetail) must NOT pop —
            // sourceVC there is the detail page itself, and popping would
            // silently remove it from its nav stack.
            if popSourceOnPresent {
                sourceVC.navigationController?.popViewController(animated: false)
            }
        }
    }

    static func presentDrawingPrompt(
        from sourceVC: UIViewController,
        checkinId: String?,
        recordedEmotion: RecordedEmotion?
    ) {
        let promptVC = DrawingPromptViewController(
            checkinId: checkinId,
            recordedEmotion: recordedEmotion
        )
        let navigationController = UINavigationController(rootViewController: promptVC)
        navigationController.modalPresentationStyle = .fullScreen
        sourceVC.present(navigationController, animated: true)
    }

    static func openSpiralBreathing(from sourceVC: UIViewController) {
        let spiralVC = SpiralBreathingViewController()

        guard let navigationVC = sourceVC.navigationController else {
            // If no navigation controller, present it modally with a navigation controller
            let navController = UINavigationController(rootViewController: spiralVC)
            navController.modalPresentationStyle = .fullScreen
            sourceVC.present(navController, animated: true)
            return
        }

        navigationVC.pushViewController(spiralVC, animated: true)
    }

    static func openEmotionalBundle(from sourceVC: UIViewController) {
        guard let uid = User.shared.userId,
              let navigationVC = sourceVC.navigationController else { return }
        let coordinator = EmotionalBundleCoordinator(
            navigationController: navigationVC,
            uid: uid
        )
        coordinator.start()
    }

    static func presentMoodCheckIn(from sourceVC: UIViewController, completion: ((Bool, MoodCheckInData?) -> Void)? = nil) {
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen

        // Create coordinator - it will manage its own lifecycle
        let coordinator = MoodCheckInCoordinator(navigationController: navigationController)

        // Set up completion handler
        coordinator.onComplete = { [weak sourceVC, weak coordinator] data, selectedAction in
            let checkinId = coordinator?.lastSubmittedCheckinId

            sourceVC?.dismiss(animated: true) {
                completion?(true, data)

                // Handle post-dismiss action
                guard let sourceVC = sourceVC else { return }
                switch selectedAction {
                case .draw:
                    AppCoordinator.presentDrawingPrompt(
                        from: sourceVC,
                        checkinId: checkinId,
                        recordedEmotion: data.recordedEmotion
                    )
                case .writeJournal:
                    AppCoordinator.presentJournalEditor(
                        from: sourceVC,
                        checkinId: checkinId,
                        colorHex: data.colorHexString,
                        colorIntensity: data.colorIntensity,
                        emotionName: data.recordedEmotion?.displayName,
                        recordedEmotion: data.recordedEmotion
                    )
                case .none:
                    break
                }
            }
        }

        coordinator.onCancel = { [weak sourceVC] in
            sourceVC?.dismiss(animated: true) {
                completion?(false, nil)
            }
        }

        // Start the mood check-in flow
        coordinator.start()

        // Present the navigation controller
        sourceVC.present(navigationController, animated: true)
    }

    static func presentJournalEditor(
        from sourceVC: UIViewController,
        checkinId: String?,
        colorHex: String?,
        colorIntensity: Double,
        emotionName: String?,
        recordedEmotion: RecordedEmotion?
    ) {
        guard let checkinId = checkinId else { return }
        let vc = JournalEditorViewController(
            checkinId: checkinId,
            colorHex: colorHex,
            colorIntensity: colorIntensity,
            emotionName: emotionName
        )
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen

        // Holder is retained by the presented nav controller via associated object;
        // it deallocates automatically once the modal is dismissed.
        let holder = JournalEditorPresentationHolder(
            sourceVC: sourceVC,
            recordedEmotion: recordedEmotion
        )
        vc.delegate = holder
        objc_setAssociatedObject(nav, &journalEditorHolderKey, holder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        sourceVC.present(nav, animated: true)
    }
}

// MARK: - Journal Editor Presentation Holder

private nonisolated(unsafe) var journalEditorHolderKey: UInt8 = 0

private final class JournalEditorPresentationHolder: JournalEditorViewControllerDelegate {
    weak var sourceVC: UIViewController?
    let recordedEmotion: RecordedEmotion?

    init(sourceVC: UIViewController, recordedEmotion: RecordedEmotion?) {
        self.sourceVC = sourceVC
        self.recordedEmotion = recordedEmotion
    }

    func journalEditorDidSave(_ vc: JournalEditorViewController, journalId: String) {
        vc.presentingViewController?.dismiss(animated: true)
    }

    func journalEditorDidRequestDraw(_ vc: JournalEditorViewController) {
        let source = sourceVC
        let checkinId = vc.checkinId
        let emotion = recordedEmotion
        vc.presentingViewController?.dismiss(animated: true) {
            if let source = source {
                AppCoordinator.presentDrawingPrompt(
                    from: source,
                    checkinId: checkinId,
                    recordedEmotion: emotion
                )
            }
        }
    }
}
