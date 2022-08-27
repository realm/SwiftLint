import Dispatch
import Foundation
import SwiftLintFramework

enum LintOrAnalyzeMode {
    case lint, analyze

    var imperative: String {
        switch self {
        case .lint:
            return "lint"
        case .analyze:
            return "analyze"
        }
    }

    var verb: String {
        switch self {
        case .lint:
            return "linting"
        case .analyze:
            return "analyzing"
        }
    }
}

struct LintOrAnalyzeCommand {
    static func run(_ options: LintOrAnalyzeOptions) async throws {
        if options.inProcessSourcekit {
            queuedPrintError(
                """
                warning: The --in-process-sourcekit option is deprecated. \
                SwiftLint now always uses an in-process SourceKit.
                """
            )
        }
        try await Signposts.record(name: "LintOrAnalyzeCommand.run") {
            try await options.autocorrect ? autocorrect(options) : lintOrAnalyze(options)
        }

#if os(Linux)
        // Workaround for https://github.com/realm/SwiftLint/issues/4117
        exit(0)
#endif
    }

    private static func lintOrAnalyze(_ options: LintOrAnalyzeOptions) async throws {
        let builder = LintOrAnalyzeResultBuilder(options)
        let files = try await collectViolations(builder: builder)
        try Signposts.record(name: "LintOrAnalyzeCommand.PostProcessViolations") {
            try postProcessViolations(files: files, builder: builder)
        }
    }

    private static func collectViolations(builder: LintOrAnalyzeResultBuilder) async throws -> [SwiftLintFile] {
        let options = builder.options
        let visitorMutationQueue = DispatchQueue(label: "io.realm.swiftlint.lintVisitorMutation")
        return try await builder.configuration.visitLintableFiles(options: options, cache: builder.cache,
                                                                  storage: builder.storage) { linter in
            let currentViolations: [StyleViolation]
            if options.benchmark {
                CustomRuleTimer.shared.activate()
                let start = Date()
                let (violationsBeforeLeniency, currentRuleTimes) = linter
                    .styleViolationsAndRuleTimes(using: builder.storage)
                currentViolations = applyLeniency(options: options, violations: violationsBeforeLeniency)
                visitorMutationQueue.sync {
                    builder.fileBenchmark.record(file: linter.file, from: start)
                    currentRuleTimes.forEach { builder.ruleBenchmark.record(id: $0, time: $1) }
                    builder.violations += currentViolations
                }
            } else {
                currentViolations = applyLeniency(options: options,
                                                  violations: linter.styleViolations(using: builder.storage))
                visitorMutationQueue.sync {
                    builder.violations += currentViolations
                }
            }
            linter.file.invalidateCache()
            builder.reporter.report(violations: currentViolations, realtimeCondition: true)
        }
    }

    private static func postProcessViolations(files: [SwiftLintFile], builder: LintOrAnalyzeResultBuilder) throws {
        let options = builder.options
        let configuration = builder.configuration
        if isWarningThresholdBroken(configuration: configuration, violations: builder.violations)
            && !options.lenient {
            builder.violations.append(
                createThresholdViolation(threshold: configuration.warningThreshold!)
            )
            builder.reporter.report(violations: [builder.violations.last!], realtimeCondition: true)
        }
        builder.reporter.report(violations: builder.violations, realtimeCondition: false)
        let numberOfSeriousViolations = builder.violations.filter({ $0.severity == .error }).count
        if !options.quiet {
            printStatus(violations: builder.violations, files: files, serious: numberOfSeriousViolations,
                        verb: options.verb)
        }
        if options.benchmark {
            builder.fileBenchmark.save()
            for (id, time) in CustomRuleTimer.shared.dump() {
                builder.ruleBenchmark.record(id: id, time: time)
            }
            builder.ruleBenchmark.save()
        }
        try builder.cache?.save()
        guard numberOfSeriousViolations == 0 else { exit(2) }
    }

    private static func printStatus(violations: [StyleViolation], files: [SwiftLintFile], serious: Int, verb: String) {
        let pluralSuffix = { (collection: [Any]) -> String in
            return collection.count != 1 ? "s" : ""
        }
        queuedPrintError(
            "Done \(verb)! Found \(violations.count) violation\(pluralSuffix(violations)), " +
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
            description: "Number of warnings thrown is above the threshold.",
            kind: .lint
        )
        return StyleViolation(
            ruleDescription: description,
            severity: .error,
            location: Location(file: "", line: 0, character: 0),
            reason: "Number of warnings exceeded threshold of \(threshold).")
    }

    private static func applyLeniency(options: LintOrAnalyzeOptions, violations: [StyleViolation]) -> [StyleViolation] {
        switch (options.lenient, options.strict) {
        case (false, false):
            return violations

        case (true, false):
            return violations.map {
                if $0.severity == .error {
                    return $0.with(severity: .warning)
                } else {
                    return $0
                }
            }

        case (false, true):
            return violations.map {
                if $0.severity == .warning {
                    return $0.with(severity: .error)
                } else {
                    return $0
                }
            }

        case (true, true):
            queuedFatalError("Invalid command line options: 'lenient' and 'strict' are mutually exclusive.")
        }
    }

    private static func autocorrect(_ options: LintOrAnalyzeOptions) async throws {
        let storage = RuleStorage()
        let configuration = Configuration(options: options)
        let files = try await configuration
            .visitLintableFiles(options: options, cache: nil, storage: storage) { linter in
                if options.format {
                    switch configuration.indentation {
                    case .tabs:
                        linter.format(useTabs: true, indentWidth: 4)
                    case .spaces(let count):
                        linter.format(useTabs: false, indentWidth: count)
                    }
                }

                let corrections = linter.correct(using: storage)
                if !corrections.isEmpty && !options.quiet && !options.useSTDIN {
                    let correctionLogs = corrections.map({ $0.consoleDescription })
                    queuedPrint(correctionLogs.joined(separator: "\n"))
                }
            }

        if !options.quiet {
            let pluralSuffix = { (collection: [Any]) -> String in
                return collection.count != 1 ? "s" : ""
            }
            queuedPrintError("Done inspecting \(files.count) file\(pluralSuffix(files)) for auto-correction!")
        }
    }
}

struct LintOrAnalyzeOptions {
    let mode: LintOrAnalyzeMode
    let paths: [String]
    let useSTDIN: Bool
    let configurationFiles: [String]
    let strict: Bool
    let lenient: Bool
    let forceExclude: Bool
    let useExcludingByPrefix: Bool
    let useScriptInputFiles: Bool
    let benchmark: Bool
    let reporter: String?
    let quiet: Bool
    let cachePath: String?
    let ignoreCache: Bool
    let enableAllRules: Bool
    let autocorrect: Bool
    let format: Bool
    let compilerLogPath: String?
    let compileCommands: String?
    let inProcessSourcekit: Bool

    var verb: String {
        if autocorrect {
            return "correcting"
        } else {
            return mode.verb
        }
    }
}

private class LintOrAnalyzeResultBuilder {
    var fileBenchmark = Benchmark(name: "files")
    var ruleBenchmark = Benchmark(name: "rules")
    var violations = [StyleViolation]()
    let storage = RuleStorage()
    let configuration: Configuration
    let reporter: Reporter.Type
    let cache: LinterCache?
    let options: LintOrAnalyzeOptions

    init(_ options: LintOrAnalyzeOptions) {
        let config = Signposts.record(name: "LintOrAnalyzeCommand.ParseConfiguration") {
            Configuration(options: options)
        }
        configuration = config
        reporter = reporterFrom(optionsReporter: options.reporter, configuration: config)
        cache = options.ignoreCache ? nil : LinterCache(configuration: config)
        self.options = options
    }
}
