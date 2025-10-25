//
//  MoodCheckInAPIService.swift
//  Soulverse
//
//  Created by Claude on 2025.
//

import Foundation
import Moya

let MoodCheckInAPIServiceProvider = MoyaProvider<MoodCheckInAPIService>()

enum MoodCheckInAPIService {
    case submitMoodCheckIn(MoodCheckInData)
}

extension MoodCheckInAPIService: TargetType {
    var baseURL: URL {
        return URL(string: HostAppContants.serverUrl)!
    }

    var path: String {
        switch self {
        case .submitMoodCheckIn:
            return "mood-checkin"
        }
    }

    var method: Moya.Method {
        switch self {
        case .submitMoodCheckIn:
            return .post
        }
    }

    var sampleData: Data {
        return Data()
    }

    var task: Task {
        switch self {
        case .submitMoodCheckIn(let data):
            var parameters: [String: Any] = [:]

            // Color and intensity
            if let colorHex = data.colorHexString {
                parameters["selected_color"] = colorHex
            }
            parameters["color_intensity"] = data.colorIntensity

            // Emotion and intensity
            if let emotion = data.emotion {
                parameters["emotion"] = emotion.rawValue
            }
            parameters["emotion_intensity"] = data.emotionIntensity

            // Prompt and response
            if let prompt = data.selectedPrompt {
                parameters["selected_prompt"] = prompt.rawValue
            }
            if let response = data.promptResponse {
                parameters["prompt_response"] = response
            }

            // Life area
            if let lifeArea = data.lifeArea {
                parameters["life_area"] = lifeArea.rawValue
            }

            // Evaluation
            if let evaluation = data.evaluation {
                parameters["evaluation"] = evaluation.rawValue
            }

            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        return ["Content-type": "application/json"]
    }
}
