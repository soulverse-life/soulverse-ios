//
//  ErrorReporting.swift
//  Soulverse
//

import Foundation
import FirebaseCrashlytics

protocol CrashlyticsClient {
    func setUserID(_ userID: String)
}

extension Crashlytics: CrashlyticsClient {
    func setUserID(_ userID: String) {
        // FIRCrashlytics declares setUserID: with nullable NSString *,
        // which bridges to Swift as `String?`. Forward the non-optional
        // String through to satisfy the protocol while preserving the
        // documented "" = clear semantics.
        let bridged: String? = userID
        setUserID(bridged)
    }
}

/// App-lifetime singleton that mirrors the current user identity into Firebase Crashlytics.
/// The NotificationCenter observer is intentionally not removed in deinit because this instance never deinits.
/// Do not construct additional runtime instances; use `ErrorReporting.shared`.
final class ErrorReporting: NSObject {

    static let shared = ErrorReporting(
        client: Crashlytics.crashlytics(),
        user: User.shared,
        notificationCenter: NotificationCenter.default
    )

    private let client: CrashlyticsClient
    private let user: UserProtocol
    private let notificationCenter: NotificationCenter

    init(client: CrashlyticsClient, user: UserProtocol, notificationCenter: NotificationCenter) {
        self.client = client
        self.user = user
        self.notificationCenter = notificationCenter
        super.init()
    }

    func start() {
        syncUserID()
        notificationCenter.addObserver(
            self,
            selector: #selector(handleUserIdentityChange),
            name: NSNotification.Name(rawValue: Notification.UserIdentityChange),
            object: nil
        )
    }

    @objc private func handleUserIdentityChange() {
        syncUserID()
    }

    private func syncUserID() {
        // Empty string is the documented way to "clear" the user ID in Crashlytics.
        client.setUserID(user.userId ?? "")
    }
}
