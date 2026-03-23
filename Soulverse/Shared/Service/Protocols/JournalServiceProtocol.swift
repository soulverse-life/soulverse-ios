//
//  JournalServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol JournalServiceProtocol {
    func submitJournal(
        uid: String,
        checkinId: String,
        title: String?,
        content: String?,
        prompt: String?,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func fetchJournal(
        uid: String,
        journalId: String,
        completion: @escaping (Result<JournalModel, Error>) -> Void
    )

    func fetchJournal(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<JournalModel?, Error>) -> Void
    )

    func fetchJournals(
        uid: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[JournalModel], Error>) -> Void
    )

    func updateJournal(
        uid: String,
        journalId: String,
        title: String?,
        content: String?,
        completion: @escaping (Result<Void, Error>) -> Void
    )

    func deleteJournal(
        uid: String,
        journalId: String,
        checkinId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}
