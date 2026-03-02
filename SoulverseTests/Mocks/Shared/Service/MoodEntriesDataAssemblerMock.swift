//
//  MoodEntriesDataAssemblerMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class MoodEntriesDataAssemblerMock: MoodEntriesDataAssemblerProtocol {

    /// Simulates real Firebase behavior: completions arrive on a background thread.
    private let callbackQueue = DispatchQueue(label: "mock.assembler.callback")

    // MARK: - Stubbed Results

    var fetchInitialResult: Result<[MoodEntryCard], Error> = .success([])
    var fetchMoreResult: Result<[MoodEntryCard], Error> = .success([])

    // MARK: - State

    var hasMore: Bool = false

    // MARK: - Call Tracking

    var fetchInitialCallCount = 0
    var fetchMoreCallCount = 0
    var lastFetchInitialLimit: Int?

    // MARK: - Protocol Methods

    func fetchInitial(limit: Int, completion: @escaping (Result<[MoodEntryCard], Error>) -> Void) {
        fetchInitialCallCount += 1
        lastFetchInitialLimit = limit
        let result = fetchInitialResult
        callbackQueue.async { completion(result) }
    }

    func fetchMore(completion: @escaping (Result<[MoodEntryCard], Error>) -> Void) {
        fetchMoreCallCount += 1
        let result = fetchMoreResult
        callbackQueue.async { completion(result) }
    }
}
