//
//  SeverityConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return severity.rawValue
    }

    var severity: ViolationSeverity

    public init(_ severity: ViolationSeverity) {
        self.severity = severity
    }

    public mutating func apply(configuration: Any) throws {
        let configString = configuration as? String
        let configDict = configuration as? [String: Any]
        guard let severityString: String = configString ?? configDict?["severity"] as? String,
            let severity = severity(fromString: severityString) else {
            throw ConfigurationError.unknownConfiguration
        }
        self.severity = severity
    }

    fileprivate func severity(fromString string: String) -> ViolationSeverity? {
        return ViolationSeverity(rawValue: string.lowercased())
    }
}

public func == (lhs: SeverityConfiguration, rhs: SeverityConfiguration) -> Bool {
    return lhs.severity == rhs.severity
}
