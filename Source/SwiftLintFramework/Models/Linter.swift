//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

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
            queuedPrintError("Most of rules are skipped because sourcekitd fails.")
        }
        let regions = file.regions()
        var ruleTimes = [(id: String, time: Double)]()
        let violations = rules.flatMap { rule -> [StyleViolation] in
            if !(rule is SourceKitFreeRule) && file.sourcekitdFailed {
                return []
            }
            let start: Date! = benchmark ? Date() : nil
            let violations = rule.validateFile(file)
            if benchmark {
                let id = type(of: rule).description.identifier
                ruleTimes.append((id, -start.timeIntervalSinceNow))
            }
            return violations.filter { violation in
                guard let violationRegion = regions
                    .first(where: { $0.contains(violation.location) }) else {
                        return true
                }
                return violationRegion.isRuleEnabled(rule)
            }
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
