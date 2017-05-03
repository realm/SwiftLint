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

    public init(rawValue: Int = 0) {
        self.rawValue = rawValue
    }

    public static let ignoreURLs = LineLengthRuleOptions(rawValue: 1 << 0)
    public static let ignoreFunctionDeclarations = LineLengthRuleOptions(rawValue: 1 << 1)
    public static let ignoreComments = LineLengthRuleOptions(rawValue: 1 << 2)

    public static let all: LineLengthRuleOptions = [.ignoreURLs, .ignoreFunctionDeclarations, .ignoreComments]
}

private enum ConfigurationKey: String {
    case warning = "warning"
    case error = "error"
    case ignoresURLs = "ignores_urls"
    case ignoresFunctionDeclarations = "ignores_function_declarations"
    case ignoresComments = "ignores_comments"
}

public struct LineLengthConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return length.consoleDescription +
               ", ignores urls: \(ignoresURLs)" +
               ", ignores function declarations: \(ignoresFunctionDeclarations)" +
               ", ignores comments: \(ignoresComments)"
    }

    var length: SeverityLevelsConfiguration
    var ignoresURLs: Bool
    var ignoresFunctionDeclarations: Bool
    var ignoresComments: Bool

    var params: [RuleParameter<Int>] {
        return length.params
    }

    public init(warning: Int, error: Int?, options: LineLengthRuleOptions = []) {
        self.length = SeverityLevelsConfiguration(warning: warning, error: error)
        self.ignoresURLs = options.contains(.ignoreURLs)
        self.ignoresFunctionDeclarations = options.contains(.ignoreFunctionDeclarations)
        self.ignoresComments = options.contains(.ignoreComments)
    }

    public mutating func apply(configuration: Any) throws {
        if let configurationArray = [Int].array(of: configuration),
            !configurationArray.isEmpty {
            let warning = configurationArray[0]
            let error = (configurationArray.count > 1) ? configurationArray[1] : nil
            length = SeverityLevelsConfiguration(warning: warning, error: error)
        } else if let configDict = configuration as? [String: Any], !configDict.isEmpty {
            for (string, value) in configDict {
                guard let key = ConfigurationKey(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
                }
                switch (key, value) {
                case (.error, let intValue as Int):
                    length.error = intValue
                case (.warning, let intValue as Int):
                    length.warning = intValue
                case (.ignoresFunctionDeclarations, let boolValue as Bool):
                    ignoresFunctionDeclarations = boolValue
                case (.ignoresComments, let boolValue as Bool):
                    ignoresComments = boolValue
                case (.ignoresURLs, let boolValue as Bool):
                    ignoresURLs = boolValue
                default:
                    throw ConfigurationError.unknownConfiguration
                }
            }
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
