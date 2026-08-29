import Foundation
@preconcurrency import SwiftLintCore

// The worker protocol is kept in one file so its schemas, validators, and command boundary evolve atomically.
// swiftlint:disable file_length

package struct AnalyzerPreparedTargetPlan: Sendable {
    package let plan: AnalyzerTargetPlan
    package let planDirectory: URL
    package let workingDirectory: URL
    package let digest: String
}

package struct AnalyzerNativeRun: Sendable {
    package let aggregate: AnalyzerWorkerAggregate
    package let graph: [AnalyzerJob]
    package let results: [AnalyzerWorkerResult]
    package let metrics: AnalyzerWorkerProcessMetrics
    package let elapsedSeconds: Double
    package let targetPlanSha256: String
    package let jobsRequested: Int
    package let workingDirectory: URL
}

// All mutable state is private, protected by `lock`, and no mutable reference escapes.
private final class AnalyzerWorkerResultCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var violations = [StyleViolation]()
    private var fileTimings = [AnalyzerFileTiming]()
    private var ruleTimings = [AnalyzerRuleTiming]()

    func record(
        violations: [StyleViolation],
        fileTiming: AnalyzerFileTiming,
        ruleTimings: [AnalyzerRuleTiming]
    ) {
        lock.withLock {
            self.violations += violations
            fileTimings.append(fileTiming)
            self.ruleTimings += ruleTimings
        }
    }

    func result(
        request: AnalyzerWorkerRequest,
        files: [URL],
        durationSeconds: Double
    ) -> AnalyzerWorkerResult {
        lock.withLock {
            AnalyzerWorkerResult(
                schemaIdentity: AnalyzerWorkerResult.schemaIdentity,
                schemaVersion: AnalyzerWorkerResult.currentVersion,
                workerId: request.workerId,
                jobId: request.jobId,
                targetId: request.targetId,
                ruleIdentifier: request.ruleIdentifier,
                batchIndex: request.batchIndex,
                requestedPaths: request.requestedPaths,
                compileCommandsSha256: request.compileCommandsSha256,
                violations: violations.sorted(by: analyzerViolationPrecedes),
                files: files.sorted(by: { $0.path < $1.path }),
                fileTimings: fileTimings.sorted(by: analyzerFileTimingPrecedes),
                ruleTimings: ruleTimings.sorted(by: analyzerRuleTimingPrecedes),
                startOffsetSeconds: 0,
                durationSeconds: durationSeconds,
                exitCode: 0
            )
        }
    }
}

// swiftlint:disable:next type_body_length
package extension LintOrAnalyzeCommand {
    static func analyzerExecutableURL(
        argument: String = CommandLine.arguments[0],
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> URL {
        let fileManager = FileManager.default
        if argument.contains("/") {
            let url = URL(filePath: argument).standardizedFileURL
            guard fileManager.isExecutableFile(atPath: url.path) else {
                throw SwiftLintError.usageError(
                    description: "Could not locate the SwiftLint executable at '\(url.path)'."
                )
            }
            return url
        }

        for directory in environment["PATH", default: ""].split(separator: ":", omittingEmptySubsequences: false) {
            let baseURL = directory.isEmpty
                ? URL(filePath: fileManager.currentDirectoryPath, directoryHint: .isDirectory)
                : URL(filePath: String(directory), directoryHint: .isDirectory)
            let candidate = baseURL.appending(path: argument, directoryHint: .notDirectory)
            if fileManager.isExecutableFile(atPath: candidate.path) {
                return candidate.standardizedFileURL
            }
        }
        throw SwiftLintError.usageError(
            description: "Could not locate the SwiftLint executable '\(argument)' in PATH."
        )
    }

    static func validateTargetAwareAnalyzeOptions(
        targetPlanPath: String,
        executionEvidencePath: String,
        jobs: Int,
        autocorrect: Bool
    ) throws {
        guard !targetPlanPath.isEmpty, !executionEvidencePath.isEmpty else {
            throw SwiftLintError.usageError(
                description: "Target-aware analyze requires both --target-plan and --execution-evidence."
            )
        }
        guard jobs > 0 else {
            throw SwiftLintError.usageError(description: "--jobs must be a positive integer.")
        }
        guard !autocorrect || jobs == 1 else {
            throw SwiftLintError.usageError(
                description: "Analyzer autocorrection is serial; use --jobs 1 with --fix."
            )
        }
    }

    static func prepareTargetAwareAnalyze(_ options: LintOrAnalyzeOptions) throws -> AnalyzerPreparedTargetPlan {
        guard let targetPlanURL = options.targetPlan else {
            throw SwiftLintError.usageError(description: "Target-aware analyze is missing --target-plan.")
        }
        let planData = try Data(contentsOf: targetPlanURL)
        try validateTargetPlanJSONShape(planData)
        let plan = try JSONDecoder().decode(AnalyzerTargetPlan.self, from: planData)
        guard plan.schemaIdentity == AnalyzerTargetPlan.schemaIdentity,
              plan.schemaVersion == AnalyzerTargetPlan.currentVersion else {
            throw AnalyzerTargetPlanError.invalidSchema
        }
        let invocationDirectory = URL(
            filePath: FileManager.default.currentDirectoryPath,
            directoryHint: .isDirectory
        )
        let workingDirectory = resolve(plan.workingDirectory, relativeTo: invocationDirectory)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: workingDirectory.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw SwiftLintError.usageError(
                description: "Analyzer target-plan working directory does not exist: '\(workingDirectory.path)'."
            )
        }
        return AnalyzerPreparedTargetPlan(
            plan: plan,
            planDirectory: targetPlanURL.deletingLastPathComponent().standardizedFileURL,
            workingDirectory: workingDirectory,
            digest: AnalyzerTargetPlan.sha256(planData)
        )
    }

    // swiftlint:disable:next function_body_length
    static func executeTargetAwareAnalyze(
        _ options: LintOrAnalyzeOptions,
        preparedPlan: AnalyzerPreparedTargetPlan
    ) async throws -> AnalyzerNativeRun {
        let configuration = Configuration(options: options)
        let analyzerRules = configuration.rules.filter { $0 is any AnalyzerRule }
        var capabilities = [String: AnalyzerRuleCapability]()
        for rule in analyzerRules {
            let identifier = type(of: rule).identifier
            guard capabilities[identifier] == nil else {
                throw AnalyzerTargetPlanError.duplicateIdentity("configured analyzer rule")
            }
            capabilities[identifier] = AnalyzerRuleCapability(
                isCollecting: rule is any AnyCollectingRule,
                maximumBatchSize: (rule as? any AnalyzerBatchingRule)?.analyzerBatchSize
            )
        }
        var resolvedGraph = try preparedPlan.plan.validatedJobGraph(capabilities: capabilities)
        try validateTargetInputs(preparedPlan, graph: &resolvedGraph)
        let graph = resolvedGraph

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appending(path: "swiftlint-analyzer-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let requests = zip(graph.indices, graph).map { index, job in
            AnalyzerWorkerRequest(
                job: job,
                options: options,
                resultURL: temporaryDirectory.appending(
                    path: "result-\(index).json",
                    directoryHint: .notDirectory
                )
            )
        }
        let runner = AnalyzerWorkerProcessRunner(
            executableURL: try analyzerExecutableURL(),
            currentDirectoryURL: preparedPlan.workingDirectory,
            environment: ProcessInfo.processInfo.environment
        )
        let invocations = try runner.prepare(requests: requests, graph: graph, in: temporaryDirectory)
        let signalForwarder = AnalyzerSignalForwarder(runner: runner)
        _ = signalForwarder

        let clock = ContinuousClock()
        let runStarted = clock.now
        let coordinator = AnalyzerProcessCoordinator<AnalyzerWorkerInvocation, AnalyzerWorkerResult>(
            jobs: options.analyzerJobs
        ) { invocation in
            let workerStarted = clock.now
            let output = try await runner.run(invocation)
            try validateWorkerResultJSONShape(output.resultData)
            var result = try JSONDecoder().decode(AnalyzerWorkerResult.self, from: output.resultData)
            guard let graphIndex = graph.firstIndex(where: { $0.jobId == invocation.jobId }) else {
                throw AnalyzerWorkerContractError.extraJob
            }
            let job = graph[graphIndex]
            try result.validate(for: job)
            result.startOffsetSeconds = runStarted.duration(to: workerStarted).analyzerSeconds
            result.durationSeconds = workerStarted.duration(to: clock.now).analyzerSeconds
            return result
        }

        do {
            let results = try await coordinator.run(invocations)
            let aggregate = try AnalyzerWorkerAggregate.merge(graph: graph, results: results)
            return AnalyzerNativeRun(
                aggregate: aggregate,
                graph: graph,
                results: results,
                metrics: runner.metrics,
                elapsedSeconds: runStarted.duration(to: clock.now).analyzerSeconds,
                targetPlanSha256: preparedPlan.digest,
                jobsRequested: options.analyzerJobs,
                workingDirectory: preparedPlan.workingDirectory
            )
        } catch {
            runner.cancelAll()
            throw error
        }
    }

    static func writeAnalyzerExecutionEvidence(
        _ run: AnalyzerNativeRun,
        findings: [StyleViolation],
        reporterOutput: Data,
        to path: String
    ) throws {
        let evidence = try AnalyzerExecutionEvidence.make(
            targetPlanSha256: run.targetPlanSha256,
            jobsRequested: run.jobsRequested,
            peakConcurrentJobs: run.metrics.peakConcurrentJobs,
            peakChildResidentMemoryBytes: run.metrics.peakAggregateResidentMemoryBytes,
            elapsedSeconds: run.elapsedSeconds,
            graph: run.graph,
            results: run.results,
            findings: findings,
            reporterOutput: reporterOutput,
            workingDirectory: run.workingDirectory
        )
        var data = try AnalyzerJSON.encoder.encode(evidence)
        data.append(0x0a)
        try data.write(to: URL(filePath: path), options: .atomic)
    }

    // swiftlint:disable:next function_body_length
    static func runAnalyzerWorker(requestAt requestURL: URL) async throws {
        let requestData = try Data(contentsOf: requestURL)
        try validateWorkerRequestJSONShape(requestData)
        let request = try JSONDecoder().decode(AnalyzerWorkerRequest.self, from: requestData)
        try request.validate()
        let compileCommandsData = try Data(contentsOf: URL(filePath: request.compileCommandsPath))
        guard AnalyzerTargetPlan.sha256(compileCommandsData) == request.compileCommandsSha256 else {
            throw AnalyzerWorkerContractError.requestMismatch(request.jobId)
        }

        let workerDirectory = URL(
            filePath: FileManager.default.currentDirectoryPath,
            directoryHint: .isDirectory
        )
        let requestedURLs = request.requestedPaths.map { resolve($0, relativeTo: workerDirectory) }
        let workerOptions = LintOrAnalyzeOptions(
            mode: .analyze,
            paths: requestedURLs,
            useSTDIN: false,
            configurationFiles: request.options.configurationFiles,
            strict: false,
            lenient: false,
            forceExclude: request.options.forceExclude,
            useExcludingByPrefix: request.options.useExcludingByPrefix,
            useScriptInputFiles: false,
            useScriptInputFileLists: false,
            benchmark: true,
            reporter: nil,
            baseline: nil,
            writeBaseline: nil,
            workingDirectory: nil,
            quiet: true,
            output: nil,
            progress: false,
            cachePath: nil,
            ignoreCache: true,
            enableAllRules: false,
            onlyRule: [request.ruleIdentifier],
            autocorrect: request.options.autocorrect,
            format: false,
            disableSourceKit: request.options.disableSourceKit,
            compilerLogPath: nil,
            compileCommands: request.compileCommandsPath,
            checkForUpdates: false
        )
        let configuration = Configuration(options: workerOptions)
        let configuredAnalyzerRules = configuration.rules
            .filter { $0 is any AnalyzerRule }
            .map { type(of: $0).identifier }
        guard configuredAnalyzerRules == [request.ruleIdentifier] else {
            throw AnalyzerWorkerContractError.requestMismatch(request.jobId)
        }

        let storage = RuleStorage()
        let collector = AnalyzerWorkerResultCollector()
        let clock = ContinuousClock()
        let started = clock.now
        let files = try await configuration.visitLintableFiles(
            options: workerOptions,
            cache: nil,
            storage: storage
        ) { linter in
            let fileStarted = clock.now
            if request.options.autocorrect {
                _ = linter.correct(using: storage)
                collector.record(
                    violations: [],
                    fileTiming: AnalyzerFileTiming(
                        path: linter.file.path?.path ?? "<nopath>",
                        seconds: fileStarted.duration(to: clock.now).analyzerSeconds
                    ),
                    ruleTimings: []
                )
            } else {
                let (rawViolations, rawRuleTimes) = linter.styleViolationsAndRuleTimes(using: storage)
                let violations = rawViolations.filter { $0.ruleIdentifier == request.ruleIdentifier }
                collector.record(
                    violations: violations,
                    fileTiming: AnalyzerFileTiming(
                        path: linter.file.path?.path ?? "<nopath>",
                        seconds: fileStarted.duration(to: clock.now).analyzerSeconds
                    ),
                    ruleTimings: rawRuleTimes
                        .filter { $0.id == request.ruleIdentifier }
                        .map { AnalyzerRuleTiming(ruleIdentifier: $0.id, seconds: $0.time) }
                )
            }
        }
        let fileURLs = try files.map { file in
            guard let path = file.path else {
                throw AnalyzerWorkerContractError.resultMismatch(request.jobId)
            }
            return path.standardizedFileURL
        }
        let expectedURLs = requestedURLs
        guard fileURLs.sorted(by: { $0.path < $1.path }) == expectedURLs.sorted(by: { $0.path < $1.path }) else {
            throw AnalyzerWorkerContractError.resultMismatch(
                "\(request.jobId) [file inventory expected=\(expectedURLs.map(\.path)) actual=\(fileURLs.map(\.path))]"
            )
        }
        let result = collector.result(
            request: request,
            files: fileURLs,
            durationSeconds: started.duration(to: clock.now).analyzerSeconds
        )
        try AnalyzerJSON.encoder.encode(result).write(to: request.resultURL, options: .atomic)
    }

    private static func validateTargetInputs(
        _ preparedPlan: AnalyzerPreparedTargetPlan,
        graph: inout [AnalyzerJob]
    ) throws {
        let targetsByID = Dictionary(uniqueKeysWithValues: preparedPlan.plan.targets.map { ($0.targetId, $0) })
        for target in preparedPlan.plan.targets {
            let root = resolve(target.sourceRoot, relativeTo: preparedPlan.workingDirectory)
            guard isContained(root, in: preparedPlan.workingDirectory) else {
                throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
            }
            let sourceURLs = target.sourceFiles.map { resolve($0, relativeTo: preparedPlan.workingDirectory) }
            guard sourceURLs.allSatisfy({ isContained($0, in: root) }),
                  sourceURLs.allSatisfy({ FileManager.default.fileExists(atPath: $0.path) }) else {
                throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
            }

            let compileCommandsURL = resolve(target.compileCommandsPath, relativeTo: preparedPlan.planDirectory)
            let compileCommandsData = try Data(contentsOf: compileCommandsURL)
            guard AnalyzerTargetPlan.sha256(compileCommandsData) == target.compileCommandsSha256 else {
                throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
            }
            try validateCompilationDatabase(
                compileCommandsData,
                target: target,
                workingDirectory: preparedPlan.workingDirectory
            )
        }

        for index in graph.indices {
            guard let target = targetsByID[graph[index].targetId] else {
                throw AnalyzerTargetPlanError.invalidTarget(graph[index].targetId)
            }
            graph[index].compileCommandsPath = resolve(
                target.compileCommandsPath,
                relativeTo: preparedPlan.planDirectory
            ).path
        }
    }

    private static func validateCompilationDatabase(
        _ data: Data,
        target: AnalyzerTargetPlan.Target,
        workingDirectory: URL
    ) throws {
        guard let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              entries.count == target.sourceFiles.count else {
            throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
        }
        let expectedFiles = Set(target.sourceFiles.map { resolve($0, relativeTo: workingDirectory).path })
        var actualFiles = Set<String>()
        for entry in entries {
            guard let file = entry["file"] as? String,
                  let arguments = entry["arguments"] as? [String] else {
                throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
            }
            let absoluteFile = resolve(file, relativeTo: workingDirectory).path
            guard actualFiles.insert(absoluteFile).inserted,
                  expectedFiles.contains(absoluteFile),
                  arguments.contains(absoluteFile),
                  expectedFiles.allSatisfy(arguments.contains),
                  arguments.adjacentPairs().contains(where: {
                      $0.0 == "-module-name" && $0.1 == target.moduleName
                  }) else {
                throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
            }
        }
        guard actualFiles == expectedFiles else {
            throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
        }
    }

    private static func validateTargetPlanJSONShape(_ data: Data) throws {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              Set(root.keys) == [
                "schemaIdentity", "schemaVersion", "compilerLogSha256", "workingDirectory", "rules", "targets",
              ],
              let targets = root["targets"] as? [[String: Any]] else {
            throw AnalyzerTargetPlanError.invalidSchema
        }
        for target in targets {
            guard Set(target.keys) == [
                "targetId", "moduleName", "sourceRoot", "compileCommandsPath", "compileCommandsSha256",
                "sourceFiles", "sourceFilesSha256", "rulePlans",
            ], let rulePlans = target["rulePlans"] as? [[String: Any]] else {
                throw AnalyzerTargetPlanError.invalidSchema
            }
            for rulePlan in rulePlans {
                guard Set(rulePlan.keys) == ["rule", "mode", "batches"],
                      let batches = rulePlan["batches"] as? [[String: Any]],
                      batches.allSatisfy({ Set($0.keys) == ["batchIndex", "requestedPaths"] }) else {
                    throw AnalyzerTargetPlanError.invalidSchema
                }
            }
        }
    }

    private static func validateWorkerRequestJSONShape(_ data: Data) throws {
        let requiredRootKeys: Set<String> = [
            "schemaIdentity", "schemaVersion", "workerId", "jobId", "targetId", "moduleName", "sourceRoot",
            "ruleIdentifier", "requestedPaths", "targetSourcePaths", "compileCommandsPath",
            "compileCommandsSha256", "options", "resultURL",
        ]
        let allowedRootKeys = requiredRootKeys.union(["batchIndex"])
        let requiredOptionKeys: Set<String> = [
            "configurationFiles", "strict", "lenient", "forceExclude", "useExcludingByPrefix",
            "benchmark", "quiet", "disableSourceKit", "autocorrect",
        ]
        let allowedOptionKeys = requiredOptionKeys.union(["reporter"])
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              requiredRootKeys.isSubset(of: root.keys),
              Set(root.keys).isSubset(of: allowedRootKeys),
              let options = root["options"] as? [String: Any],
              requiredOptionKeys.isSubset(of: options.keys),
              Set(options.keys).isSubset(of: allowedOptionKeys) else {
            throw AnalyzerWorkerContractError.requestMismatch("unknown")
        }
    }

    private static func validateWorkerResultJSONShape(_ data: Data) throws {
        let requiredKeys: Set<String> = [
            "schemaIdentity", "schemaVersion", "workerId", "jobId", "targetId", "ruleIdentifier",
            "requestedPaths", "compileCommandsSha256", "violations", "files", "fileTimings", "ruleTimings",
            "startOffsetSeconds", "durationSeconds", "exitCode",
        ]
        let allowedKeys = requiredKeys.union(["batchIndex"])
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              requiredKeys.isSubset(of: root.keys),
              Set(root.keys).isSubset(of: allowedKeys) else {
            throw AnalyzerWorkerContractError.resultMismatch("unknown")
        }
    }

    private static func resolve(_ path: String, relativeTo base: URL) -> URL {
        let url = URL(filePath: path)
        return (url.path.hasPrefix("/") ? url : base.appending(path: path)).standardizedFileURL
    }

    private static func isContained(_ url: URL, in directory: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let root = directory.standardizedFileURL.path
        return path == root || path.hasPrefix(root.hasSuffix("/") ? root : root + "/")
    }
}

private func analyzerViolationPrecedes(_ lhs: StyleViolation, _ rhs: StyleViolation) -> Bool {
    if lhs.location != rhs.location { return lhs.location < rhs.location }
    if lhs.ruleIdentifier != rhs.ruleIdentifier { return lhs.ruleIdentifier < rhs.ruleIdentifier }
    if lhs.reason != rhs.reason { return lhs.reason < rhs.reason }
    return lhs.severity.rawValue < rhs.severity.rawValue
}

private func analyzerFileTimingPrecedes(_ lhs: AnalyzerFileTiming, _ rhs: AnalyzerFileTiming) -> Bool {
    lhs.path == rhs.path ? lhs.seconds < rhs.seconds : lhs.path < rhs.path
}

private func analyzerRuleTimingPrecedes(_ lhs: AnalyzerRuleTiming, _ rhs: AnalyzerRuleTiming) -> Bool {
    lhs.ruleIdentifier == rhs.ruleIdentifier
        ? lhs.seconds < rhs.seconds
        : lhs.ruleIdentifier < rhs.ruleIdentifier
}

private extension Duration {
    var analyzerSeconds: Double {
        let components = components
        return Double(components.seconds) + Double(components.attoseconds) / 1_000_000_000_000_000_000
    }
}

private extension Collection {
    func adjacentPairs() -> [(Element, Element)] {
        zip(self, dropFirst()).map { ($0, $1) }
    }
}
