//
//  TrackingServiceTests.swift
//  SoulverseTests
//
//  Created by mingshing on 2022/1/4.
//

import XCTest
@testable import Soulverse

class TrackingServiceTests: XCTestCase {

    var sut: TrackingService?

    func test_TrackingService_have_correct_trackingService_after_init() {

        sut = TrackingService()
        XCTAssertNotNil(sut?.services)
        XCTAssertEqual(sut?.count(ofType: FirebaseTrackingService.self), 1)

    }

    func test_TrackingService_set_trackingService_userProperty_after_init() {
        let mockUser = UserMock()
        let mockTrackService = TrackingServiceMock()
        sut = TrackingService(mockUser, services: [mockTrackService])

        XCTAssertNotNil(sut?.services)
        XCTAssertEqual(sut?.count(ofType: TrackingServiceMock.self), 1)
        XCTAssertEqual(mockUser.userId, mockTrackService.trackedUserId)
        XCTAssertEqual(mockUser.email, mockTrackService.trackedUserEmail)
    }

    func test_TrackingService_send_trackingEvent_success() {
        let mockUser = UserMock()
        let mockTrackService = TrackingServiceMock()
        let testEventName = "Test Event"
        let testEventProperties: [String: Any] = ["stringKey": "string", "intKey": 1]
        let mockEvent = TrackingEventMock(testEventName, eventProperties: testEventProperties)
        sut = TrackingService(mockUser, services: [mockTrackService])

        sut?.track(mockEvent)

        XCTAssertNotNil(mockTrackService.trackedEvent)
        XCTAssertEqual(mockTrackService.trackedEvent?.name, testEventName)
        XCTAssertEqual(mockTrackService.trackedEvent?.metadata["stringKey"] as! String, "string")
        XCTAssertEqual(mockTrackService.trackedEvent?.metadata["intKey"] as! Int, 1)
    }
}

private extension TrackingService {
    func count<T>(ofType: T.Type) -> Int {
        return services.filter{ $0 is T}.count
    }
}
