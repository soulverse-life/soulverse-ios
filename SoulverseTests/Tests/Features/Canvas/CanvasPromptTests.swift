//
//  CanvasPromptTests.swift
//  SoulverseTests
//

import XCTest
@testable import Soulverse

final class CanvasPromptTests: XCTestCase {

    // MARK: - emotion Computed Property

    func test_CanvasPrompt_emotion_validEmotionStr_returnsEmotionType() {
        let prompt = makePrompt(emotionStr: "joy")
        XCTAssertEqual(prompt.emotion, .joy)
    }

    func test_CanvasPrompt_emotion_nilEmotionStr_returnsNil() {
        let prompt = makePrompt(emotionStr: nil)
        XCTAssertNil(prompt.emotion)
    }

    func test_CanvasPrompt_emotion_emptyEmotionStr_returnsNil() {
        let prompt = makePrompt(emotionStr: "")
        XCTAssertNil(prompt.emotion)
    }

    func test_CanvasPrompt_emotion_invalidEmotionStr_returnsNil() {
        let prompt = makePrompt(emotionStr: "happiness")
        XCTAssertNil(prompt.emotion)
    }

    func test_CanvasPrompt_emotion_allValidEmotionTypes() {
        for emotionType in EmotionType.allCases {
            let prompt = makePrompt(emotionStr: emotionType.rawValue)
            XCTAssertEqual(prompt.emotion, emotionType, "Failed for \(emotionType.rawValue)")
        }
    }

    // MARK: - templateImage

    func test_CanvasPrompt_templateImage_nilTemplateName_returnsNil() {
        let prompt = makePrompt(templateName: nil)
        XCTAssertNil(prompt.templateImage)
    }

    func test_CanvasPrompt_templateImage_emptyTemplateName_returnsNil() {
        let prompt = makePrompt(templateName: "")
        XCTAssertNil(prompt.templateImage)
    }

    // MARK: - Codable

    func test_CanvasPrompt_codable_roundTrip() throws {
        let original = makePrompt(
            templateName: "template1",
            emotionStr: "anger"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CanvasPrompt.self, from: data)

        XCTAssertEqual(decoded.templateName, original.templateName)
        XCTAssertEqual(decoded.artTherapyPrompt, original.artTherapyPrompt)
        XCTAssertEqual(decoded.reflectiveQuestion, original.reflectiveQuestion)
        XCTAssertEqual(decoded.emotion, original.emotion)
    }
}

// MARK: - Helpers

private extension CanvasPromptTests {
    func makePrompt(
        templateName: String? = "default_template",
        emotionStr: String? = nil
    ) -> CanvasPrompt {
        return CanvasPrompt(
            templateName: templateName,
            artTherapyPrompt: "Draw how you feel",
            reflectiveQuestion: "What do you see?",
            emotionStr: emotionStr
        )
    }
}
