//
//  FileHeaderConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct FileHeaderConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]

    private var severityParameter = SeverityConfiguration(.warning).severityParameter
    private var requiredStringParameter = OptionalParameter<String>(key: "required_string", default: nil,
                                                                    description: "")
    private var requiredPatternParameter = OptionalParameter<String>(key: "required_pattern", default: nil,
                                                                     description: "")
    private var forbiddenStringParameter = OptionalParameter<String>(key: "forbidden_string", default: nil,
                                                                     description: "")
    private var forbiddenPatternParameter = OptionalParameter<String>(key: "forbidden_pattern", default: nil,
                                                                      description: "")

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try severityParameter.parse(from: configuration)
        try requiredStringParameter.parse(from: configuration)
        try requiredPatternParameter.parse(from: configuration)
        try forbiddenStringParameter.parse(from: configuration)
        try forbiddenPatternParameter.parse(from: configuration)

        if let requiredString = requiredStringParameter.value {
            requiredRegex = try .cached(pattern: requiredString, options: [.ignoreMetacharacters])
        } else if let requiredPattern = requiredPatternParameter.value {
            requiredRegex = try .cached(pattern: requiredPattern)
        }

        if let forbiddenString = forbiddenStringParameter.value {
            forbiddenRegex = try .cached(pattern: forbiddenString, options: [.ignoreMetacharacters])
        } else if let forbiddenPattern = forbiddenPatternParameter.value {
            forbiddenRegex = try .cached(pattern: forbiddenPattern)
        }
    }

    private var _forbiddenRegex: NSRegularExpression?

    private(set) var requiredRegex: NSRegularExpression?
    private(set) var forbiddenRegex: NSRegularExpression? {
        get {
            if _forbiddenRegex != nil {
                return _forbiddenRegex
            }

            if requiredRegex == nil {
                return FileHeaderConfiguration.defaultRegex
            }

            return nil
        }
        set {
            _forbiddenRegex = newValue
        }
    }

    private static let defaultRegex = regex("\\bCopyright\\b", options: [.caseInsensitive])

    public init() {
        parameters = [requiredStringParameter, requiredPatternParameter,
                      forbiddenStringParameter, forbiddenPatternParameter,
                      severityParameter]
    }

    public static func == (lhs: FileHeaderConfiguration,
                           rhs: FileHeaderConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.requiredStringParameter == rhs.requiredStringParameter &&
            lhs.requiredPatternParameter == rhs.requiredPatternParameter &&
            lhs.forbiddenStringParameter == rhs.forbiddenStringParameter &&
            lhs.forbiddenPatternParameter == rhs.forbiddenPatternParameter
    }
}
