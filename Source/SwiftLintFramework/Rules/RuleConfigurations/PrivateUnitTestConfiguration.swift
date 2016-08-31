//
//  PrivateUnitTestConfiguration.swift
//  SwiftLint
//
//  Created by Cristian Filipov on 8/5/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct PrivateUnitTestConfiguration: RuleConfiguration, Equatable {
    public let identifier: String
    public var name: String?
    public var message = "Regex matched."
    public var regex = NSRegularExpression()
    public var included = NSRegularExpression()
    public var severityConfiguration = SeverityConfiguration(.Warning)

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    public var consoleDescription: String {
        return "\(severity.rawValue.lowercaseString): \(regex.pattern)"
    }

    public var description: RuleDescription {
        return RuleDescription(identifier: identifier,
                               name: name ?? identifier,
                               description: "")
    }

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configurationDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }
        if let regexString = configurationDict["regex"] as? String {
            regex = try NSRegularExpression.cached(pattern: regexString)
        }
        if let includedString = configurationDict["included"] as? String {
            included = try NSRegularExpression.cached(pattern: includedString)
        }
        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: PrivateUnitTestConfiguration, rhs: PrivateUnitTestConfiguration) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.message == rhs.message &&
        lhs.regex == rhs.regex &&
        lhs.included.pattern == rhs.included.pattern &&
        lhs.severity == rhs.severity
}
