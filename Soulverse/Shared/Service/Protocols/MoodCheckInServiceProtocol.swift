//
//  MoodCheckInServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol MoodCheckInServiceProtocol {
    func submitMoodCheckIn(
        uid: String,
        data: MoodCheckInData,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func fetchLatestCheckIns(
        uid: String,
        limit: Int,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    )

    func fetchCheckIns(
        uid: String,
        from startDate: Date,
        to endDate: Date,
        completion: @escaping (Result<[MoodCheckInModel], Error>) -> Void
    )

    func deleteCheckIn(
        uid: String,
        checkinId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}
