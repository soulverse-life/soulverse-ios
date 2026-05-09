import XCTest
@testable import Soulverse

final class FirestoreDeviceTokenServiceTests: XCTestCase {

    private let pendingKey = "soulverse.fcm.pendingTokenWrite"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: pendingKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: pendingKey)
        super.tearDown()
    }

    func test_enqueuePendingWrite_storesPayloadInUserDefaults() {
        FirestoreDeviceTokenService.enqueuePendingWrite(
            deviceId: "device-1",
            token: "fcm-abc",
            appVersion: "1.0.0"
        )

        let stored = UserDefaults.standard.dictionary(forKey: pendingKey)
        XCTAssertEqual(stored?["deviceId"] as? String, "device-1")
        XCTAssertEqual(stored?["token"] as? String, "fcm-abc")
        XCTAssertEqual(stored?["appVersion"] as? String, "1.0.0")
    }

    func test_consumePendingWrite_returnsAndClearsPayload() {
        FirestoreDeviceTokenService.enqueuePendingWrite(
            deviceId: "device-2",
            token: "fcm-xyz",
            appVersion: "1.0.0"
        )

        let payload = FirestoreDeviceTokenService.consumePendingWrite()

        XCTAssertEqual(payload?.deviceId, "device-2")
        XCTAssertEqual(payload?.token, "fcm-xyz")
        XCTAssertNil(UserDefaults.standard.dictionary(forKey: pendingKey))
    }

    func test_consumePendingWrite_returnsNilWhenNothingQueued() {
        XCTAssertNil(FirestoreDeviceTokenService.consumePendingWrite())
    }
}
