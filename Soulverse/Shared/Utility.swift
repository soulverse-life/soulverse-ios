//
//  Utility.swift
//

import Foundation

class Utility {
    
    static func getAppVersion() -> String {
        let versionNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        return versionNumber + "." + buildNumber
    }
    
    static func getDoubleValue(_ value: Any?) -> Double? {
        guard value != nil else { return nil }
        
        if let doubleType = value as? Double {
            return doubleType
        }
        if let intType = value as? Int {
            return Double(intType)
        }
        
        if let stringType = value as? String {
            return Double(stringType)
        }
        return nil
    }
}
