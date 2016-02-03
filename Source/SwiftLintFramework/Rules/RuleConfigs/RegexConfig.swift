//
//  RegexConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RegexConfig: RuleConfig, Equatable {
    public let identifier: String
    public var name: String?
    public var message = "Regex matched."
    public var regex = NSRegularExpression()
    public var matchKinds = Set(SyntaxKind.allKinds())
    public var severityConfig = SeverityConfig(.Warning)

    public var severity: ViolationSeverity {
        return severityConfig.severity
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

    public mutating func setConfig(config: AnyObject) throws {
        guard let configDict = config as? [String: AnyObject],
              let regexString = configDict["regex"] as? String else {
            throw ConfigurationError.UnknownConfiguration
        }

        regex = try NSRegularExpression.cached(pattern: regexString)

        if let name = configDict["name"] as? String {
            self.name = name
        }
        if let message = configDict["message"] as? String {
            self.message = message
        }
        if let matchKinds = [String].arrayOf(configDict["match_kinds"]) {
            self.matchKinds = Set( try matchKinds.map { try SyntaxKind(shortName: $0) })
        }
        if let severityString = configDict["severity"] as? String {
            try severityConfig.setConfig(severityString)
        }
    }
}

public func == (lhs: RegexConfig, rhs: RegexConfig) -> Bool {
    return lhs.identifier == rhs.identifier &&
           lhs.message == rhs.message &&
           lhs.regex == rhs.regex &&
           lhs.matchKinds == rhs.matchKinds &&
           lhs.severity == rhs.severity
}
