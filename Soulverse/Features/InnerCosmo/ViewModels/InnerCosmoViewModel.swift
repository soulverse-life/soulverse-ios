//
//  InnerCosmoViewModel.swift
//  Soulverse
//
//  Created by mingshing on 2021/8/15.
//

import Foundation

struct InnerCosmoViewModel {

    // MARK: - State

    var isLoading: Bool

    // MARK: - User Data

    var userName: String?
    var petName: String?
    var planetName: String?

    // MARK: - Emotion Data

    var emotions: [EmotionPlanetData]

    // MARK: - Mood Entry Cards

    var moodEntries: [MoodEntry]

    // MARK: - Initialization

    init(
        isLoading: Bool = false,
        userName: String? = nil,
        petName: String? = nil,
        planetName: String? = nil,
        emotions: [EmotionPlanetData] = [],
        moodEntries: [MoodEntry] = []
    ) {
        self.isLoading = isLoading
        self.userName = userName
        self.petName = petName
        self.planetName = planetName
        self.emotions = emotions
        self.moodEntries = moodEntries
    }
}
