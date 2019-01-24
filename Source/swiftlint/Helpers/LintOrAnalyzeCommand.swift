import Commandant
import Dispatch
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

enum LintOrAnalyzeMode {
    case lint, analyze

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
    private static var fileBenchmark = Benchmark(name: "files")
    private static var ruleBenchmark = Benchmark(name: "rules")
    private static let visitorMutationQueue = DispatchQueue(label: "io.realm.swiftlint.lintVisitorMutation")

    static func run(_ options: LintOrAnalyzeOptions) -> Result<(), CommandantError<()>> {
        var violations = [StyleViolation]()
        let configuration = Configuration(options: options)
        let reporter = reporterFrom(optionsReporter: options.reporter, configuration: configuration)
        let cache = options.ignoreCache ? nil : LinterCache(configuration: configuration)
        let baseline = prepareBaseline(options: options, configuration: configuration)

        return configuration.visitLintableFiles(options: options, cache: cache) { linter in
            let currentViolations = preperaViolations(
                linter: linter,
                options: options,
                baseline: baseline
            )
            visitorMutationQueue.sync {
                violations += currentViolations
            }
            linter.file.invalidateCache()
            reporter.report(violations: currentViolations, realtimeCondition: true)
        }.flatMap { files in
            if isWarningThresholdBroken(configuration: configuration, violations: violations)
                && !options.lenient {
                violations.append(createThresholdViolation(threshold: configuration.warningThreshold!))
                reporter.report(violations: [violations.last!], realtimeCondition: true)
            }
            reporter.report(violations: violations, realtimeCondition: false)
            let numberOfSeriousViolations = violations.filter({ $0.severity == .error }).count
            if !options.quiet {
                printStatus(violations: violations, files: files, serious: numberOfSeriousViolations,
                            verb: options.verb)
            }
            if options.benchmark {
                fileBenchmark.save()
                ruleBenchmark.save()
            }
            if options.useBaseline {
                baseline.saveBaseline(violations: violations)
            }
            try? cache?.save()
            return successOrExit(numberOfSeriousViolations: numberOfSeriousViolations,
                                 strictWithViolations: options.strict && !violations.isEmpty)
        }
    }

    private static func preperaViolations(linter: Linter,
                                          options: LintOrAnalyzeOptions,
                                          baseline: Baseline) -> [StyleViolation] {
        var currentViolations: [StyleViolation]
        if options.benchmark {
            let start = Date()
            let (violationsBeforeLeniency, currentRuleTimes) = linter.styleViolationsAndRuleTimes
            currentViolations = applyLeniency(options: options, violations: violationsBeforeLeniency)
            currentViolations = applyBaseline(baseline: baseline, options: options, violations: currentViolations)
            visitorMutationQueue.sync {
                fileBenchmark.record(file: linter.file, from: start)
                currentRuleTimes.forEach { ruleBenchmark.record(id: $0, time: $1) }
            }
            return currentViolations
        } else {
            currentViolations = applyLeniency(options: options, violations: linter.styleViolations)
            currentViolations = applyBaseline(baseline: baseline, options: options, violations: currentViolations)
            return currentViolations
        }
    }

    private static func prepareBaseline(options: LintOrAnalyzeOptions, configuration: Configuration) -> Baseline {
        let rootPath = configuration.rootPath ?? ""
        let baseline = Baseline(rootPath: rootPath)
        baseline.readBaseline()
        return baseline
    }

    private static func applyBaseline(baseline: Baseline,
                                      options: LintOrAnalyzeOptions,
                                      violations: [StyleViolation]) -> [StyleViolation] {
        guard options.useBaseline else {
            return violations
        }

        var filteredViolations = [StyleViolation]()
        for violation in violations {
            if !baseline.isInBaseline(violation: violation) {
                filteredViolations.append(violation)
            }
        }
        return filteredViolations
    }

    private static func successOrExit(numberOfSeriousViolations: Int,
                                      strictWithViolations: Bool) -> Result<(), CommandantError<()>> {
        if numberOfSeriousViolations > 0 {
            exit(2)
        } else if strictWithViolations {
            exit(3)
        }
        return .success(())
    }

    private static func printStatus(violations: [StyleViolation], files: [File], serious: Int, verb: String) {
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

struct LintOrAnalyzeOptions {
    let mode: LintOrAnalyzeMode
    let paths: [String]
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool
    let lenient: Bool
    let forceExclude: Bool
    let useScriptInputFiles: Bool
    let benchmark: Bool
    let reporter: String
    let quiet: Bool
    let cachePath: String
    let ignoreCache: Bool
    let enableAllRules: Bool
    let useBaseline: Bool
    let autocorrect: Bool
    let compilerLogPath: String

    init(_ options: LintOptions) {
        mode = .lint
        paths = options.paths
        useSTDIN = options.useSTDIN
        configurationFile = options.configurationFile
        strict = options.strict
        lenient = options.lenient
        forceExclude = options.forceExclude
        useScriptInputFiles = options.useScriptInputFiles
        benchmark = options.benchmark
        reporter = options.reporter
        quiet = options.quiet
        cachePath = options.cachePath
        ignoreCache = options.ignoreCache
        enableAllRules = options.enableAllRules
        useBaseline = options.useBaseline
        autocorrect = false
        compilerLogPath = ""
    }

    init(_ options: AnalyzeOptions) {
        mode = .analyze
        paths = options.paths
        useSTDIN = false
        configurationFile = options.configurationFile
        strict = options.strict
        lenient = options.lenient
        forceExclude = options.forceExclude
        useScriptInputFiles = options.useScriptInputFiles
        benchmark = options.benchmark
        reporter = options.reporter
        quiet = options.quiet
        cachePath = ""
        ignoreCache = true
        enableAllRules = options.enableAllRules
        useBaseline = false
        autocorrect = options.autocorrect
        compilerLogPath = options.compilerLogPath
    }

    var verb: String {
        if autocorrect {
            return "correcting"
        } else {
            return mode.verb
        }
    }
}
