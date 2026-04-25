//
//  CrisisResourceModel.swift
//  Soulverse
//

import Foundation

struct CrisisResource: Codable {
    let name: String
    let number: String
    let descriptionKey: String
    let availability: String
}

struct CrisisResourceLoader {
    static func loadForCurrentLocale() -> CrisisResource? {
        guard let url = Bundle.main.url(forResource: "CrisisResources", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let resources = try? JSONDecoder().decode([String: CrisisResource].self, from: data) else {
            return nil
        }
        guard let countryCode = Locale.current.region?.identifier else { return nil }
        return resources[countryCode]
    }
}
