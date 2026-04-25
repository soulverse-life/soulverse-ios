//
//  EmotionalBundleServiceMock.swift
//  SoulverseTests
//

import Foundation
@testable import Soulverse

final class EmotionalBundleServiceMock: EmotionalBundleServiceProtocol {

    var fetchBundleResult: Result<EmotionalBundleModel?, Error> = .success(nil)
    var fetchBundleCallCount = 0

    var saveSectionResult: Result<Void, Error> = .success(())
    var saveSectionCallCount = 0
    var lastSavedSection: EmotionalBundleSection?
    var lastSavedData: EmotionalBundleSectionData?

    func fetchBundle(uid: String, completion: @escaping (Result<EmotionalBundleModel?, Error>) -> Void) {
        fetchBundleCallCount += 1
        completion(fetchBundleResult)
    }

    func saveSection(uid: String, section: EmotionalBundleSection, data: EmotionalBundleSectionData, completion: @escaping (Result<Void, Error>) -> Void) {
        saveSectionCallCount += 1
        lastSavedSection = section
        lastSavedData = data
        completion(saveSectionResult)
    }
}
