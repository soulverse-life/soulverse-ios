//
//  FirestoreDeviceTokenService.swift
//  Soulverse
//
//  Lightweight FCM device-token persistence helper.
//  Per Phase 5 design: NOT a full service — just two statics.
//  Writes to users/{uid}/devices/{deviceId} per spec §4.5.
//

import Foundation
import FirebaseFirestore

enum FirestoreDeviceTokenService {

    private static let db = Firestore.firestore()
    private static let pendingKey = "soulverse.fcm.pendingTokenWrite"

    struct PendingWrite {
        let deviceId: String
        let token: String
        let appVersion: String
    }

    /// Persist the FCM token to Firestore. On failure, queues for retry.
    static func writeToken(
        uid: String,
        deviceId: String,
        token: String,
        appVersion: String,
        completion: ((Error?) -> Void)? = nil
    ) {
        let payload: [String: Any] = [
            "fcmToken":   token,
            "platform":   "ios",
            "appVersion": appVersion,
            "lastSeenAt": FieldValue.serverTimestamp()
        ]

        db.collection("users").document(uid)
            .collection("devices").document(deviceId)
            .setData(payload, merge: true) { error in
                if let error = error {
                    print("[FCM] Token write failed, queuing for retry: \(error.localizedDescription)")
                    enqueuePendingWrite(deviceId: deviceId, token: token, appVersion: appVersion)
                }
                completion?(error)
            }
    }

    /// Persist a failed write into UserDefaults so the next launch can retry.
    static func enqueuePendingWrite(deviceId: String, token: String, appVersion: String) {
        UserDefaults.standard.set(
            [
                "deviceId":   deviceId,
                "token":      token,
                "appVersion": appVersion
            ],
            forKey: pendingKey
        )
    }

    /// Pop and return any pending write. Returns nil if queue is empty.
    @discardableResult
    static func consumePendingWrite() -> PendingWrite? {
        guard
            let stored = UserDefaults.standard.dictionary(forKey: pendingKey),
            let deviceId   = stored["deviceId"]   as? String,
            let token      = stored["token"]      as? String,
            let appVersion = stored["appVersion"] as? String
        else {
            return nil
        }
        UserDefaults.standard.removeObject(forKey: pendingKey)
        return PendingWrite(deviceId: deviceId, token: token, appVersion: appVersion)
    }

    /// Retry any queued write for the current user. Safe to call on every app launch.
    static func flushPendingWrites(uid: String) {
        guard let pending = consumePendingWrite() else { return }
        writeToken(
            uid: uid,
            deviceId: pending.deviceId,
            token: pending.token,
            appVersion: pending.appVersion
        )
    }
}
