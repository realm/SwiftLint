//
//  WarningThresholdRule.swift
//  SwiftLint
//
//  Created by George Woodham on 6/07/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct WarningThresholdRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityLevelsConfiguration(warning: 10, error: 0)

    public init() {}

    public static let description = RuleDescription(
        identifier: "warning_threshold",
        name: "Warning Threshold",
        description: "Number of warnings thrown is above the threshold."
    )

    public func validate(violations: [StyleViolation]) -> [StyleViolation] {
        let value = configuration.params.map({$0.value}).maxElement(<) ?? 10
        var count = 0
        for violation in violations {
            if violation.severity == ViolationSeverity.Warning {
                count += 1
            }
            if count >= value {
                return violations + createError(value)
            }
        }
        return violations
    }

    public func validateFile(file: File) -> [StyleViolation] {
        return []
    }

    func createError(value: Int) -> [StyleViolation] {
        let location = Location(file: "filename", line: 1, character: 2)
        return [StyleViolation(
            ruleDescription: self.dynamicType.description,
            severity: ViolationSeverity.Error,
            location: location,
            reason: "Number of warnings exceeded threshold of \(value)")]
    }
}
