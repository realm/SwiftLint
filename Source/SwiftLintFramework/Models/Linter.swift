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
        var ruleTimes = [(id: String, time: Double)]()
        let mutationQueue = DispatchQueue(label: "io.realm.SwiftLintFramework.getStyleViolationsMutation")
        var deprecatedIdentifiers = Set<String>()
        var deprecatedToValidIdentifier = [String: String]()

        let violations = rules.parallelFlatMap { rule -> [StyleViolation] in
            if !(rule is SourceKitFreeRule) && self.file.sourcekitdFailed {
                return []
            }
            let start: Date! = benchmark ? Date() : nil
            let violations = rule.validateFile(self.file)
            if benchmark {
                let id = type(of: rule).description.identifier
                mutationQueue.sync {
                    ruleTimes.append((id, -start.timeIntervalSinceNow))
                }
            }

            return violations.filter { violation in
                guard let violationRegion = regions
                    .first(where: { $0.contains(violation.location) }) else {
                        return true
                }
                let enabled = violationRegion.isRuleEnabled(rule)
                if !enabled {
                    let identifiers = violationRegion.deprecatedAliasesDisablingRule(rule)
                    mutationQueue.sync {
                        deprecatedIdentifiers.formUnion(identifiers)
                        for deprecatedIdentifier in identifiers {
                            deprecatedToValidIdentifier[deprecatedIdentifier] = type(of: rule).description.identifier
                        }
                    }
                }

                return enabled
            }
        }

        for deprecatedIdentifier in deprecatedIdentifiers {
            guard let identifier = deprecatedToValidIdentifier[deprecatedIdentifier] else { continue }
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
