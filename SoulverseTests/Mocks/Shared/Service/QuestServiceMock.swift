//
//  QuestServiceMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class QuestServiceMock: QuestServiceProtocol {

    private(set) var lastWrittenOffsetMinutes: Int?
    private(set) var lastWrittenNotificationHour: Int?
    private(set) var listenedUid: String?

    private var handler: ((QuestStateModel) -> Void)?

    func listen(uid: String, onUpdate: @escaping (QuestStateModel) -> Void) -> QuestListenerToken {
        listenedUid = uid
        handler = onUpdate
        return QuestListenerToken { [weak self] in
            self?.handler = nil
        }
    }

    func emit(_ state: QuestStateModel) {
        handler?(state)
    }

    func writeTimezone(
        uid: String,
        offsetMinutes: Int,
        notificationHour: Int,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        lastWrittenOffsetMinutes = offsetMinutes
        lastWrittenNotificationHour = notificationHour
        completion(.success(()))
    }
}
