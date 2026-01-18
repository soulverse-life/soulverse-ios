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
    var planetName: String?
    var petName: String?

    // MARK: - Emotion Data

    var emotions: [EmotionPlanetData]

    // MARK: - Initialization

    init(
        isLoading: Bool = false,
        userName: String? = nil,
        planetName: String? = nil,
        petName: String? = nil,
        emotions: [EmotionPlanetData] = []
    ) {
        self.isLoading = isLoading
        self.userName = userName
        self.planetName = planetName
        self.petName = petName
        self.emotions = emotions
    }
}
