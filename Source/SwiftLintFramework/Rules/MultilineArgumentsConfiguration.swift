//
//  MultilineArgumentsConfiguration.swift
//  SwiftLint
//
//  Created by Marcel Jackwerth on 9/29/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

private enum ConfigurationKey: String {
    case firstArgumentLocation = "first_argument_location"
}

public struct MultilineArgumentsConfiguration: RuleConfiguration, Equatable {
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

    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var firstArgumentLocation = FirstArgumentLocation.anyLine

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", \(ConfigurationKey.firstArgumentLocation.rawValue): \(firstArgumentLocation.rawValue)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let modeString = configuration[ConfigurationKey.firstArgumentLocation.rawValue] {
            try firstArgumentLocation = FirstArgumentLocation(value: modeString)
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static func == (lhs: MultilineArgumentsConfiguration,
                           rhs: MultilineArgumentsConfiguration) -> Bool {
        return lhs.severityConfiguration == rhs.severityConfiguration &&
            lhs.firstArgumentLocation == rhs.firstArgumentLocation
    }
}
