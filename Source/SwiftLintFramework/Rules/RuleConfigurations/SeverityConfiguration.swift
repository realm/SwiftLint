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
        return severity.rawValue.lowercaseString
    }

    public var severity: ViolationSeverity

    public init(_ severity: ViolationSeverity) {
        self.severity = severity
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        // swiftlint:disable:next line_length
        guard let value = configuration as? String ?? (configuration as? [String: AnyObject])?["severity"] as? String,
            severity = severity(fromString: value) else {
                throw ConfigurationError.UnknownConfiguration
        }
        self.severity = severity
    }

    private func severity(fromString string: String) -> ViolationSeverity? {
        return ViolationSeverity(rawValue: string.lowercaseString.capitalizedString)
    }
}

public func == (lhs: SeverityConfiguration, rhs: SeverityConfiguration) -> Bool {
    return lhs.severity == rhs.severity
}
