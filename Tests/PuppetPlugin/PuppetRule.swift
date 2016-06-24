//
//  PuppetRule.swift
//  SwiftLint
//
//  Created by Sash Zats on 6/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import SourceKittenFramework

public struct PuppetRuleConfiguration: RuleConfiguration, Equatable {
    public var shouldFail: Bool
    public var severity: SeverityConfiguration

    public init(shouldFail: Bool, severity: ViolationSeverity) {
        self.shouldFail = shouldFail
        self.severity = SeverityConfiguration(severity)
    }

    public var consoleDescription: String {
        return "(should_fail) \(shouldFail), (severity) \(severity)"
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configurationDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let value = configurationDict["should_fail"] as? Int {
            self.shouldFail = (value == 1)
        }

        if let rawSeverity = configurationDict["severity"] as? String,
            severity = ViolationSeverity(rawValue: rawSeverity) {
            self.severity = SeverityConfiguration(severity)
        }
    }
}

public func == (lhs: PuppetRuleConfiguration, rhs: PuppetRuleConfiguration) -> Bool {
    return lhs.shouldFail == rhs.shouldFail && lhs.severity == rhs.severity
}

public class PuppetRule: ConfigurationProviderRule {

    public var configuration = PuppetRuleConfiguration(shouldFail: false, severity: .Warning)

    public required init() {}

    public static let description = RuleDescription(
        identifier: "puppet",
        name: "Puppet",
        description: "Puppet rule, set should_fail to true to trigger violation",
        nonTriggeringExamples: [],
        triggeringExamples: []
    )

    public func validateFile(file: File) -> [StyleViolation] {
        guard configuration.shouldFail else {
            return []
        }
        return [
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity.severity,
                location: Location(file: file.path, line: 0),
                reason: "PuppetRule was told to fail")
        ]
    }
}
