//
//  JournalServiceMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class JournalServiceMock: JournalServiceProtocol {

    private let callbackQueue = DispatchQueue(label: "mock.journal.callback")

    // MARK: - Stubbed Results

    var submitResult: Result<String, Error> = .success("mock-journal-id")
    var fetchByIdResult: Result<JournalModel, Error> = .failure(NSError(domain: "mock", code: 0))
    var fetchByCheckinResult: Result<JournalModel?, Error> = .success(nil)
    var fetchByDateResult: Result<[JournalModel], Error> = .success([])
    var updateResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking

    var fetchByDateCallCount = 0

    // MARK: - Protocol Methods

    func submitJournal(uid: String, checkinId: String, title: String?, content: String?, prompt: String?, completion: @escaping (Result<String, Error>) -> Void) {
        let result = submitResult
        callbackQueue.async { completion(result) }
    }

    func fetchJournal(uid: String, journalId: String, completion: @escaping (Result<JournalModel, Error>) -> Void) {
        let result = fetchByIdResult
        callbackQueue.async { completion(result) }
    }

    func fetchJournal(uid: String, checkinId: String, completion: @escaping (Result<JournalModel?, Error>) -> Void) {
        let result = fetchByCheckinResult
        callbackQueue.async { completion(result) }
    }

    func fetchJournals(uid: String, from startDate: Date, to endDate: Date, completion: @escaping (Result<[JournalModel], Error>) -> Void) {
        fetchByDateCallCount += 1
        let result = fetchByDateResult
        callbackQueue.async { completion(result) }
    }

    func updateJournal(uid: String, journalId: String, title: String?, content: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        let result = updateResult
        callbackQueue.async { completion(result) }
    }

    func deleteJournal(uid: String, journalId: String, checkinId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let result = deleteResult
        callbackQueue.async { completion(result) }
    }
}
