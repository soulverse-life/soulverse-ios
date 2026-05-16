//
//  QuestLayout.swift
//  Soulverse
//
//  Shared layout constants that apply across the entire Quest tab.
//  Per-view sizes (heights, paddings, font sizes) stay in each view's
//  private `Layout` enum; this file is for values that MUST stay
//  consistent across multiple card surfaces.
//

import UIKit

enum QuestLayout {
    static let cardCornerRadius: CGFloat = 12
    static let cardVerticalInset: CGFloat = 24
    static let cardHorizontalInset: CGFloat = 26
    static let cardTitleFontSize: CGFloat = 20
    static let cardSubtitleFontSize: CGFloat = 16
}
