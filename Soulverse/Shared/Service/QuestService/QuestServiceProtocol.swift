//
//  QuestServiceProtocol.swift
//  Soulverse
//

import Foundation

/// Cancels an active quest_state listener. Stored by callers and invoked on deinit.
final class QuestListenerToken {
    private let cancelHandler: () -> Void
    private var cancelled: Bool = false

    init(cancelHandler: @escaping () -> Void) {
        self.cancelHandler = cancelHandler
    }

    func cancel() {
        guard !cancelled else { return }
        cancelled = true
        cancelHandler()
    }

    deinit { cancel() }
}

protocol QuestServiceProtocol: AnyObject {
    /// Subscribes to real-time updates of users/{uid}/quest_state/state.
    /// The handler fires on the main queue. Pass the returned token to keep
    /// the listener alive; release it to unsubscribe.
    func listen(uid: String, onUpdate: @escaping (QuestStateModel) -> Void) -> QuestListenerToken

    /// Writes the two client-allowed quest_state fields. Per Plan 1 Security
    /// Rules, all other fields would reject.
    func writeTimezone(
        uid: String,
        offsetMinutes: Int,
        notificationHour: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}
