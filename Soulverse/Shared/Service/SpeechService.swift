//
//  SpeechService.swift
//  Soulverse
//
//  A general-purpose text-to-speech service using AVSpeechSynthesizer.
//  Designed to be reusable across the app.
//

import AVFoundation

/// Delegate protocol for speech events
protocol SpeechServiceDelegate: AnyObject {
    func speechServiceDidStartSpeaking(_ service: SpeechService)
    func speechServiceDidFinishSpeaking(_ service: SpeechService)
    func speechServiceDidCancel(_ service: SpeechService)
}

// Make delegate methods optional
extension SpeechServiceDelegate {
    func speechServiceDidStartSpeaking(_ service: SpeechService) {}
    func speechServiceDidFinishSpeaking(_ service: SpeechService) {}
    func speechServiceDidCancel(_ service: SpeechService) {}
}

/// General-purpose text-to-speech service
@MainActor
final class SpeechService: NSObject {

    // MARK: - Singleton

    static let shared = SpeechService()

    // MARK: - Properties

    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking: Bool = false
    weak var delegate: SpeechServiceDelegate?

    // MARK: - Configuration

    /// Speech rate (0.0 - 1.0, default AVSpeechUtteranceDefaultSpeechRate ~0.5)
    var rate: Float = 0.2

    /// Speech pitch (0.5 - 2.0, default 1.0). Higher = more cheerful/bright
    var pitch: Float = 1.8

    /// Speech volume (0.0 - 1.0, default 1.0)
    var volume: Float = 1.0

    /// Optional voice identifier for specific voice selection
    /// Use `availableVoices(for:)` to get valid identifiers
    var voiceIdentifier: String?

    // MARK: - Initialization

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public Methods

    /// Speak the given text with automatic language detection
    /// - Parameters:
    ///   - text: The text to speak
    ///   - language: Optional language code (e.g., "en-US", "zh-TW"). If nil, auto-detects.
    func speak(_ text: String, language: String? = nil) {
        // Stop any ongoing speech
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = pitch
        utterance.volume = volume

        // Set voice: prefer specific identifier, then language, then auto-detect
        if let identifier = voiceIdentifier,
           let voice = AVSpeechSynthesisVoice(identifier: identifier) {
            utterance.voice = voice
        } else if let language = language {
            utterance.voice = AVSpeechSynthesisVoice(language: language)
        } else {
            let detectedLanguage = detectLanguage(for: text)
            utterance.voice = AVSpeechSynthesisVoice(language: detectedLanguage)
        }

        synthesizer.speak(utterance)
    }

    /// Get available voices for a language
    /// - Parameter languageCode: Language code (e.g., "en", "zh"). If nil, returns all voices.
    /// - Returns: Array of voice info tuples (identifier, name, language)
    static func availableVoices(for languageCode: String? = nil) -> [(identifier: String, name: String, language: String)] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let filtered = languageCode == nil ? voices : voices.filter { $0.language.hasPrefix(languageCode!) }
        return filtered.map { ($0.identifier, $0.name, $0.language) }
    }

    /// Stop any ongoing speech
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }

    /// Pause ongoing speech
    func pause() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
        }
    }

    /// Resume paused speech
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
        }
    }

    // MARK: - Private Methods

    /// Simple language detection based on character ranges
    private func detectLanguage(for text: String) -> String {
        // Check if text contains Chinese characters
        let chineseRange = text.range(of: "\\p{Han}", options: .regularExpression)
        if chineseRange != nil {
            return "zh-TW"
        }

        // Default to English
        return "en-US"
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension SpeechService: AVSpeechSynthesizerDelegate {

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        isSpeaking = true
        delegate?.speechServiceDidStartSpeaking(self)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
        delegate?.speechServiceDidFinishSpeaking(self)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        delegate?.speechServiceDidCancel(self)
    }
}
