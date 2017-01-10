//
//  LineLengthConfiguration.swift
//  SwiftLint
//
//  Created by Javier Hernández on 21/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct LineLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return length.consoleDescription + ", ignores urls: \(ignoresURLs)"
    }

    var length: SeverityLevelsConfiguration
    var ignoresURLs: Bool

    var params: [RuleParameter<Int>] {
        return length.params
    }

    public init(warning: Int, error: Int?, ignoresURLs: Bool) {
        length = SeverityLevelsConfiguration(warning: warning, error: error)
        self.ignoresURLs = ignoresURLs
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration), !configurationArray.isEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            length = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], !configDict.isEmpty
            && Set(configDict.keys).isSubset(of: ["warning", "error", "ignores_urls"]) {
            let warning = configDict["warning"] as? Int ?? length.warning
            let error = configDict["error"] as? Int
            length = SeverityLevelsConfiguration(warning: warning, error: error)
            ignoresURLs = configDict["ignores_urls"] as? Bool ?? ignoresURLs
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }

}

public func == (lhs: LineLengthConfiguration, rhs: LineLengthConfiguration) -> Bool {
    return lhs.length == rhs.length && lhs.ignoresURLs == rhs.ignoresURLs
}
