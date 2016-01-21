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
    let identifier: String
    var message = "Regex matched."
    var regex = NSRegularExpression()
    var matchTokens = SyntaxKind.allKinds()
    var severityConfig = SeverityConfig(.Warning)

    public var severity: ViolationSeverity {
        return severityConfig.severity
    }

    public var description: RuleDescription {
        return RuleDescription(identifier: identifier,
            name: identifier,
            description: "")
    }

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func setConfig(config: AnyObject) throws {
        guard let configDict = config as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let message = configDict["message"] as? String {
            self.message = message
        }
        if let regexString = configDict["regex"] as? String {
            self.regex = try NSRegularExpression(pattern: regexString, options: [])
        }
        try [String].arrayOf(configDict["match_tokens"])?.forEach {
            self.matchTokens.append(try SyntaxKind(shortName: $0))
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
        lhs.matchTokens == rhs.matchTokens &&
        lhs.severity == rhs.severity
}
