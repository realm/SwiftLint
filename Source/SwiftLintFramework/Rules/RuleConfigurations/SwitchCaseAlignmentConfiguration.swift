//
//  SwitchCaseAlignmentRuleConfiguration.swift
//  SwiftLint
//
//  Created by Shai Mishali on 4/23/18.
//  Copyright © 2018 Realm. All rights reserved.
//

public struct SwitchCaseAlignmentConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var indentedCases = false

    init() {}

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", indented_cases: \(indentedCases)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        self.indentedCases = configuration["indented_cases"] as? Bool ?? false
    }

    public static func == (lhs: SwitchCaseAlignmentConfiguration,
                           rhs: SwitchCaseAlignmentConfiguration) -> Bool {
        return lhs.indentedCases == rhs.indentedCases &&
               lhs.severityConfiguration == rhs.severityConfiguration
    }
}
