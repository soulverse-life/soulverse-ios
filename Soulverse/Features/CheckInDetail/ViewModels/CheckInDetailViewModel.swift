//
//  CheckInDetailViewModel.swift
//  Soulverse
//

import Foundation

struct CheckInDetailViewModel {

    // MARK: - Header

    let dateText: String
    let emotionName: String
    let colorHex: String
    let colorIntensity: Double

    // MARK: - Tags

    let intensityLevel: Int
    let topicLabel: String
    let topicRawValue: String

    // MARK: - Navigation

    let currentIndex: Int
    let totalCount: Int
    var canGoBack: Bool { currentIndex > 0 }
    var canGoForward: Bool { currentIndex < totalCount - 1 }

    // MARK: - Loading State

    /// True while drawing/journal are still being fetched from Firestore.
    let isLoadingContent: Bool

    // MARK: - Drawing / Reflection

    let drawingImageURL: String?
    let reflectionPrompt: String?
    let reflectionText: String?

    // MARK: - Journal

    let journalTitle: String?
    let journalContent: String?

    // MARK: - Identity

    let checkinId: String
}
