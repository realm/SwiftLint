//
//  ColonConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/18/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct ColonConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var flexibleRightSpacing = false
    private(set) var applyToDictionaries = true

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription +
            ", flexible_right_spacing: \(flexibleRightSpacing)" +
            ", apply_to_dictionaries: \(applyToDictionaries)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        flexibleRightSpacing = configuration["flexible_right_spacing"] as? Bool == true
        applyToDictionaries = configuration["apply_to_dictionaries"] as? Bool ?? true

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }
    }

    public static func == (lhs: ColonConfiguration,
                           rhs: ColonConfiguration) -> Bool {
        return lhs.severityConfiguration == rhs.severityConfiguration &&
            lhs.flexibleRightSpacing == rhs.flexibleRightSpacing &&
            lhs.applyToDictionaries == rhs.applyToDictionaries
    }
}
