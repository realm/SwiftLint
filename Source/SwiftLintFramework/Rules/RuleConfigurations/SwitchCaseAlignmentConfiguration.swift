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

    public var ruleDescription: RuleDescription {
        let examples = SwitchCaseAlignmentRule.Examples(indentedCases: indentedCases)

        let reason = indentedCases ? "Case statements should be indented within their enclosing switch statement"
                                   : "Case statements should vertically align with their enclosing switch statement"

        return RuleDescription(identifier: "switch_case_alignment",
                               name: "Switch and Case Statement Alignment",
                               description: reason,
                               kind: .style,
                               nonTriggeringExamples: examples.nonTriggeringExamples,
                               triggeringExamples: examples.triggeringExamples)
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
