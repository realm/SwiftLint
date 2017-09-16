//
//  ImplicitlyUnwrappedOptionalConfiguration.swift
//  SwiftLint
//
//  Created by Siarhei Fedartsou on 18/03/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

// swiftlint:disable:next type_name
public enum ImplicitlyUnwrappedOptionalModeConfiguration: String, YamlLoadable {
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
    private(set) var modeParameter: Parameter<ImplicitlyUnwrappedOptionalModeConfiguration>
    private(set) var severityParameter: Parameter<ViolationSeverity>

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var mode: ImplicitlyUnwrappedOptionalModeConfiguration {
        return modeParameter.value
    }

    init(mode: ImplicitlyUnwrappedOptionalModeConfiguration, severity: ViolationSeverity) {
        modeParameter = Parameter(key: "mode",
                                  default: mode,
                                  description: "How serious")
        severityParameter = SeverityConfiguration(severity).severityParameter
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try modeParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: ImplicitlyUnwrappedOptionalConfiguration,
                           rhs: ImplicitlyUnwrappedOptionalConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.mode == rhs.mode
    }
}
