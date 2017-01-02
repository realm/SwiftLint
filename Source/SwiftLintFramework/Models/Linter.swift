//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Dispatch
import Foundation
import SourceKittenFramework

private struct LintResult {
    let violations: [StyleViolation]
    let ruleTime: (id: String, time: Double)?
    let deprecatedToValidIdentifier: [(String, String)]
}

public struct Linter {
    public let file: File
    fileprivate let rules: [Rule]

    public var styleViolations: [StyleViolation] {
        return getStyleViolations().0
    }

    public var styleViolationsAndRuleTimes: ([StyleViolation], [(id: String, time: Double)]) {
        return getStyleViolations(true)
    }

    private func getStyleViolations(_ benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)]) {
        if file.sourcekitdFailed {
            queuedPrintError("Most rules will be skipped because sourcekitd has failed.")
        }
        let regions = file.regions()

        let result = rules.parallelFlatMap { rule -> LintResult? in
            if !(rule is SourceKitFreeRule) && self.file.sourcekitdFailed {
                return nil
            }

            let violations: [StyleViolation]
            let benchmarkValue: (String, Double)?
            if benchmark {
                let start = Date()
                violations = rule.validateFile(self.file)
                let id = type(of: rule).description.identifier
                benchmarkValue = (id, -start.timeIntervalSinceNow)
            } else {
                violations = rule.validateFile(self.file)
                benchmarkValue = nil
            }

            let violationsAndRegions = violations.map { violation in
                return (violation, regions.first(where: { $0.contains(violation.location) }))
            }

            let (disabledViolationsAndRegions, enabledViolations) = violationsAndRegions.partitioned { _, region in
                return region?.isRuleEnabled(rule) ?? true
            }

            let deprecatedToValidIdentifier = disabledViolationsAndRegions.flatMap { _, region -> [(String, String)] in
                let identifiers = region?.deprecatedAliasesDisablingRule(rule) ?? []
                return identifiers.map { ($0, type(of: rule).description.identifier) }
            }

            return LintResult(violations: enabledViolations.map { $0.0 }, ruleTime: benchmarkValue,
                              deprecatedToValidIdentifier: deprecatedToValidIdentifier)
        }

        let violations = result.flatMap { subResult in
            return subResult.violations
        }
        let ruleTimes = result.flatMap { subResult in
            return subResult.ruleTime
        }

        var deprecatedToValidIdentifier = [String: String]()
        for (key, value) in result.flatMap({ $0.deprecatedToValidIdentifier }) {
            deprecatedToValidIdentifier[key] = value
        }

        for (deprecatedIdentifier, identifier) in deprecatedToValidIdentifier {
            queuedPrintError("'\(deprecatedIdentifier)' rule has been renamed to '\(identifier)' and will be " +
                "completely removed in a future release.")
        }

        return (violations, ruleTimes)
    }

    public init(file: File, configuration: Configuration = Configuration()!) {
        self.file = file
        rules = configuration.rules
    }

    public func correct() -> [Correction] {
        var corrections = [Correction]()
        for rule in rules.flatMap({ $0 as? CorrectableRule }) {
            let newCorrections = rule.correctFile(file)
            corrections += newCorrections
            if !newCorrections.isEmpty {
                file.invalidateCache()
            }
        }
        return corrections
    }
}
