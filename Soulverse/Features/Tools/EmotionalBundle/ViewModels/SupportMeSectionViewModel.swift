//
//  SupportMeSectionViewModel.swift
//  Soulverse
//

import Foundation

struct SupportMeContactViewModel {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var relationship: String = ""
}

struct SupportMeSectionViewModel {
    var contacts: [SupportMeContactViewModel]  // Fixed count: 2
    let maxCharacters: Int = 100

    init(contacts: [SupportMeContactViewModel] = [SupportMeContactViewModel(), SupportMeContactViewModel()]) {
        self.contacts = contacts
    }

    init(from items: [SupportContact]) {
        var contactVMs = items.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
            SupportMeContactViewModel(name: $0.name, phone: $0.phone ?? "", email: $0.email ?? "", relationship: $0.relationship ?? "")
        }
        while contactVMs.count < 2 { contactVMs.append(SupportMeContactViewModel()) }
        self.contacts = Array(contactVMs.prefix(2))
    }

    var hasContent: Bool {
        contacts.contains { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func toSectionData() -> EmotionalBundleSectionData {
        let items = contacts.enumerated().map { index, vm in
            SupportContact(name: vm.name, phone: vm.phone, email: vm.email, relationship: vm.relationship, sortOrder: index)
        }
        return .supportMe(items)
    }
}
