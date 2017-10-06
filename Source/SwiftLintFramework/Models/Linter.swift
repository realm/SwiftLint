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
    let deprecatedToValidIDPairs: [(String, String)]
}

private extension Rule {
    static func superfluousDisableCommandViolations(regions: [Region],
                                                    superfluousDisableCommandRule: SuperfluousDisableCommandRule?,
                                                    allViolations: [StyleViolation]) -> [StyleViolation] {
        guard !regions.isEmpty, let superfluousDisableCommandRule = superfluousDisableCommandRule else {
            return []
        }

        let regionsDisablingCurrentRule = regions.filter { region in
            return region.isRuleDisabled(self.init())
        }
        let regionsDisablingSuperflousDisableRule = regions.filter { region in
            return region.isRuleDisabled(superfluousDisableCommandRule)
        }

        return regionsDisablingCurrentRule.flatMap { region -> StyleViolation? in
            let isSuperflousRuleDisabled = regionsDisablingSuperflousDisableRule.contains { $0.contains(region.start) }
            guard !isSuperflousRuleDisabled else {
                return nil
            }

            let noViolationsInDisabledRegion = !allViolations.contains { violation in
                return region.contains(violation.location)
            }
            guard noViolationsInDisabledRegion else {
                return nil
            }

            return StyleViolation(
                ruleDescription: type(of: superfluousDisableCommandRule).description,
                severity: superfluousDisableCommandRule.configuration.severity,
                location: region.start,
                reason: superfluousDisableCommandRule.reason(for: self)
            )
        }
    }

    func lint(file: File, regions: [Region], benchmark: Bool,
              superfluousDisableCommandRule: SuperfluousDisableCommandRule?) -> LintResult? {
        if !(self is SourceKitFreeRule) && file.sourcekitdFailed {
            return nil
        }

        let ruleID = Self.description.identifier

        let violations: [StyleViolation]
        let ruleTime: (String, Double)?
        if benchmark {
            let start = Date()
            violations = validate(file: file)
            ruleTime = (ruleID, -start.timeIntervalSinceNow)
        } else {
            violations = validate(file: file)
            ruleTime = nil
        }

        let (disabledViolationsAndRegions, enabledViolationsAndRegions) = violations.map { violation in
            return (violation, regions.first { $0.contains(violation.location) })
        }.partitioned { _, region in
            return region?.isRuleEnabled(self) ?? true
        }

        let ruleIDs = Self.description.allIdentifiers +
            (superfluousDisableCommandRule.map({ type(of: $0) })?.description.allIdentifiers ?? [])

        let superfluousDisableCommandViolations = Self.superfluousDisableCommandViolations(
            regions: regions.count > 1 ? file.regions(restrictingRuleIdentifiers: ruleIDs) : regions,
            superfluousDisableCommandRule: superfluousDisableCommandRule,
            allViolations: violations
        )

        let enabledViolations: [StyleViolation]
        if file.contents.hasPrefix("#!") { // if a violation happens on the same line as a shebang, ignore it
            enabledViolations = enabledViolationsAndRegions.flatMap { violation, _ in
                if violation.location.line == 1 { return nil }
                return violation
            }
        } else {
            enabledViolations = enabledViolationsAndRegions.map { $0.0 }
        }
        let deprecatedToValidIDPairs = disabledViolationsAndRegions.flatMap { _, region -> [(String, String)] in
            let identifiers = region?.deprecatedAliasesDisabling(rule: self) ?? []
            return identifiers.map { ($0, ruleID) }
        }

        return LintResult(violations: enabledViolations + superfluousDisableCommandViolations, ruleTime: ruleTime,
                          deprecatedToValidIDPairs: deprecatedToValidIDPairs)
    }
}

public struct Linter {
    public let file: File
    private let rules: [Rule]
    private let cache: LinterCache?
    private let configuration: Configuration

    public var styleViolations: [StyleViolation] {
        return getStyleViolations().0
    }

    public var styleViolationsAndRuleTimes: ([StyleViolation], [(id: String, time: Double)]) {
        return getStyleViolations(benchmark: true)
    }

    private func getStyleViolations(benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)]) {

        if let cached = cachedStyleViolations(benchmark: benchmark) {
            return cached
        }

        if file.sourcekitdFailed {
            queuedPrintError("Most rules will be skipped because sourcekitd has failed.")
        }
        let regions = file.regions()
        let superfluousDisableCommandRule = rules.first(where: {
            $0 is SuperfluousDisableCommandRule
        }) as? SuperfluousDisableCommandRule
        let validationResults = rules.parallelFlatMap {
            $0.lint(file: self.file, regions: regions, benchmark: benchmark,
                    superfluousDisableCommandRule: superfluousDisableCommandRule)
        }
        let violations = validationResults.flatMap { $0.violations }
        let ruleTimes = validationResults.flatMap { $0.ruleTime }
        var deprecatedToValidIdentifier = [String: String]()
        for (key, value) in validationResults.flatMap({ $0.deprecatedToValidIDPairs }) {
            deprecatedToValidIdentifier[key] = value
        }

        if let cache = cache, let path = file.path {
            cache.cache(violations: violations, forFile: path, configuration: configuration)
        }

        for (deprecatedIdentifier, identifier) in deprecatedToValidIdentifier {
            queuedPrintError("'\(deprecatedIdentifier)' rule has been renamed to '\(identifier)' and will be " +
                "completely removed in a future release.")
        }

        return (violations, ruleTimes)
    }

    private func cachedStyleViolations(benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)])? {
        let start: Date! = benchmark ? Date() : nil
        guard let cache = cache, let file = file.path,
            let cachedViolations = cache.violations(forFile: file, configuration: configuration) else {
            return nil
        }

        var ruleTimes = [(id: String, time: Double)]()
        if benchmark {
            // let's assume that all rules should have the same duration and split the duration among them
            let totalTime = -start.timeIntervalSinceNow
            let fractionedTime = totalTime / TimeInterval(rules.count)
            ruleTimes = rules.flatMap { rule in
                let id = type(of: rule).description.identifier
                return (id, fractionedTime)
            }
        }

        return (cachedViolations, ruleTimes)
    }

    public init(file: File, configuration: Configuration = Configuration()!, cache: LinterCache? = nil) {
        self.file = file
        self.cache = cache
        self.configuration = configuration
        rules = configuration.rules
    }

    public func correct() -> [Correction] {
        if let violations = cachedStyleViolations()?.0, violations.isEmpty {
            return []
        }

        var corrections = [Correction]()
        for rule in rules.flatMap({ $0 as? CorrectableRule }) {
            let newCorrections = rule.correct(file: file)
            corrections += newCorrections
            if !newCorrections.isEmpty {
                file.invalidateCache()
            }
        }
        return corrections
    }
}
