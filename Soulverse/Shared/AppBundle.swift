//
//  AppBundle.swift
//  Soulverse
//

import Foundation

/// Resolves to the bundle that contains `Localizable.strings`, regardless of
/// whether the caller runs inside the app process or a test target (where
/// `Bundle.main` may be the xctest runner).
enum AppBundle {
    static let main: Bundle = {
        let candidates: [Bundle] = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        for bundle in candidates where bundle.path(forResource: "Localizable", ofType: "strings") != nil {
            return bundle
        }
        return Bundle.main
    }()
}
