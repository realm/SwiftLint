@preconcurrency import Dispatch
import Foundation

// swiftlint:disable file_length

public enum LintOrAnalyzeMode: Sendable {
    case lint, analyze

    public var imperative: String {
        switch self {
        case .lint:
            return "lint"
        case .analyze:
            return "analyze"
        }
    }

    public var verb: String {
        switch self {
        case .lint:
            return "linting"
        case .analyze:
            return "analyzing"
        }
    }
}

public struct LintOrAnalyzeOptions: Sendable {
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
    let baseline: String?
    let writeBaseline: String?
    let workingDirectory: String?
    let quiet: Bool
    let output: String?
    let progress: Bool
    let cachePath: String?
    let ignoreCache: Bool
    let enableAllRules: Bool
    let onlyRule: String?
    let autocorrect: Bool
    let format: Bool
    let compilerLogPath: String?
    let compileCommands: String?
    let checkForUpdates: Bool

    public init(
        mode: LintOrAnalyzeMode,
        paths: [String],
        useSTDIN: Bool,
        configurationFiles: [String],
        strict: Bool,
        lenient: Bool,
        forceExclude: Bool,
        useExcludingByPrefix: Bool,
        useScriptInputFiles: Bool,
        benchmark: Bool,
        reporter: String?,
        baseline: String?,
        writeBaseline: String?,
        workingDirectory: String?,
        quiet: Bool,
        output: String?,
        progress: Bool,
        cachePath: String?,
        ignoreCache: Bool,
        enableAllRules: Bool,
        onlyRule: String?,
        autocorrect: Bool,
        format: Bool,
        compilerLogPath: String?,
        compileCommands: String?,
        checkForUpdates: Bool
    ) {
        self.mode = mode
        self.paths = paths
        self.useSTDIN = useSTDIN
        self.configurationFiles = configurationFiles
        self.strict = strict
        self.lenient = lenient
        self.forceExclude = forceExclude
        self.useExcludingByPrefix = useExcludingByPrefix
        self.useScriptInputFiles = useScriptInputFiles
        self.benchmark = benchmark
        self.reporter = reporter
        self.baseline = baseline
        self.writeBaseline = writeBaseline
        self.workingDirectory = workingDirectory
        self.quiet = quiet
        self.output = output
        self.progress = progress
        self.cachePath = cachePath
        self.ignoreCache = ignoreCache
        self.enableAllRules = enableAllRules
        self.onlyRule = onlyRule
        self.autocorrect = autocorrect
        self.format = format
        self.compilerLogPath = compilerLogPath
        self.compileCommands = compileCommands
        self.checkForUpdates = checkForUpdates
    }

    var verb: String {
        autocorrect ? "correcting" : mode.verb
    }

    var capitalizedVerb: String {
        verb.capitalized
    }
}

public struct LintOrAnalyzeCommand {
    public static func run(_ options: LintOrAnalyzeOptions) async throws {
        if let workingDirectory = options.workingDirectory {
            if !FileManager.default.changeCurrentDirectoryPath(workingDirectory) {
                throw SwiftLintError.usageError(
                    description: """
                        Could not change working directory to '\(workingDirectory)'. \
                        Make sure it exists and is accessible.
                        """
                )
            }
        }
        try await Signposts.record(name: "LintOrAnalyzeCommand.run") { @Sendable in
            try await options.autocorrect ? autocorrect(options) : lintOrAnalyze(options)
        }
        ExitHelper.successfullyExit()
    }

    private static func lintOrAnalyze(_ options: LintOrAnalyzeOptions) async throws {
        let builder = await LintOrAnalyzeResultBuilder(options)
        let files = try await collectViolations(builder: builder)
        if let baselineOutputPath = options.writeBaseline ?? builder.configuration.writeBaseline {
            try await Baseline(violations: builder.unfilteredViolations).write(
                toPath: baselineOutputPath)
        }
        try await Signposts.record(name: "LintOrAnalyzeCommand.PostProcessViolations") {
            @Sendable in
            try await postProcessViolations(files: files, builder: builder)
        }
        if options.checkForUpdates || builder.configuration.checkForUpdates {
            await UpdateChecker.checkForUpdates()
        }
    }

    private static func collectViolations(builder: LintOrAnalyzeResultBuilder) async throws
        -> [SwiftLintFile]
    {
        let options = builder.options
        let baseline = try baseline(options, builder.configuration)
        return try await builder.configuration.visitLintableFiles(
            options: options, cache: builder.cache,
            storage: builder.storage
        ) { linter in
            let currentViolations: [StyleViolation]
            if options.benchmark {
                await CustomRuleTimer.shared.activate()
                let start = Date()
                let (violationsBeforeLeniency, currentRuleTimes) =
                    linter
                    .styleViolationsAndRuleTimes(using: builder.storage)
                currentViolations = applyLeniency(
                    options: options,
                    strict: builder.configuration.strict,
                    violations: violationsBeforeLeniency
                )
                await builder.recordFileBenchmark(file: linter.file, from: start)
                for (id, time) in currentRuleTimes {
                    await builder.recordRuleBenchmark(id: id, time: time)
                }
            } else {
                currentViolations = applyLeniency(
                    options: options,
                    strict: builder.configuration.strict,
                    violations: linter.styleViolations(using: builder.storage)
                )
            }
            let filteredViolations = baseline?.filter(currentViolations) ?? currentViolations
            await builder.addViolations(
                filteredViolations: filteredViolations, unfilteredViolations: currentViolations)

            linter.file.invalidateCache()
            await builder.report(violations: filteredViolations, realtimeCondition: true)
        }
    }

    private static func postProcessViolations(
        files: [SwiftLintFile],
        builder: LintOrAnalyzeResultBuilder
    ) async throws {
        let options = builder.options
        let configuration = builder.configuration
        if await isWarningThresholdBroken(
            configuration: configuration, violations: builder.violations),
            !options.lenient
        {
            await builder.addViolations(
                filteredViolations: [
                    createThresholdViolation(threshold: configuration.warningThreshold!)
                ]
            )
            await builder.report(violations: [builder.violations.last!], realtimeCondition: true)
        }
        await builder.report(violations: builder.violations, realtimeCondition: false)
        let numberOfSeriousViolations = await builder.violations.filter({ $0.severity == .error })
            .count
        if !options.quiet {
            await printStatus(
                violations: builder.violations,
                files: files,
                serious: numberOfSeriousViolations,
                verb: options.verb
            )
        }
        if options.benchmark {
            await builder.fileBenchmark.save()
            for (id, time) in await CustomRuleTimer.shared.dump() {
                await builder.recordRuleBenchmark(id: id, time: time)
            }
            await builder.ruleBenchmark.save()
            if !options.quiet, let memoryUsage = memoryUsage() {
                queuedPrintError(memoryUsage)
            }
        }
        try builder.cache?.save()
        guard numberOfSeriousViolations == 0 else { exit(2) }
    }

    private static func baseline(_ options: LintOrAnalyzeOptions, _ configuration: Configuration)
        throws -> Baseline?
    {
        if let baselinePath = options.baseline ?? configuration.baseline {
            do {
                return try Baseline(fromPath: baselinePath)
            } catch {
                Issue.baselineNotReadable(path: baselinePath).print()
                if (error as? CocoaError)?.code != CocoaError.fileReadNoSuchFile
                    || options.writeBaseline != options.baseline
                {
                    throw error
                }
            }
        }
        return nil
    }

    private static func printStatus(
        violations: [StyleViolation], files: [SwiftLintFile], serious: Int, verb: String
    ) {
        let pluralSuffix = { (collection: [Any]) -> String in
            collection.count != 1 ? "s" : ""
        }
        queuedPrintError(
            "Done \(verb)! Found \(violations.count) violation\(pluralSuffix(violations)), "
                + "\(serious) serious in \(files.count) file\(pluralSuffix(files))."
        )
    }

    private static func isWarningThresholdBroken(
        configuration: Configuration,
        violations: [StyleViolation]
    ) -> Bool {
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

    private static func applyLeniency(
        options: LintOrAnalyzeOptions,
        strict: Bool,
        violations: [StyleViolation]
    ) -> [StyleViolation] {
        let strict = (strict && !options.lenient) || options.strict

        switch (options.lenient, strict) {
        case (false, false):
            return violations

        case (true, false):
            return violations.map {
                if $0.severity == .error {
                    return $0.with(severity: .warning)
                }
                return $0
            }

        case (false, true):
            return violations.map {
                if $0.severity == .warning {
                    return $0.with(severity: .error)
                }
                return $0
            }

        case (true, true):
            queuedFatalError(
                "Invalid command line options: 'lenient' and 'strict' are mutually exclusive.")
        }
    }

    private static func autocorrect(_ options: LintOrAnalyzeOptions) async throws {
        let storage = RuleStorage()
        let configuration = Configuration(options: options)
        let correctionsBuilder = CorrectionsBuilder()
        let files =
            try await configuration
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
                collection.count != 1 ? "s" : ""
            }
            queuedPrintError("Done correcting \(files.count) file\(pluralSuffix(files))!")
        }
    }
}

private actor LintOrAnalyzeResultBuilder {
    var fileBenchmark = Benchmark(name: "files")
    var ruleBenchmark = Benchmark(name: "rules")
    /// All detected violations, unfiltered by the baseline, if any.
    var unfilteredViolations = [StyleViolation]()
    /// The violations to be reported, possibly filtered by a baseline, plus any threshold violations.
    var violations = [StyleViolation]()
    let storage = RuleStorage()
    let configuration: Configuration
    let reporter: any Reporter.Type
    let cache: LinterCache?
    let options: LintOrAnalyzeOptions

    init(_ options: LintOrAnalyzeOptions) async {
        let config = await Signposts.record(name: "LintOrAnalyzeCommand.ParseConfiguration") {
            @Sendable in
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
                Issue.fileNotWritable(path: outFile).print()
            }
        }
    }

    func recordFileBenchmark(file: SwiftLintFile, from date: Date) {
        fileBenchmark.record(file: file, from: date)
    }

    func recordRuleBenchmark(id: String, time: Double) {
        ruleBenchmark.record(id: id, time: time)
    }

    func addViolations(
        filteredViolations: [StyleViolation] = [], unfilteredViolations: [StyleViolation] = []
    ) {
        self.violations += filteredViolations
        self.unfilteredViolations += unfilteredViolations
    }

    func report(violations: [StyleViolation], realtimeCondition: Bool) {
        if (reporter.isRealtime && (!options.progress || options.output != nil))
            == realtimeCondition
        {
            let report = reporter.generateReport(violations)
            if !report.isEmpty {
                options.writeToOutput(report)
            }
        }
    }
}

extension LintOrAnalyzeOptions {
    fileprivate func writeToOutput(_ string: String) {
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
            Issue.fileNotWritable(path: outFile).print()
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
        let basicInfoCount =
            MemoryLayout<mach_task_basic_info>.stride / MemoryLayout<natural_t>.stride
        var count = mach_msg_type_number_t(basicInfoCount)

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: basicInfoCount) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let bytes = Measurement<UnitInformationStorage>(
                value: Double(info.resident_size), unit: .bytes)
            let formatted = ByteCountFormatter().string(from: bytes)
            return "Memory used: \(formatted)"
        }
        let errorMessage = String(cString: mach_error_string(kerr), encoding: .ascii)
        return "Error with task_info(): \(errorMessage ?? "unknown")"
    #endif
}
