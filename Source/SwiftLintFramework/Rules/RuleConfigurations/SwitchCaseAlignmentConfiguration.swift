//
//  SwitchCaseAlignmentRuleConfiguration.swift
//  SwiftLint
//
//  Created by Shai Mishali on 4/23/18.
//  Copyright © 2018 Realm. All rights reserved.
//

public struct SwitchCaseAlignmentConfiguration: RuleConfiguration, Equatable {
    private(set) var severityConfiguration = SeverityConfiguration(.warning)
    private(set) var indentation: Int = 0

    init() {}

    public var consoleDescription: String {
        return severityConfiguration.consoleDescription + ", indentation: \(indentation)"
    }

    public mutating func apply(configuration: Any) throws {
        guard let configuration = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        self.indentation = configuration["indentation"] as? Int ?? 0
    }

    public static func == (lhs: SwitchCaseAlignmentConfiguration,
                           rhs: SwitchCaseAlignmentConfiguration) -> Bool {
        return lhs.indentation == rhs.indentation &&
               lhs.severityConfiguration == rhs.severityConfiguration
    }
}
