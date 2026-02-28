//
//  MoodCheckInServiceMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class MoodCheckInServiceMock: MoodCheckInServiceProtocol {

    /// Simulates real Firebase behavior: completions arrive on a background thread.
    private let callbackQueue = DispatchQueue(label: "mock.moodcheckin.callback")

    // MARK: - Stubbed Results

    var submitResult: Result<String, Error> = .success("mock-checkin-id")
    var fetchLatestResult: Result<[MoodCheckInModel], Error> = .success([])
    var fetchByDateResult: Result<[MoodCheckInModel], Error> = .success([])
    var deleteResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking

    var submitCallCount = 0
    var fetchLatestCallCount = 0
    var fetchByDateCallCount = 0
    var deleteCallCount = 0

    var lastSubmitUID: String?
    var lastFetchUID: String?
    var lastDeleteCheckinId: String?

    // MARK: - Protocol Methods

    func submitMoodCheckIn(
        uid: String,
        data: MoodCheckInData,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        submitCallCount += 1
        lastSubmitUID = uid
        let result = submitResult
        callbackQueue.async { completion(result) }
    }

    func fetchLatestCheckIns(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    ) {
        fetchLatestCallCount += 1
        lastFetchUID = uid
        let result = fetchLatestResult
        callbackQueue.async { completion(result) }
    }

    func fetchCheckIns(
        uid: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    ) {
        fetchByDateCallCount += 1
        lastFetchUID = uid
        let result = fetchByDateResult
        callbackQueue.async { completion(result) }
    }

    func deleteCheckIn(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        deleteCallCount += 1
        lastDeleteCheckinId = checkinId
        let result = deleteResult
        callbackQueue.async { completion(result) }
    }
}
