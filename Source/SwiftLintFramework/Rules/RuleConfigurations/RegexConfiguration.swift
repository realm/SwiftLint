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
    public var regex: NSRegularExpression!
    public var included: NSRegularExpression?
    public var matchKinds = Set(SyntaxKind.allKinds())
    public var excludeKinds = Set<SyntaxKind>()
    public var severityConfiguration = SeverityConfiguration(.warning)
    public var template: String?

    public var isCorrectable: Bool {
        return template != nil
    }

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    public var consoleDescription: String {
        return "\(severity.rawValue): \(regex.pattern)"
    }

    public var description: RuleDescription {
        return RuleDescription(identifier: identifier, name: name ?? identifier, description: "")
    }

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func applyConfiguration(_ configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any],
            let regexString = configurationDict["regex"] as? String else {
                throw ConfigurationError.unknownConfiguration
        }

        regex = try .cached(pattern: regexString)

        if let includedString = configurationDict["included"] as? String {
            included = try .cached(pattern: includedString)
        }

        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let matchKinds = [String].array(of: configurationDict["match_kinds"]) {
            self.matchKinds = Set(try matchKinds.map({ try SyntaxKind(shortName: $0) }))
        }
        if let excludeKinds = [String].array(of: configurationDict["exclude_kinds"]) {
            self.excludeKinds = Set(try excludeKinds.map({ try SyntaxKind(shortName: $0) }))
        }
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.applyConfiguration(severityString)
        }
        if let template = configurationDict["template"] as? String {
            self.template = template
        }
    }

    public static func == (lhs: RegexConfiguration, rhs: RegexConfiguration) -> Bool {
        return lhs.identifier == rhs.identifier &&
            lhs.message == rhs.message &&
            lhs.regex == rhs.regex &&
            lhs.included?.pattern == rhs.included?.pattern &&
            lhs.matchKinds == rhs.matchKinds &&
            lhs.excludeKinds == rhs.excludeKinds &&
            lhs.severity == rhs.severity &&
            lhs.template == rhs.template
    }
}
