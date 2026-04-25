//
//  ProfessionalSupportSectionViewModel.swift
//  Soulverse
//

import Foundation

struct ProfessionalSupportSectionViewModel {
    var placeName: String = ""
    var contactName: String = ""
    var phone: String = ""
    let maxCharacters: Int = 100
    let crisisResource: CrisisResource?

    init(placeName: String = "", contactName: String = "", phone: String = "", crisisResource: CrisisResource? = CrisisResourceLoader.loadForCurrentLocale()) {
        self.placeName = placeName
        self.contactName = contactName
        self.phone = phone
        self.crisisResource = crisisResource
    }

    init(from items: [ProfessionalContact], crisisResource: CrisisResource? = CrisisResourceLoader.loadForCurrentLocale()) {
        let first = items.sorted(by: { $0.sortOrder < $1.sortOrder }).first
        self.placeName = first?.placeName ?? ""
        self.contactName = first?.contactName ?? ""
        self.phone = first?.phone ?? ""
        self.crisisResource = crisisResource
    }

    var hasContent: Bool {
        !placeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toSectionData() -> EmotionalBundleSectionData {
        return .professionalSupport([ProfessionalContact(placeName: placeName, contactName: contactName, phone: phone, sortOrder: 0)])
    }
}
