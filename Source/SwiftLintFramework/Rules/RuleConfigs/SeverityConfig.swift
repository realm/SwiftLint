//
//  SeverityConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityConfig: RuleConfig, Equatable {
    var severity: ViolationSeverity

    public init(_ severity: ViolationSeverity) {
        self.severity = severity
    }

    public mutating func setConfig(config: AnyObject) throws {
        guard
            // swiftlint:disable:next line_length
            let value = config as? String ?? (config as? [String: AnyObject])?["severity"] as? String,
            let severity = severity(fromString: value) else {
                throw ConfigurationError.UnknownConfiguration
        }
        self.severity = severity
    }

    private func severity(fromString string: String) -> ViolationSeverity? {
        return ViolationSeverity(rawValue: string.lowercaseString.capitalizedString)
    }
}

public func == (lhs: SeverityConfig, rhs: SeverityConfig) -> Bool {
    return lhs.severity == rhs.severity
}
