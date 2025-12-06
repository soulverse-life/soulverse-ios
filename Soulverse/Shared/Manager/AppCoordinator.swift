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
        
        guard let params = params,
              let currentVC = UIViewController.getLastPresentedViewController() else { return }

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
    
    
    static func openWebBrowser(to url: String) {
        guard let targetURL = URL(string: url) else { return }
        UIApplication.shared.open(targetURL)
    }
    
    
    static func openDrawingCanvas(from sourceVC: UIViewController, prompt: CanvasPrompt? = nil) {
        let drawingCanvasVC = DrawingCanvasViewController()
        drawingCanvasVC.hidesBottomBarWhenPushed = true

        // Set background image from prompt's template if available
        if let templateImage = prompt?.templateImage {
            drawingCanvasVC.backgroundImage = templateImage
        }

        guard let navigationVC = sourceVC.navigationController else {
            sourceVC.show(drawingCanvasVC, sender: nil)
            return
        }

        navigationVC.pushViewController(drawingCanvasVC, animated: true)
    }

    static func presentDrawingResult(image: UIImage, from sourceVC: UIViewController) {
        let drawingResultVC = DrawingResultViewController(drawingImage: image)
        let navigationController = UINavigationController(rootViewController: drawingResultVC)
        navigationController.modalPresentationStyle = .fullScreen

        sourceVC.present(navigationController, animated: true) {
            // After presentation, pop the DrawingCanvasViewController from the navigation stack
            sourceVC.navigationController?.popViewController(animated: false)
        }
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

    static func presentMoodCheckIn(from sourceVC: UIViewController, completion: ((Bool, MoodCheckInData?) -> Void)? = nil) {
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen

        // Create coordinator - it will manage its own lifecycle
        let coordinator = MoodCheckInCoordinator(navigationController: navigationController)

        // Set up completion handler
        coordinator.onComplete = { [weak sourceVC] data in
            sourceVC?.dismiss(animated: true) {
                completion?(true, data)
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
}
