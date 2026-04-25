//
//  DrawingsPromptTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class DrawingsPromptTests: XCTestCase {

    // MARK: - templateImage

    func test_DrawingsPrompt_templateImage_nilTemplateName_returnsNil() {
        let prompt = makePrompt(templateName: nil)
        XCTAssertNil(prompt.templateImage)
    }

    func test_DrawingsPrompt_templateImage_emptyTemplateName_returnsNil() {
        let prompt = makePrompt(templateName: "")
        XCTAssertNil(prompt.templateImage)
    }

    // MARK: - Codable round-trip

    func test_DrawingsPrompt_codable_roundTrip_single() throws {
        let original = makePrompt(templateName: "template1", category: .single(.anger))
        let decoded = try roundTrip(original)

        XCTAssertEqual(decoded.templateName, original.templateName)
        XCTAssertEqual(decoded.artTherapyPrompt, original.artTherapyPrompt)
        XCTAssertEqual(decoded.reflectiveQuestion, original.reflectiveQuestion)
        XCTAssertEqual(decoded.category, .single(.anger))
    }

    func test_DrawingsPrompt_codable_roundTrip_mixed() throws {
        let decoded = try roundTrip(makePrompt(category: .mixed))
        XCTAssertEqual(decoded.category, .mixed)
    }

    func test_DrawingsPrompt_codable_roundTrip_general() throws {
        let decoded = try roundTrip(makePrompt(category: .general))
        XCTAssertEqual(decoded.category, .general)
    }

    func test_DrawingsPrompt_codable_roundTrip_allEmotionTypes() throws {
        for emotionType in EmotionType.allCases {
            let decoded = try roundTrip(makePrompt(category: .single(emotionType)))
            XCTAssertEqual(decoded.category, .single(emotionType), "Failed for \(emotionType.rawValue)")
        }
    }

    // MARK: - JSON schema guards

    func test_DrawingsPrompt_decode_nullEmotion_isGeneral() throws {
        let decoded = try decodePrompt(emotionJSON: "null")
        XCTAssertEqual(decoded.category, .general)
    }

    func test_DrawingsPrompt_decode_mixedEmotion_isMixed() throws {
        let decoded = try decodePrompt(emotionJSON: "\"mixed\"")
        XCTAssertEqual(decoded.category, .mixed)
    }

    func test_DrawingsPrompt_decode_knownPrimary_isSingle() throws {
        let decoded = try decodePrompt(emotionJSON: "\"joy\"")
        XCTAssertEqual(decoded.category, .single(.joy))
    }

    func test_DrawingsPrompt_decode_unknownEmotion_fallsBackToGeneral() throws {
        let decoded = try decodePrompt(emotionJSON: "\"happiness\"")
        XCTAssertEqual(decoded.category, .general)
    }

    func test_DrawingsPrompt_encode_general_writesNullEmotion() throws {
        let data = try JSONEncoder().encode(makePrompt(category: .general))
        let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        // `NSNull` on encode = JSON null; ensure the key exists with a null value.
        XCTAssertTrue(object?["emotion"] is NSNull)
    }
}

// MARK: - Helpers

private extension DrawingsPromptTests {
    func makePrompt(
        templateName: String? = "default_template",
        category: DrawingsPromptCategory = .general
    ) -> DrawingsPrompt {
        return DrawingsPrompt(
            templateName: templateName,
            artTherapyPrompt: "Draw how you feel",
            reflectiveQuestion: "What do you see?",
            category: category
        )
    }

    func roundTrip(_ drawingsPrompt: DrawingsPrompt) throws -> DrawingsPrompt {
        let data = try JSONEncoder().encode(drawingsPrompt)
        return try JSONDecoder().decode(DrawingsPrompt.self, from: data)
    }

    func decodePrompt(emotionJSON: String) throws -> DrawingsPrompt {
        let json = """
        {
            "templateName": null,
            "artTherapyPrompt": "Draw how you feel",
            "reflectiveQuestion": "What do you see?",
            "emotion": \(emotionJSON)
        }
        """
        return try JSONDecoder().decode(DrawingsPrompt.self, from: Data(json.utf8))
    }
}
