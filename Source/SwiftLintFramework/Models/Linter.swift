//
//  Linter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct Linter {
    public let file: File
    private let rules: [Rule]

    public var styleViolations: [StyleViolation] {
        return getStyleViolations().0
    }

    public var styleViolationsAndRuleTimes: ([StyleViolation], [(id: String, time: Double)]) {
        return getStyleViolations(true)
    }

    private func getStyleViolations(benchmark: Bool = false) ->
        ([StyleViolation], [(id: String, time: Double)]) {
        if file.sourcekitdFailed {
            queuedPrintError("Most of rules are skipped because sourcekitd fails.")
        }
        let regions = file.regions()
        var ruleTimes = [(id: String, time: Double)]()
        let violations = rules.flatMap { rule -> [StyleViolation] in
            if !(rule is SourceKitFreeRule) && self.file.sourcekitdFailed {
                return []
            }
            let start: NSDate! = benchmark ? NSDate() : nil
            let violations = rule.validateFile(self.file)
            if benchmark {
                let id = rule.dynamicType.description.identifier
                ruleTimes.append((id, -start.timeIntervalSinceNow))
            }
            return violations.filter { violation in
                guard let violationRegion = regions.filter({ $0.contains(violation.location) })
                    .first else {
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
