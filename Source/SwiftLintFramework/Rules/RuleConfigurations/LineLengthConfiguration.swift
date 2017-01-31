//
//  LineLengthConfiguration.swift
//  SwiftLint
//
//  Created by Javier Hernández on 21/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct LineLengthRuleOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public init() { self.rawValue = 0 }

    static let ignoreUrls = LineLengthRuleOptions(rawValue: 1 << 0)
    static let ignoreFunctionDeclarations = LineLengthRuleOptions(rawValue: 1 << 1)
    static let ignoreComments = LineLengthRuleOptions(rawValue: 1 << 2)

    static let all: LineLengthRuleOptions = [.ignoreUrls, .ignoreFunctionDeclarations, .ignoreComments]
}

public struct LineLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return length.consoleDescription + ", ignores urls: \(ignoresURLs)"
    }

    var length: SeverityLevelsConfiguration
    var ignoresURLs: Bool
    var ignoresFunctionDeclarations: Bool
    var ignoresComments: Bool

    var params: [RuleParameter<Int>] {
        return length.params
    }

    public init(warning: Int, error: Int?, options: LineLengthRuleOptions? = []) {
        length = SeverityLevelsConfiguration(warning: warning, error: error)
        if let options = options {
            self.ignoresURLs = options.contains(.ignoreUrls)
            self.ignoresFunctionDeclarations = options.contains(.ignoreFunctionDeclarations)
            self.ignoresComments = options.contains(.ignoreComments)
        } else {
            self.ignoresURLs = false
            self.ignoresFunctionDeclarations = false
            self.ignoresComments = false
        }
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            !configurationArray.isEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            length = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], !configDict.isEmpty
            && Set(configDict.keys).isSubset(of: ["warning",
                                                  "error",
                                                  "ignores_urls",
                                                  "ignores_function_declarations",
                                                  "ignores_comments"]) {
            let warning = configDict["warning"] as? Int ?? length.warning
            let error = configDict["error"] as? Int
            length = SeverityLevelsConfiguration(warning: warning, error: error)
            ignoresURLs = configDict["ignores_urls"] as? Bool ?? ignoresURLs
            if let funcDec =
                configDict["ignores_function_declarations"] as? Bool {            ignoresFunctionDeclarations = funcDec
            }
            ignoresComments = configDict["ignores_comments"] as? Bool ?? ignoresComments
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }

}

public func == (lhs: LineLengthConfiguration, rhs: LineLengthConfiguration) -> Bool {
    return lhs.length == rhs.length &&
        lhs.ignoresURLs == rhs.ignoresURLs &&
        lhs.ignoresComments == rhs.ignoresComments &&
        lhs.ignoresFunctionDeclarations == rhs.ignoresFunctionDeclarations
}
