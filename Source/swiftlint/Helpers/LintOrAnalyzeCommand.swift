import Dispatch
import Foundation
@_spi(TestHelper)
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
        ExitHelper.successfullyExit()
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
            builder.report(violations: currentViolations, realtimeCondition: true)
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
            builder.report(violations: [builder.violations.last!], realtimeCondition: true)
        }
        builder.report(violations: builder.violations, realtimeCondition: false)
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
            if !options.quiet, let memoryUsage = memoryUsage() {
                queuedPrintError(memoryUsage)
            }
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
            description: "Number of warnings thrown is above the threshold",
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
        let correctionsBuilder = CorrectionsBuilder()
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
                if !corrections.isEmpty && !options.quiet {
                    if options.useSTDIN {
                        queuedPrint(linter.file.contents)
                    } else {
                        if options.progress {
                            await correctionsBuilder.append(corrections)
                        } else {
                            let correctionLogs = corrections.map(\.consoleDescription)
                            queuedPrint(correctionLogs.joined(separator: "\n"))
                        }
                    }
                }
            }

        if !options.quiet {
            if options.progress {
                let corrections = await correctionsBuilder.corrections
                if !corrections.isEmpty {
                    let correctionLogs = corrections.map(\.consoleDescription)
                    options.writeToOutput(correctionLogs.joined(separator: "\n"))
                }
            }

            let pluralSuffix = { (collection: [Any]) -> String in
                return collection.count != 1 ? "s" : ""
            }
            queuedPrintError("Done correcting \(files.count) file\(pluralSuffix(files))!")
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
    let output: String?
    let progress: Bool
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
        reporter = reporterFrom(identifier: options.reporter ?? config.reporter)
        if options.ignoreCache || ProcessInfo.processInfo.isLikelyXcodeCloudEnvironment {
            cache = nil
        } else {
            cache = LinterCache(configuration: config)
        }
        self.options = options

        if let outFile = options.output {
            do {
                try Data().write(to: URL(fileURLWithPath: outFile))
            } catch {
                queuedPrintError("Could not write to file at path \(outFile)")
            }
        }
    }

    func report(violations: [StyleViolation], realtimeCondition: Bool) {
        if (reporter.isRealtime && (!options.progress || options.output != nil)) == realtimeCondition {
            let report = reporter.generateReport(violations)
            if !report.isEmpty {
                options.writeToOutput(report)
            }
        }
    }
}

private extension LintOrAnalyzeOptions {
    func writeToOutput(_ string: String) {
        guard let outFile = output else {
            queuedPrint(string)
            return
        }

        do {
            let outFileURL = URL(fileURLWithPath: outFile)
            let fileUpdater = try FileHandle(forUpdating: outFileURL)
            fileUpdater.seekToEndOfFile()
            fileUpdater.write(Data((string + "\n").utf8))
            fileUpdater.closeFile()
        } catch {
            queuedPrintError("Could not write to file at path \(outFile)")
        }
    }
}

private actor CorrectionsBuilder {
    private(set) var corrections: [Correction] = []

    func append(_ corrections: [Correction]) {
        self.corrections.append(contentsOf: corrections)
    }
}

private func memoryUsage() -> String? {
#if os(Linux)
    return nil
#else
    var info = mach_task_basic_info()
    let basicInfoCount = MemoryLayout<mach_task_basic_info>.stride / MemoryLayout<natural_t>.stride
    var count = mach_msg_type_number_t(basicInfoCount)

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: basicInfoCount) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
        }
    }

    if kerr == KERN_SUCCESS {
        let bytes = Measurement<UnitInformationStorage>(value: Double(info.resident_size), unit: .bytes)
        let formatted = ByteCountFormatter().string(from: bytes)
        return "Memory used: \(formatted)"
    } else {
        let errorMessage = String(cString: mach_error_string(kerr), encoding: .ascii)
        return "Error with task_info(): \(errorMessage ?? "unknown")"
    }
#endif
}
