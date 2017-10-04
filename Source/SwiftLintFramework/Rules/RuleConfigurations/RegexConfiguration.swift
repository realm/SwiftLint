//
//  RegexConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct RegexConfiguration: RuleConfiguration, Equatable, CacheDescriptionProvider {
    public let identifier: String
    public var name: String?
    public var message = "Regex matched."
    public var regex: NSRegularExpression!
    public var included: NSRegularExpression?
    public var excluded: NSRegularExpression?
    public var matchKinds = SyntaxKind.allKinds
    public var severityConfiguration = SeverityConfiguration(.warning)

    public var severity: ViolationSeverity {
        return severityConfiguration.severity
    }

    public var consoleDescription: String {
        return "\(severity.rawValue): \(regex.pattern)"
    }

    internal var cacheDescription: String {
        var dict = [String: Any]()
        dict["identifier"] = identifier
        dict["name"] = name
        dict["message"] = message
        dict["regex"] = regex.pattern
        dict["included"] = included?.pattern
        dict["excluded"] = excluded?.pattern
        dict["match_kinds"] = matchKinds.map { $0.rawValue }
        dict["severity"] = severityConfiguration.consoleDescription
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
          let jsonString = String(data: jsonData, encoding: .utf8) {
              return jsonString
        }
        queuedFatalError("Could not serialize regex configuration for cache")
    }

    public var description: RuleDescription {
        return RuleDescription(identifier: identifier, name: name ?? identifier,
                               description: "", kind: .style)
    }

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any],
            let regexString = configurationDict["regex"] as? String else {
                throw ConfigurationError.unknownConfiguration
        }

        regex = try .cached(pattern: regexString)

        if let includedString = configurationDict["included"] as? String {
            included = try .cached(pattern: includedString)
        }

        if let excludedString = configurationDict["excluded"] as? String {
            excluded = try .cached(pattern: excludedString)
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
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

public func == (lhs: RegexConfiguration, rhs: RegexConfiguration) -> Bool {
    return lhs.identifier == rhs.identifier &&
           lhs.message == rhs.message &&
           lhs.regex == rhs.regex &&
           lhs.included?.pattern == rhs.included?.pattern &&
           lhs.excluded?.pattern == rhs.excluded?.pattern &&
           lhs.matchKinds == rhs.matchKinds &&
           lhs.severity == rhs.severity
}
