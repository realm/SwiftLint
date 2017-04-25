//
//  ImplicitlyUnwrappedOptionalConfiguration.swift
//  SwiftLint
//
//  Created by Siarhei Fedartsou on 18/03/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

// swiftlint:disable:next type_name
public enum ImplicitlyUnwrappedOptionalModeConfiguration: String {
    case all = "all"
    case allExceptIBOutlets = "all_except_iboutlets"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = ImplicitlyUnwrappedOptionalModeConfiguration(rawValue: string) {
            self = value
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }
}

public struct ImplicitlyUnwrappedOptionalConfiguration: RuleConfiguration, Equatable {
    private(set) var severity: SeverityConfiguration
    private(set) var mode: ImplicitlyUnwrappedOptionalModeConfiguration

    init(mode: ImplicitlyUnwrappedOptionalModeConfiguration, severity: SeverityConfiguration) {
        self.mode = mode
        self.severity = severity
    }

    public var consoleDescription: String {
        return severity.consoleDescription +
            ", mode: \(mode)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let modeString = configuration["mode"] {
            try mode = ImplicitlyUnwrappedOptionalModeConfiguration(value: modeString)
        }

        if let severityString = configuration["severity"] as? String {
            try severity.apply(configuration: severityString)
        }
    }

    public static func == (lhs: ImplicitlyUnwrappedOptionalConfiguration,
                           rhs: ImplicitlyUnwrappedOptionalConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.mode == rhs.mode
    }
}
