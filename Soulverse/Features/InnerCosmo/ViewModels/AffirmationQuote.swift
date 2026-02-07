//
//  AffirmationQuote.swift
//  Soulverse
//

import Foundation

/// Model representing an affirmation quote for the E.M.O pet
struct AffirmationQuote: Codable {
    let en: String
    let zhTW: String

    enum CodingKeys: String, CodingKey {
        case en
        case zhTW = "zh-TW"
    }

    /// Returns the localized text based on current locale
    var text: String {
        let languageCode = Locale.current.language.languageCode?.identifier ?? "en"
        return languageCode.hasPrefix("zh") ? zhTW : en
    }
}

/// Container for loading quotes from JSON
private struct AffirmationQuotesContainer: Codable {
    let quotes: [AffirmationQuote]
}

/// Manager for loading and providing affirmation quotes
enum AffirmationQuoteProvider {

    /// All available affirmation quotes loaded from JSON
    static let allQuotes: [AffirmationQuote] = {
        guard let url = Bundle.main.url(forResource: "AffirmationQuotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let container = try? JSONDecoder().decode(AffirmationQuotesContainer.self, from: data) else {
            // Fallback quote if JSON loading fails
            return [AffirmationQuote(en: "You are doing great.", zhTW: "你做得很好。")]
        }
        return container.quotes
    }()

    /// Returns a random affirmation quote
    static func random() -> AffirmationQuote {
        return allQuotes.randomElement() ?? allQuotes[0]
    }
}
