//
//  MultilineArgumentsRuleConfiguration.swift
//  SwiftLint
//
//  Created by Marcel Jackwerth on 9/29/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct MultilineArgumentsRuleConfiguration: RuleConfiguration, Equatable {
    public enum FirstArgumentLocation: String {
        case anyLine = "any_line"
        case sameLine = "same_line"
        case nextLine = "next_line"

        init(value: Any) throws {
            guard
                let string = (value as? String)?.lowercased(),
                let value = FirstArgumentLocation(rawValue: string) else {
                    throw ConfigurationError.unknownConfiguration
            }

            self = value
        }
    }

    private(set) var firstArgumentLocation: FirstArgumentLocation
    private(set) var severity: SeverityConfiguration

    init(firstArgumentLocation: FirstArgumentLocation, severity: SeverityConfiguration) {
        self.firstArgumentLocation = firstArgumentLocation
        self.severity = severity
    }

    public var consoleDescription: String {
        return severity.consoleDescription +
        ", first_argument_location: \(firstArgumentLocation)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let modeString = configuration["first_argument_location"] {
            try firstArgumentLocation = FirstArgumentLocation(value: modeString)
        }

        if let severityString = configuration["severity"] as? String {
            try severity.apply(configuration: severityString)
        }
    }

    public static func == (lhs: MultilineArgumentsRuleConfiguration,
                           rhs: MultilineArgumentsRuleConfiguration) -> Bool {
        return lhs.severity == rhs.severity &&
            lhs.firstArgumentLocation == rhs.firstArgumentLocation
    }
}
