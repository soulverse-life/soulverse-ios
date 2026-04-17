//
//  EmotionalBundleMainViewModel.swift
//  Soulverse
//

import Foundation

struct BundleSectionCardViewModel {
    let section: EmotionalBundleSection
    let title: String
    let iconName: String
    let isCompleted: Bool
}

struct EmotionalBundleMainViewModel {
    let isLoading: Bool
    let sectionCards: [BundleSectionCardViewModel]

    init(isLoading: Bool = false, sectionCards: [BundleSectionCardViewModel] = []) {
        self.isLoading = isLoading
        self.sectionCards = sectionCards
    }

    static func completionCheck(for section: EmotionalBundleSection, in bundle: EmotionalBundleModel) -> Bool {
        switch section {
        case .redFlags:
            return bundle.redFlags.first.map { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        case .supportMe:
            return bundle.supportMe.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        case .feelCalm:
            return bundle.feelCalm.first.map { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        case .staySafe:
            return bundle.staySafe.first.map { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? false
        case .professionalSupport:
            return bundle.professionalSupport.contains {
                !($0.placeName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !($0.contactName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                !($0.phone ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
}
