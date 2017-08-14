//
//  PrivateOverFilePrivateRuleConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct PrivateOverFilePrivateRuleConfiguration: RuleConfiguration, Equatable {
    public var severityConfiguration = SeverityConfiguration(.warning)
    public var validateExtensions = false

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", validate_extensions: \(validateExtensions)"
    }

    // MARK: - RuleConfiguration

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let severityString = configuration["severity"] as? String {
            try severityConfiguration.apply(configuration: severityString)
        }

        validateExtensions = configuration["validate_extensions"] as? Bool ?? false
    }

    // MARK: - Equatable

    public static func == (lhs: PrivateOverFilePrivateRuleConfiguration,
                           rhs: PrivateOverFilePrivateRuleConfiguration) -> Bool {
        return lhs.validateExtensions == rhs.validateExtensions &&
            lhs.severityConfiguration == rhs.severityConfiguration
    }
}
