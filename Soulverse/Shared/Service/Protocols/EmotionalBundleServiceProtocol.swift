//
//  EmotionalBundleServiceProtocol.swift
//  Soulverse
//

import Foundation

protocol EmotionalBundleServiceProtocol {
    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void)
    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void)
}
