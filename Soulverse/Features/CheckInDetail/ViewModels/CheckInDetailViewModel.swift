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

    /// True when the check-in has a linked drawing in Firestore (driven by
    /// `MoodCheckInModel.drawingId != nil`). Available synchronously during
    /// phase 1, so the reflection section can be hidden upfront when no
    /// drawing is linked — avoids a brief flash where the section appears
    /// during loading and then collapses when phase 2 arrives.
    let hasLinkedDrawing: Bool
    let drawingId: String?
    let drawingImageURL: String?
    let reflectiveQuestion: String?
    let reflectiveAnswer: String?

    // MARK: - Journal

    let journalTitle: String?
    let journalContent: String?

    // MARK: - Identity

    let checkinId: String
    let recordedEmotion: RecordedEmotion?
}
