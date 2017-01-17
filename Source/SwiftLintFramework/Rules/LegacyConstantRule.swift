//
//  LegacyConstantRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 12/1/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct LegacyConstantRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "legacy_constant",
        name: "Legacy Constant",
        description: "Struct-scoped constants are preferred over legacy global constants.",
        nonTriggeringExamples: LegacyConstantRuleExamples.swift3NonTriggeringExamples,
        triggeringExamples: LegacyConstantRuleExamples.swift3TriggeringExamples,
        corrections: LegacyConstantRuleExamples.swift3Corrections
    )

    private let legacyConstants: [String] = {
        switch SwiftVersion.current {
        case .two:
            return Array(LegacyConstantRuleExamples.swift2Patterns.keys)
        case .three:
            return Array(LegacyConstantRuleExamples.swift3Patterns.keys)
        }
    }()

    private let legacyPatterns: [String: String] = {
        switch SwiftVersion.current {
        case .two:
            return LegacyConstantRuleExamples.swift2Patterns
        case .three:
            return LegacyConstantRuleExamples.swift3Patterns
        }
    }()

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\b(" + legacyConstants.joined(separator: "|") + ")"

        return file.match(pattern: pattern, range: nil)
            .filter { Set($0.1).isSubset(of: [.identifier]) }
            .map { $0.0 }
            .map {
                StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location))
            }
    }

    public func correct(file: File) -> [Correction] {
        return file.correct(legacyRule: self, patterns: legacyPatterns)
    }
}
