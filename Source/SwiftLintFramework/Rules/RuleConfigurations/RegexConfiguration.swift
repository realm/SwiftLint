//
//  RegexConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RegexConfiguration: RuleConfiguration, Equatable {
    public let identifier: String
    public var name: String?
    public var message = "Regex matched."
    public var regex = NSRegularExpression()
    public var matchKinds = Set(SyntaxKind.allKinds())
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
        guard let configurationDict = configuration as? [String: AnyObject],
            regexString = configurationDict["regex"] as? String else {
            throw ConfigurationError.UnknownConfiguration
        }

        regex = try NSRegularExpression.cached(pattern: regexString)

        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let matchKinds = [String].arrayOf(configurationDict["match_kinds"]) {
            self.matchKinds = Set( try matchKinds.map { try SyntaxKind(shortName: $0) })
        }
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
    }
}

public func == (lhs: RegexConfiguration, rhs: RegexConfiguration) -> Bool {
    return lhs.identifier == rhs.identifier &&
           lhs.message == rhs.message &&
           lhs.regex == rhs.regex &&
           lhs.matchKinds == rhs.matchKinds &&
           lhs.severity == rhs.severity
}
