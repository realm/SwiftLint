//
//  LintCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Commandant
import Dispatch
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

struct LintCommand: CommandProtocol {
    let verb = "lint"
    let function = "Print lint warnings and errors (default command)"

    func run(_ options: LintOptions) -> Result<(), CommandantError<()>> {
        var fileBenchmark = Benchmark(name: "files")
        var ruleBenchmark = Benchmark(name: "rules")
        var violations = [StyleViolation]()
        let configuration = Configuration(options: options)
        let reporter = reporterFrom(options: options, configuration: configuration)
        let cache = options.ignoreCache ? nil : LinterCache(configuration: configuration)
        let visitorMutationQueue = DispatchQueue(label: "io.realm.swiftlint.lintVisitorMutation")
        return configuration.visitLintableFiles(options: options, cache: cache) { linter in
            let currentViolations: [StyleViolation]
            if options.benchmark {
                let start = Date()
                let (_currentViolations, currentRuleTimes) = linter.styleViolationsAndRuleTimes
                currentViolations = LintCommand.applyLeniency(options: options, violations: _currentViolations)
                visitorMutationQueue.sync {
                    fileBenchmark.record(file: linter.file, from: start)
                    currentRuleTimes.forEach { ruleBenchmark.record(id: $0, time: $1) }
                    violations += currentViolations
                }
            } else {
                currentViolations = LintCommand.applyLeniency(options: options, violations: linter.styleViolations)
                visitorMutationQueue.sync {
                    violations += currentViolations
                }
            }
            linter.file.invalidateCache()
            reporter.report(violations: currentViolations, realtimeCondition: true)
        }.flatMap { files in
            if LintCommand.isWarningThresholdBroken(configuration: configuration, violations: violations)
                && !options.lenient {
                violations.append(LintCommand.createThresholdViolation(threshold: configuration.warningThreshold!))
                reporter.report(violations: [violations.last!], realtimeCondition: true)
            }
            reporter.report(violations: violations, realtimeCondition: false)
            let numberOfSeriousViolations = violations.filter({ $0.severity == .error }).count
            if !options.quiet {
                LintCommand.printStatus(violations: violations, files: files,
                                        serious: numberOfSeriousViolations)
            }
            if options.benchmark {
                fileBenchmark.save()
                ruleBenchmark.save()
            }
            try? cache?.save()
            return LintCommand.successOrExit(numberOfSeriousViolations: numberOfSeriousViolations,
                                             strictWithViolations: options.strict && !violations.isEmpty)
        }
    }

    private static func successOrExit(numberOfSeriousViolations: Int,
                                      strictWithViolations: Bool) -> Result<(), CommandantError<()>> {
        if numberOfSeriousViolations > 0 {
            exit(2)
        } else if strictWithViolations {
            exit(3)
        }
        return .success()
    }

    private static func printStatus(violations: [StyleViolation], files: [File], serious: Int) {
        let pluralSuffix = { (collection: [Any]) -> String in
            return collection.count != 1 ? "s" : ""
        }
        queuedPrintError(
            "Done linting! Found \(violations.count) violation\(pluralSuffix(violations)), " +
            "\(serious) serious in \(files.count) file\(pluralSuffix(files))."
        )
    }

    private static func isWarningThresholdBroken(configuration: Configuration,
                                                 violations: [StyleViolation]) -> Bool {
        guard let warningThreshold = configuration.warningThreshold else { return false }
        let numberOfWarningViolations = violations.filter({ $0.severity == .warning }).count
        return numberOfWarningViolations >= warningThreshold
    }

    private static func createThresholdViolation(threshold: Int) -> StyleViolation {
        let description = RuleDescription(
            identifier: "warning_threshold",
            name: "Warning Threshold",
            description: "Number of warnings thrown is above the threshold."
        )
        return StyleViolation(
            ruleDescription: description,
            severity: .error,
            location: Location(file: "", line: 0, character: 0),
            reason: "Number of warnings exceeded threshold of \(threshold).")
    }

    private static func applyLeniency(options: LintOptions, violations: [StyleViolation]) -> [StyleViolation] {
        if !options.lenient {
            return violations
        }
        return violations.map {
            if $0.severity == .error {
                return StyleViolation(ruleDescription: $0.ruleDescription,
                                      severity: .warning,
                                      location: $0.location,
                                      reason: $0.reason)
            } else {
                return $0
            }
        }
    }
}

struct LintOptions: OptionsProtocol {
    let path: String
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool
    let lenient: Bool
    let useScriptInputFiles: Bool
    let benchmark: Bool
    let reporter: String
    let quiet: Bool
    let cachePath: String
    let ignoreCache: Bool
    let enableAllRules: Bool

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ useSTDIN: Bool) -> (_ configurationFile: String) -> (_ strict: Bool) -> (_ lenient: Bool) -> (_ useScriptInputFiles: Bool) -> (_ benchmark: Bool) -> (_ reporter: String) -> (_ quiet: Bool) -> (_ cachePath: String) -> (_ ignoreCache: Bool) -> (_ enableAllRules: Bool) -> LintOptions {
        return { useSTDIN in { configurationFile in { strict in { lenient in { useScriptInputFiles in { benchmark in { reporter in { quiet in { cachePath in { ignoreCache in { enableAllRules in
            self.init(path: path, useSTDIN: useSTDIN, configurationFile: configurationFile, strict: strict, lenient: lenient, useScriptInputFiles: useScriptInputFiles, benchmark: benchmark, reporter: reporter, quiet: quiet, cachePath: cachePath, ignoreCache: ignoreCache, enableAllRules: enableAllRules)
        }}}}}}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<LintOptions, CommandantError<CommandantError<()>>> {
        // swiftlint:enable line_length
        return create
            <*> mode <| pathOption(action: "lint")
            <*> mode <| Option(key: "use-stdin", defaultValue: false,
                               usage: "lint standard input")
            <*> mode <| configOption
            <*> mode <| Option(key: "strict", defaultValue: false,
                               usage: "fail on warnings")
            <*> mode <| Option(key: "lenient", defaultValue: false,
                               usage: "downgrades serious violations to warnings, warning threshold is disabled")
            <*> mode <| useScriptInputFilesOption
            <*> mode <| Option(key: "benchmark", defaultValue: false,
                               usage: "save benchmarks to benchmark_files.txt " +
                                      "and benchmark_rules.txt")
            <*> mode <| Option(key: "reporter", defaultValue: "",
                               usage: "the reporter used to log errors and warnings")
            <*> mode <| quietOption(action: "linting")
            <*> mode <| Option(key: "cache-path", defaultValue: "",
                               usage: "the directory of the cache used when linting")
            <*> mode <| Option(key: "no-cache", defaultValue: false,
                               usage: "ignore cache when linting")
            <*> mode <| Option(key: "enable-all-rules", defaultValue: false,
                               usage: "run all rules, even opt-in and disabled ones, ignoring `whitelist_rules`")
    }
}
