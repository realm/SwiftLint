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
    private let rules: [Rule]
    private let cache: LinterCache?

    public var styleViolations: [StyleViolation] {
        return getStyleViolations().0
    }

    public var styleViolationsAndRuleTimes: ([StyleViolation], [(id: String, time: Double)]) {
        return getStyleViolations(true)
    }

    private func getStyleViolations(_ benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)]) {

        if let cached = cachedStyleViolations(benchmark) {
            return cached
        }

        if file.sourcekitdFailed {
            queuedPrintError("Most rules will be skipped because sourcekitd has failed.")
        }
        let regions = file.regions()
        var ruleTimes = [(id: String, time: Double)]()
        let mutationQueue: DispatchQueue! = benchmark ?
            DispatchQueue(label: "io.realm.SwiftLintFramework.getStyleViolationsMutation")
            : nil
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
                return violationRegion.isRuleEnabled(rule)
            }
        }

        if let cache = cache, let file = file.path {
            let hash = self.file.contents.hash
            cache.cacheFile(file, violations: violations, hash: hash)
        }

        return (violations, ruleTimes)
    }

    private func cachedStyleViolations(_ benchmark: Bool = false) -> ([StyleViolation], [(id: String, time: Double)])? {
        let start: Date! = benchmark ? Date() : nil
        guard let cache = cache,
            let file = file.path,
            case let hash = self.file.contents.hash,
            let cachedViolations = cache.violations(for: file, hash: hash) else {
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

    public init(file: File,
                configuration: Configuration = Configuration()!,
                cache: LinterCache? = nil) {
        self.file = file
        self.cache = cache
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
