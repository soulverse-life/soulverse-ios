//
//  Constants+MoodCheckIn.swift
//  Soulverse
//
//  Shared layout constants for MoodCheckIn flow
//

import UIKit

/// Layout constants shared across all MoodCheckIn ViewControllers
enum MoodCheckInLayout {

    // MARK: - Progress

    /// Total number of steps in the mood check-in flow (excluding Pet intro)
    static let totalSteps: Int = 5

    // MARK: - Navigation

    /// Top offset from safe area for navigation elements
    static let navigationTopOffset: CGFloat = 16

    /// Left offset for back button
    static let navigationLeftOffset: CGFloat = 16


    // MARK: - Content Spacing

    /// Horizontal padding for content (left and right insets)
    static let horizontalPadding: CGFloat = 26

    /// Default vertical spacing between sections
    static let sectionSpacing: CGFloat = 24

    /// Spacing between title and subtitle
    static let titleToSubtitleSpacing: CGFloat = 8

    // MARK: - Title Offset

    /// Offset from progress bar to title
    static let titleTopOffset: CGFloat = 80

    // MARK: - Bottom

    /// Bottom padding from safe area for action buttons
    static let bottomPadding: CGFloat = 40

    // MARK: - Component Sizes

    /// Height for text input fields
    static let textFieldHeight: CGFloat = 80

    /// Height for color gradient slider
    static let colorSliderHeight: CGFloat = 28

    /// Height for intensity circles selector
    static let intensityCirclesHeight: CGFloat = 60
}
