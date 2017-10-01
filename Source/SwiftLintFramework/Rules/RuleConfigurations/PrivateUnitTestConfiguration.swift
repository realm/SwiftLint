//
//  PrivateUnitTestConfiguration.swift
//  SwiftLint
//
//  Created by Cristian Filipov on 8/5/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct PrivateUnitTestConfiguration: RuleConfiguration, Equatable, CacheDescriptionProvider {
    public let identifier: String
    public var name: String?
    public var message = "Regex matched."
    public var regex: NSRegularExpression!
    public var included: NSRegularExpression?
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
        dict["severity"] = severityConfiguration.consoleDescription
        if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
          let jsonString = String(data: jsonData, encoding: .utf8) {
              return jsonString
        }
        queuedFatalError("Could not serialize private unit test configuration for cache")
    }

    public init(identifier: String) {
        self.identifier = identifier
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        if let regexString = configurationDict["regex"] as? String {
            regex = try .cached(pattern: regexString)
        }
        if let includedString = configurationDict["included"] as? String {
            included = try .cached(pattern: includedString)
        }
        if let name = configurationDict["name"] as? String {
            self.name = name
        }
        if let message = configurationDict["message"] as? String {
            self.message = message
        }
        if let severityString = configurationDict["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }
}

public func == (lhs: PrivateUnitTestConfiguration, rhs: PrivateUnitTestConfiguration) -> Bool {
    return lhs.identifier == rhs.identifier &&
        lhs.message == rhs.message &&
        lhs.regex == rhs.regex &&
        lhs.included?.pattern == rhs.included?.pattern &&
        lhs.severity == rhs.severity
}
