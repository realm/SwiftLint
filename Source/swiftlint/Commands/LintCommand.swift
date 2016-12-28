//
//  LintCommand.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

extension Reporter {
    static func reportViolations(_ violations: [StyleViolation], realtimeCondition: Bool) {
        if isRealtime == realtimeCondition {
            let report = generateReport(violations)
            if !report.isEmpty {
                queuedPrint(report)
            }
        }
    }
}

#if os(Linux)
private func autoreleasepool(block: () -> Void) { block() }
#endif

struct LintCommand: CommandProtocol {
    let verb = "lint"
    let function = "Print lint warnings and errors (default command)"

    func run(_ options: LintOptions) -> Result<(), CommandantError<()>> {
        var fileBenchmark = Benchmark(name: "files")
        var ruleBenchmark = Benchmark(name: "rules")
        var violations = [StyleViolation]()
        let configuration = Configuration(commandLinePath: options.configurationFile,
                                          rootPath: options.path, quiet: options.quiet)
        let reporter = makeReporter(options: options, configuration: configuration)
        let cache = makeCache(options: options, configuration: configuration)

        return configuration.visitLintableFiles(options.path, action: "Linting",
            useSTDIN: options.useSTDIN, quiet: options.quiet,
            useScriptInputFiles: options.useScriptInputFiles, cache: cache) { linter in
            var currentViolations = [StyleViolation]()
            autoreleasepool {
                if options.benchmark {
                    let start = Date()
                    let (_currentViolations, currentRuleTimes) = linter.styleViolationsAndRuleTimes
                    currentViolations = _currentViolations
                    fileBenchmark.record(file: linter.file, from: start)
                    currentRuleTimes.forEach { ruleBenchmark.record(id: $0, time: $1) }
                } else {
                    currentViolations = linter.styleViolations
                }
                linter.file.invalidateCache()
            }
            violations += currentViolations
            reporter.reportViolations(currentViolations, realtimeCondition: true)
        }.flatMap { files in
            if isWarningThresholdBroken(configuration, violations: violations) {
                violations.append(createThresholdViolation(configuration.warningThreshold!))
                reporter.reportViolations([violations.last!], realtimeCondition: true)
            }
            reporter.reportViolations(violations, realtimeCondition: false)
            let numberOfSeriousViolations = violations.filter({ $0.severity == .error }).count
            if !options.quiet {
                LintCommand.printStatus(violations: violations, files: files, serious: numberOfSeriousViolations)
            }
            if options.benchmark {
                fileBenchmark.save()
                ruleBenchmark.save()
            }

            saveCache(cache: cache, options: options, configuration: configuration)

            if numberOfSeriousViolations > 0 {
                exit(2)
            } else if options.strict && !violations.isEmpty {
                exit(3)
            }
            return .success()
        }
    }

    private func cacheUrl(options: LintOptions, configuration: Configuration) -> URL? {
        guard !options.ignoreCache else {
            return nil
        }
        let path = (options.cachePath.isEmpty ? configuration.cachePath : options.cachePath) ?? ".swiftlint_cache.json"
        return URL(fileURLWithPath: path)
    }

    private func makeCache(options: LintOptions, configuration: Configuration) -> LinterCache? {
        guard let url = cacheUrl(options: options, configuration: configuration) else {
            return nil
        }

        let configurationHash = configuration.hash
        let cache: LinterCache
        do {
            cache = try LinterCache(contentsOf: url, configurationHash: configurationHash)
        } catch {
            cache = LinterCache(configurationHash: configurationHash)
        }

        return cache
    }

    private func saveCache(cache: LinterCache?, options: LintOptions, configuration: Configuration) {
        if let url = cacheUrl(options: options, configuration: configuration) {
            try? cache?.save(to: url)
        }
    }

    private func makeReporter(options: LintOptions, configuration: Configuration) -> Reporter.Type {
        let identifier = options.reporter.isEmpty ? configuration.reporter : options.reporter
        return reporterFromString(identifier)
    }

    static func printStatus(violations: [StyleViolation], files: [File], serious: Int) {
        let violationSuffix = (violations.count != 1 ? "s" : "")
        let fileCount = files.count
        let filesSuffix = (fileCount != 1 ? "s." : ".")
        let message = "Done linting! Found \(violations.count) violation\(violationSuffix), " +
            "\(serious) serious in \(fileCount) file\(filesSuffix)"
        queuedPrintError(message)
    }
}

struct LintOptions: OptionsProtocol {
    let path: String
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool
    let useScriptInputFiles: Bool
    let benchmark: Bool
    let reporter: String
    let quiet: Bool
    let cachePath: String
    let ignoreCache: Bool

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ useSTDIN: Bool) -> (_ configurationFile: String) -> (_ strict: Bool) -> (_ useScriptInputFiles: Bool) -> (_ benchmark: Bool) -> (_ reporter: String) -> (_ quiet: Bool) -> (_ cachePath: String) -> (_ ignoreCache: Bool) -> LintOptions {
        return { useSTDIN in { configurationFile in { strict in { useScriptInputFiles in { benchmark in { reporter in { quiet in { cachePath in { ignoreCache in
            self.init(path: path, useSTDIN: useSTDIN, configurationFile: configurationFile, strict: strict, useScriptInputFiles: useScriptInputFiles, benchmark: benchmark, reporter: reporter, quiet: quiet, cachePath: cachePath, ignoreCache: ignoreCache)
        }}}}}}}}}
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
            <*> mode <| useScriptInputFilesOption
            <*> mode <| Option(key: "benchmark", defaultValue: false,
                               usage: "save benchmarks to benchmark_files.txt " +
                                      "and benchmark_rules.txt")
            <*> mode <| Option(key: "reporter", defaultValue: "",
                               usage: "the reporter used to log errors and warnings")
            <*> mode <| quietOption(action: "linting")
            <*> mode <| Option(key: "cache-path", defaultValue: "",
                               usage: "the cache that should be used when linting")
            <*> mode <| Option(key: "no-cache", defaultValue: false,
                               usage: "ignore cache when linting")
    }
}

private func isWarningThresholdBroken(_ configuration: Configuration,
                                      violations: [StyleViolation]) -> Bool {
    guard let warningThreshold = configuration.warningThreshold else { return false }
    let numberOfWarningViolations = violations.filter({ $0.severity == .warning }).count
    return numberOfWarningViolations >= warningThreshold
}

private func createThresholdViolation(_ threshold: Int) -> StyleViolation {
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
