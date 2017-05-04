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
        nonTriggeringExamples: LegacyConstantRuleExamples.nonTriggeringExamples,
        triggeringExamples: LegacyConstantRuleExamples.triggeringExamples,
        corrections: LegacyConstantRuleExamples.corrections
    )

    private static let legacyConstants: [String] = {
        return Array(LegacyConstantRule.legacyPatterns.keys)
    }()

    private static let legacyPatterns = LegacyConstantRuleExamples.patterns

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\b" + LegacyConstantRule.legacyConstants.joined(separator: "|")

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
        var wordBoundPatterns: [String: String] = [:]
        LegacyConstantRule.legacyPatterns.forEach { key, value in
            wordBoundPatterns["\\b" + key] = value
        }

        return file.correct(legacyRule: self, patterns: wordBoundPatterns)
    }
}
