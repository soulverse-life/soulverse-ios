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

    // MARK: - candidateCategories(for:)

    func test_candidateCategories_nilEmotion_returnsGeneralAndMixed() {
        let categories = DrawingsPromptManager.candidateCategories(for: nil)
        XCTAssertEqual(categories, [.general, .mixed])
    }

    func test_candidateCategories_combinedDyad_returnsBothPrimaryPools() {
        // optimism = joy + anticipation
        let categories = DrawingsPromptManager.candidateCategories(for: .optimism)
        XCTAssertEqual(categories, [.single(.joy), .single(.anticipation)])
    }

    func test_candidateCategories_intensityEmotion_returnsFamilyPrimaryOnly() {
        let categories = DrawingsPromptManager.candidateCategories(for: .serenity)
        XCTAssertEqual(categories, [.single(.joy)])
    }

    func test_candidateCategories_primaryEmotion_returnsThatPool() {
        let categories = DrawingsPromptManager.candidateCategories(for: .anger)
        XCTAssertEqual(categories, [.single(.anger)])
    }

    // MARK: - randomPrompt(for:from:)

    func test_randomPrompt_nilEmotion_drawsFromGeneralOrMixed() {
        let pool = [
            makePrompt(templateName: "g", category: .general),
            makePrompt(templateName: "m", category: .mixed),
            makePrompt(templateName: "j", category: .single(.joy)),
            makePrompt(templateName: "a", category: .single(.anger))
        ]
        let allowed: Set<DrawingsPromptCategory> = [.general, .mixed]
        for _ in 0..<50 {
            let picked = DrawingsPromptManager.randomPrompt(for: nil, from: pool)
            XCTAssertNotNil(picked)
            XCTAssertTrue(allowed.contains(picked!.category))
        }
    }

    func test_randomPrompt_combinedDyad_drawsFromBothPrimaryPools() {
        // optimism = joy + anticipation
        let pool = [
            makePrompt(templateName: "j", category: .single(.joy)),
            makePrompt(templateName: "a", category: .single(.anticipation)),
            makePrompt(templateName: "m", category: .mixed),
            makePrompt(templateName: "g", category: .general),
            makePrompt(templateName: "ang", category: .single(.anger))
        ]
        let allowed: Set<DrawingsPromptCategory> = [.single(.joy), .single(.anticipation)]
        for _ in 0..<50 {
            let picked = DrawingsPromptManager.randomPrompt(for: .optimism, from: pool)
            XCTAssertNotNil(picked)
            XCTAssertTrue(allowed.contains(picked!.category))
        }
    }

    func test_randomPrompt_intensityEmotion_drawsFromFamilyPrimaryPool() {
        // serenity → joy
        let pool = [
            makePrompt(templateName: "j", category: .single(.joy)),
            makePrompt(templateName: "m", category: .mixed),
            makePrompt(templateName: "g", category: .general),
            makePrompt(templateName: "a", category: .single(.anticipation))
        ]
        for _ in 0..<20 {
            let picked = DrawingsPromptManager.randomPrompt(for: .serenity, from: pool)
            XCTAssertEqual(picked?.category, .single(.joy))
        }
    }

    func test_randomPrompt_emptyMatchingPool_returnsNil() {
        let pool = [makePrompt(templateName: "j", category: .single(.joy))]
        let picked = DrawingsPromptManager.randomPrompt(for: .anger, from: pool)
        XCTAssertNil(picked)
    }

    func test_randomPrompt_combinedDyad_doesNotIncludeMixedOrGeneral() {
        // Regression guard: pre-fix routing pulled from .mixed for combined dyads.
        // After issue #70 fix, combined dyads must stay within their two primary pools.
        let pool = [
            makePrompt(templateName: "g", category: .general),
            makePrompt(templateName: "m", category: .mixed)
        ]
        let picked = DrawingsPromptManager.randomPrompt(for: .optimism, from: pool)
        XCTAssertNil(picked)
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
