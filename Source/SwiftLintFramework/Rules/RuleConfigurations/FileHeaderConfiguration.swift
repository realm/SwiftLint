//
//  FileHeaderConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 01/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct FileHeaderConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.Warning)
    private var requiredString: String?
    private var requiredPattern: String?
    private var forbiddenString: String?
    private var forbiddenPattern: String?

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

    // swiftlint:disable:next force_try
    private static let defaultRegex = try! NSRegularExpression(pattern: "\\bCopyright\\b",
                                                              options: [.CaseInsensitive])

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", required_string: \(requiredString)" +
        ", required_pattern: \(requiredPattern), forbidden_string: \(forbiddenString)" +
        ", forbidden_pattern: \(forbiddenPattern)"
    }

    public init() {
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configuration = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let requiredString = configuration["required_string"] as? String {
            self.requiredString = requiredString
            requiredRegex = try NSRegularExpression(pattern: requiredString,
                                                    options: [.IgnoreMetacharacters])
        } else if let requiredPattern = configuration["required_pattern"] as? String {
            self.requiredPattern = requiredPattern
            requiredRegex = try NSRegularExpression.cached(pattern: requiredPattern)
        }

        if let forbiddenString = configuration["forbidden_string"] as? String {
            self.forbiddenString = forbiddenString
            forbiddenRegex = try NSRegularExpression(pattern: forbiddenString,
                                                     options: [.IgnoreMetacharacters])
        } else if let forbiddenPattern = configuration["forbidden_pattern"] as? String {
            self.forbiddenPattern = forbiddenPattern
            forbiddenRegex = try NSRegularExpression.cached(pattern: forbiddenPattern)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: FileHeaderConfiguration,
                rhs: FileHeaderConfiguration) -> Bool {
    return lhs.severityConfiguration == rhs.severityConfiguration
}
