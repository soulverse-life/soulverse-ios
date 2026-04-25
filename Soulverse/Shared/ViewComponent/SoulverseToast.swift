//
//  SoulverseToast.swift
//  Soulverse
//

import UIKit
import SwiftMessages

/// Project-wide wrapper for SwiftMessages-based toasts.
/// Hides the SwiftMessages config so callers don't need to import it.
enum SoulverseToast {

    enum Style {
        case error
        case warning
        case success
        case info

        fileprivate func apply(to view: MessageView) {
            switch self {
            case .error: view.configureTheme(.error)
            case .warning: view.configureTheme(.warning)
            case .success: view.configureTheme(.success)
            case .info: view.configureTheme(.info)
            }
        }
    }

    static func show(
        _ style: Style,
        title: String? = nil,
        message: String,
        duration: TimeInterval = 3
    ) {
        MainActor.assumeIsolated {
            let view = MessageView.viewFromNib(layout: .cardView)
            style.apply(to: view)
            view.configureDropShadow()
            view.configureContent(title: title ?? "", body: message)
            view.button?.isHidden = true
            var config = SwiftMessages.Config()
            config.presentationStyle = .top
            config.duration = .seconds(seconds: duration)
            SwiftMessages.show(config: config, view: view)
        }
    }
}
