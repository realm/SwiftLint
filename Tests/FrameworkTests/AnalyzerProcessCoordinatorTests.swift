import Foundation
import SourceKittenFramework
import SwiftLintCore
import Testing

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

// This is the only plan-owned compiled test file for the complete local worker protocol.
// swiftlint:disable file_length

@testable import SwiftLintBuiltInRules
@testable import SwiftLintFramework

private let runningUnderBazel = ProcessInfo.processInfo.environment["TEST_SRCDIR"] != nil

// swiftlint:disable type_body_length
@Suite
struct AnalyzerProcessCoordinatorTests {
    @Test
    func targetPlanBuildsDeterministicTargetRuleBatchOrder() throws {
        let plan = targetPlan()

        let graph = try plan.validatedJobGraph(capabilities: capabilities())

        #expect(graph.map(\.jobId) == [
            "application/capture_variable",
            "application/unused_import/batch-000",
            "application/unused_import/batch-001",
            "unitTests/capture_variable",
            "unitTests/unused_import/batch-000",
        ])
        #expect(graph.map(\.workerId) == [
            "worker-0000",
            "worker-0001",
            "worker-0002",
            "worker-0003",
            "worker-0004",
        ])
    }

    @Test
    func coordinatorUsesOneGlobalBoundAndReturnsGraphOrder() async throws {
        let probe = ConcurrencyProbe()
        let coordinator = AnalyzerProcessCoordinator<Int, Int>(jobs: 2) { value in
            await probe.started()
            try await Task.sleep(for: .milliseconds(value.isMultiple(of: 2) ? 40 : 10))
            await probe.finished()
            return value
        }

        let values = try await coordinator.run([0, 1, 2, 3, 4])

        #expect(values == [0, 1, 2, 3, 4])
        #expect(await probe.maximumActiveJobs == 2)
    }

    @Test
    func coordinatorCancelsPeersAfterFirstFailure() async {
        let probe = CancellationProbe()
        let coordinator = AnalyzerProcessCoordinator<Int, Int>(jobs: 2) { value in
            await probe.started(value)
            await probe.waitUntilBothStarted()
            if value == 1 {
                throw TestWorkerError.failed
            }
            do {
                try await Task.sleep(for: .seconds(5))
                return value
            } catch is CancellationError {
                await probe.cancelled(value)
                throw CancellationError()
            } catch {
                throw error
            }
        }

        do {
            _ = try await coordinator.run([0, 1])
            Issue.record("Expected the first worker failure to reject the run")
        } catch TestWorkerError.failed {
            await probe.waitUntilCancelled(0)
            #expect(await probe.cancelledRequests == [0])
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func unusedImportDeclaresTheOnlyInitialBatchCapability() {
        let unusedImport = UnusedImportRule()

        #expect(unusedImport.analyzerBatchSize == 32)
    }

    @Test
    func batchedJobKeepsFullTargetCompileCommandsContext() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let batched = try #require(graph.first(where: { $0.jobId == "application/unused_import/batch-000" }))

        #expect(batched.requestedPaths == ["Sources/A.swift", "Sources/B.swift"])
        #expect(batched.targetSourcePaths == ["Sources/A.swift", "Sources/B.swift", "Sources/C.swift"])
        #expect(batched.compileCommandsPath == "application.compile-commands.json")
        #expect(batched.compileCommandsSha256 == String(repeating: "a", count: 64))
    }

    @Test
    func collectingRuleRemainsOneWholeTargetJob() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let job = try #require(graph.first)

        #expect(job.ruleIdentifier == "capture_variable")
        #expect(job.batchIndex == nil)
        #expect(job.requestedPaths == ["Sources/A.swift", "Sources/B.swift", "Sources/C.swift"])
    }

    @Test(arguments: invalidPlanMutations())
    fileprivate func planRejectsIncompleteOrAmbiguousBatchCoverage(mutation: InvalidPlanMutation) {
        var plan = targetPlan()
        mutation.mutate(&plan)

        #expect(throws: AnalyzerTargetPlanError.self) {
            try plan.validatedJobGraph(capabilities: capabilities())
        }
    }

    @Test
    func planRejectsBatchingWithoutAnExplicitRuleCapability() {
        var plan = targetPlan()
        plan.targets[0].rulePlans[0] = .init(
            rule: "capture_variable",
            mode: .batches,
            batches: [.init(batchIndex: 0, requestedPaths: plan.targets[0].sourceFiles)]
        )

        #expect(throws: AnalyzerTargetPlanError.self) {
            try plan.validatedJobGraph(capabilities: capabilities())
        }
    }

    @Test
    func planRejectsBatchLargerThanRuleCapability() {
        let sources = (0..<33).map { "Sources/File\($0).swift" }
        var plan = targetPlan()
        plan.targets[0].sourceFiles = sources
        plan.targets[0].sourceFilesSha256 = AnalyzerTargetPlan.sourceInventoryDigest(sources)
        plan.targets[0].rulePlans[1].batches = [.init(batchIndex: 0, requestedPaths: sources)]

        #expect(throws: AnalyzerTargetPlanError.self) {
            try plan.validatedJobGraph(capabilities: capabilities())
        }
    }

    @Test
    func planRejectsDuplicateTargetAndRuleIdentities() {
        var duplicateTarget = targetPlan()
        duplicateTarget.targets.append(duplicateTarget.targets[0])
        var duplicateRule = targetPlan()
        duplicateRule.rules.append("unused_import")

        #expect(throws: AnalyzerTargetPlanError.self) {
            try duplicateTarget.validatedJobGraph(capabilities: capabilities())
        }
        #expect(throws: AnalyzerTargetPlanError.self) {
            try duplicateRule.validatedJobGraph(capabilities: capabilities())
        }
    }

    @Test
    func workerRequestRejectsIdentityAndInventoryDrift() throws {
        let job = try #require(targetPlan().validatedJobGraph(capabilities: capabilities()).first)
        let request = AnalyzerWorkerRequest(
            job: job,
            options: analyzeOptions(),
            resultURL: URL(filePath: "/tmp/result")
        )
        var wrongJob = request
        wrongJob.jobId = "unexpected/job"
        var wrongSources = request
        wrongSources.requestedPaths = ["Sources/Unexpected.swift"]

        try request.validate(for: job)
        #expect(throws: AnalyzerWorkerContractError.self) {
            try wrongJob.validate(for: job)
        }
        #expect(throws: AnalyzerWorkerContractError.self) {
            try wrongSources.validate(for: job)
        }
    }

    @Test
    func aggregateRejectsDuplicateWorkerAndJobIdentities() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let first = workerResult(job: graph[0])
        var duplicateWorker = workerResult(job: graph[1])
        duplicateWorker.workerId = first.workerId
        var duplicateJob = workerResult(job: graph[1])
        duplicateJob.jobId = first.jobId

        #expect(throws: AnalyzerWorkerContractError.self) {
            try AnalyzerWorkerAggregate.merge(graph: Array(graph.prefix(2)), results: [first, duplicateWorker])
        }
        #expect(throws: AnalyzerWorkerContractError.self) {
            try AnalyzerWorkerAggregate.merge(graph: Array(graph.prefix(2)), results: [first, duplicateJob])
        }
    }

    @Test
    func aggregateRejectsMissingAndExtraJobs() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let firstTwo = Array(graph.prefix(2))

        #expect(throws: AnalyzerWorkerContractError.self) {
            try AnalyzerWorkerAggregate.merge(graph: firstTwo, results: [workerResult(job: firstTwo[0])])
        }
        #expect(throws: AnalyzerWorkerContractError.self) {
            try AnalyzerWorkerAggregate.merge(
                graph: [firstTwo[0]],
                results: firstTwo.map(workerResult)
            )
        }
    }

    @Test
    func aggregateRejectsUnexpectedDuplicateRawFindings() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let violation = violation(rule: "unused_import", file: "Sources/A.swift", line: 1)
        var first = workerResult(job: graph[1])
        first.violations = [violation]
        var second = workerResult(job: graph[2])
        second.violations = [violation]

        #expect(throws: AnalyzerWorkerContractError.self) {
            try AnalyzerWorkerAggregate.merge(graph: Array(graph[1...2]), results: [first, second])
        }
    }

    @Test
    func aggregateMergesFindingsAndReporterInputDeterministically() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let firstViolation = violation(rule: "capture_variable", file: "Sources/C.swift", line: 3)
        let secondViolation = violation(rule: "unused_import", file: "Sources/A.swift", line: 1)
        var first = workerResult(job: graph[0])
        first.violations = [firstViolation]
        var second = workerResult(job: graph[1])
        second.violations = [secondViolation]

        let forward = try AnalyzerWorkerAggregate.merge(graph: Array(graph.prefix(2)), results: [first, second])
        let reverse = try AnalyzerWorkerAggregate.merge(graph: Array(graph.prefix(2)), results: [second, first])

        #expect(forward.violations == [secondViolation, firstViolation])
        #expect(forward == reverse)
        #expect(JSONReporter.generateReport(forward.violations) == JSONReporter.generateReport(reverse.violations))
        #expect(XcodeReporter.generateReport(forward.violations) == XcodeReporter.generateReport(reverse.violations))
    }

    @Test
    func executionEvidenceRejectsDuplicateIdentitiesAndWrongProvenance() throws {
        let graph = try targetPlan().validatedJobGraph(capabilities: capabilities())
        let results = graph.map(workerResult)
        var evidence = try AnalyzerExecutionEvidence.make(
            targetPlanSha256: String(repeating: "f", count: 64),
            jobsRequested: 4,
            peakConcurrentJobs: 4,
            peakChildResidentMemoryBytes: 1024,
            elapsedSeconds: 1,
            graph: graph,
            results: results,
            findings: [],
            reporterOutput: Data("[]\n".utf8)
        )

        try evidence.validate(graph: graph, targetPlanSha256: String(repeating: "f", count: 64))
        evidence.targetPlanSha256 = String(repeating: "0", count: 64)
        #expect(throws: AnalyzerWorkerContractError.self) {
            try evidence.validate(graph: graph, targetPlanSha256: String(repeating: "f", count: 64))
        }
    }

    @Test
    func workerFailurePreservesExitAndDiagnostics() {
        let error = AnalyzerWorkerContractError.workerFailed(
            job: "application/unused_import/batch-000",
            reason: "signal 9",
            diagnostics: "SourceKit terminated"
        )

        #expect(error.localizedDescription.contains("signal 9"))
        #expect(error.localizedDescription.contains("SourceKit terminated"))
    }

    @Test
    func targetAwareOptionsRequirePositiveJobsAndSerialAutocorrection() throws {
        try LintOrAnalyzeCommand.validateTargetAwareAnalyzeOptions(
            targetPlanPath: "/tmp/plan.json",
            executionEvidencePath: "/tmp/evidence.json",
            jobs: 1,
            autocorrect: true
        )
        try LintOrAnalyzeCommand.validateTargetAwareAnalyzeOptions(
            targetPlanPath: "/tmp/plan.json",
            executionEvidencePath: "/tmp/evidence.json",
            jobs: 4,
            autocorrect: false
        )

        #expect(throws: SwiftLintError.self) {
            try LintOrAnalyzeCommand.validateTargetAwareAnalyzeOptions(
                targetPlanPath: "/tmp/plan.json",
                executionEvidencePath: "/tmp/evidence.json",
                jobs: 0,
                autocorrect: false
            )
        }
        #expect(throws: SwiftLintError.self) {
            try LintOrAnalyzeCommand.validateTargetAwareAnalyzeOptions(
                targetPlanPath: "/tmp/plan.json",
                executionEvidencePath: "/tmp/evidence.json",
                jobs: 2,
                autocorrect: true
            )
        }
    }

    @Test
    func processRunnerPreservesCrashExitAndDiagnostics() async throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let runner = fixture.runner()
        let invocation = fixture.invocation(
            jobId: "crashing-worker",
            script: "printf 'SourceKit terminated' >&2; exit 7"
        )

        do {
            _ = try await runner.run(invocation)
            Issue.record("Expected the crashing worker to fail")
        } catch let error as AnalyzerWorkerContractError {
            #expect(error.localizedDescription.contains("exit 7"))
            #expect(error.localizedDescription.contains("SourceKit terminated"))
        }
    }

    @Test
    func cancellationTerminatesWorkerDescendants() async throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let descendantPID = fixture.directory.appending(path: "descendant.pid")
        let runner = fixture.runner()
        let invocation = fixture.invocation(
            jobId: "cancelled-worker",
            script: "sleep 30 & child=$!; printf '%s' \"$child\" > \"$PID_FILE\"; wait"
        )
        let task = Task { try await runner.run(invocation) }
        let processIdentifier = try await waitForProcessIdentifier(at: descendantPID)

        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await processExits(processIdentifier))
    }

    @Test
    func forwardedSignalTerminatesWorkerDescendants() async throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let descendantPID = fixture.directory.appending(path: "forwarded-descendant.pid")
        let runner = fixture.runner()
        let invocation = fixture.invocation(
            jobId: "forwarded-worker",
            script: "sleep 30 & child=$!; printf '%s' \"$child\" > \"$PID_FILE\"; wait"
        )
        let task = Task { try await runner.run(invocation) }
        let processIdentifier = try await waitForProcessIdentifier(at: descendantPID)

        runner.forward(signal: SIGTERM)
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await processExits(processIdentifier))
    }

    @Test
    func cancellationCannotMissAWorkerDuringSpawnRegistration() async throws {
        for index in 0..<20 {
            let fixture = try ProcessFixture(suffix: "-\(index)")
            defer { fixture.remove() }
            let runner = fixture.runner()
            let invocation = fixture.invocation(
                jobId: "spawn-race-\(index)",
                script: "sleep 30"
            )
            let task = Task { try await runner.run(invocation) }

            runner.cancelAll()
            await #expect(throws: CancellationError.self) {
                try await task.value
            }
            #expect(runner.metrics.peakConcurrentJobs <= 1)
        }
    }

    // swiftlint:disable function_body_length
    @Test(.disabled(if: runningUnderBazel, "The Bazel FrameworkTests target does not stage the swiftlint executable."))
    func targetAwareAnalyzeCommandPublishesReporterAndEvidence() throws {
        let fixture = try ProcessFixture()
        defer { fixture.remove() }
        let sourceURL = fixture.directory.appending(path: "Source.swift")
        try Data("let value = 1\n".utf8).write(to: sourceURL)

        let compileCommandsURL = fixture.directory.appending(path: "compile-commands.json")
        var compilerArguments = ["-module-name", "Fixture"]
        compilerArguments += try platformCompilerContextArguments()
        compilerArguments.append(sourceURL.path)
        let compileCommands: [[String: Any]] = [
            [
                "directory": fixture.directory.path,
                "file": sourceURL.path,
                "arguments": compilerArguments,
            ],
        ]
        let compileCommandsData = try JSONSerialization.data(
            withJSONObject: compileCommands,
            options: [.sortedKeys, .withoutEscapingSlashes]
        )
        try compileCommandsData.write(to: compileCommandsURL)

        let sourceFiles = ["Source.swift"]
        let plan = AnalyzerTargetPlan(
            schemaIdentity: AnalyzerTargetPlan.schemaIdentity,
            schemaVersion: AnalyzerTargetPlan.currentVersion,
            compilerLogSha256: String(repeating: "c", count: 64),
            workingDirectory: fixture.directory.path,
            rules: ["unused_import"],
            targets: [
                .init(
                    targetId: "fixture",
                    moduleName: "Fixture",
                    sourceRoot: ".",
                    compileCommandsPath: compileCommandsURL.lastPathComponent,
                    compileCommandsSha256: AnalyzerTargetPlan.sha256(compileCommandsData),
                    sourceFiles: sourceFiles,
                    sourceFilesSha256: AnalyzerTargetPlan.sourceInventoryDigest(sourceFiles),
                    rulePlans: [
                        .init(
                            rule: "unused_import",
                            mode: .batches,
                            batches: [.init(batchIndex: 0, requestedPaths: sourceFiles)]
                        ),
                    ]
                ),
            ]
        )
        let planURL = fixture.directory.appending(path: "target-plan.json")
        try AnalyzerJSON.encoder.encode(plan).write(to: planURL)
        let reporterURL = fixture.directory.appending(path: "reporter.json")
        let evidenceURL = fixture.directory.appending(path: "execution-evidence.json")

        let process = Process()
        process.executableURL = try testSwiftLintExecutable()
        process.currentDirectoryURL = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        process.arguments = [
            "analyze",
            "--target-plan", planURL.path,
            "--jobs", "1",
            "--execution-evidence", evidenceURL.path,
            "--only-rule", "unused_import",
            "--reporter", "json",
            "--output", reporterURL.path,
            "--quiet",
        ]
        let standardOutput = Pipe()
        let standardError = Pipe()
        process.standardOutput = standardOutput
        process.standardError = standardError
        try process.run()
        process.waitUntilExit()

        let diagnostics = String(
            data: standardError.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""
        #expect(process.terminationStatus == 0, Comment(rawValue: diagnostics))
        #expect(
            try Data(contentsOf: reporterURL)
                == Data((JSONReporter.generateReport([]) + "\n").utf8)
        )
        let evidence = try JSONDecoder().decode(
            AnalyzerExecutionEvidence.self,
            from: Data(contentsOf: evidenceURL)
        )
        #expect(evidence.schemaIdentity == AnalyzerExecutionEvidence.schemaIdentity)
        #expect(evidence.jobsRequested == 1)
        #expect(evidence.peakConcurrentJobs == 1)
        #expect(evidence.workers.map(\.jobId) == ["fixture/unused_import/batch-000"])
        #expect(evidence.findingsCount == 0)
    }
    // swiftlint:enable function_body_length
}
// swiftlint:enable type_body_length

struct InvalidPlanMutation: Sendable, CustomTestStringConvertible {
    let name: String
    let mutate: @Sendable (inout AnalyzerTargetPlan) -> Void

    var testDescription: String { name }
}

private func invalidPlanMutations() -> [InvalidPlanMutation] {
    [
        .init(name: "missing path") { plan in
            plan.targets[0].rulePlans[1].batches[1].requestedPaths = []
        },
        .init(name: "duplicate path") { plan in
            plan.targets[0].rulePlans[1].batches[1].requestedPaths = ["Sources/B.swift", "Sources/C.swift"]
        },
        .init(name: "overlapping path") { plan in
            plan.targets[0].rulePlans[1].batches[0].requestedPaths.append("Sources/C.swift")
        },
        .init(name: "extra path") { plan in
            plan.targets[0].rulePlans[1].batches[1].requestedPaths.append("Sources/Unexpected.swift")
        },
        .init(name: "duplicate batch index") { plan in
            plan.targets[0].rulePlans[1].batches[1].batchIndex = 0
        },
    ]
}

private func targetPlan() -> AnalyzerTargetPlan {
    let applicationSources = ["Sources/A.swift", "Sources/B.swift", "Sources/C.swift"]
    let unitTestSources = ["Tests/A.swift"]
    return AnalyzerTargetPlan(
        schemaIdentity: AnalyzerTargetPlan.schemaIdentity,
        schemaVersion: AnalyzerTargetPlan.currentVersion,
        compilerLogSha256: String(repeating: "c", count: 64),
        workingDirectory: "ios",
        rules: ["capture_variable", "unused_import"],
        targets: [
            .init(
                targetId: "application",
                moduleName: "FixtureApp",
                sourceRoot: "Sources",
                compileCommandsPath: "application.compile-commands.json",
                compileCommandsSha256: String(repeating: "a", count: 64),
                sourceFiles: applicationSources,
                sourceFilesSha256: AnalyzerTargetPlan.sourceInventoryDigest(applicationSources),
                rulePlans: [
                    .init(rule: "capture_variable", mode: .wholeTarget, batches: []),
                    .init(rule: "unused_import", mode: .batches, batches: [
                        .init(batchIndex: 0, requestedPaths: Array(applicationSources.prefix(2))),
                        .init(batchIndex: 1, requestedPaths: Array(applicationSources.suffix(1))),
                    ]),
                ]
            ),
            .init(
                targetId: "unitTests",
                moduleName: "FixtureAppTests",
                sourceRoot: "Tests",
                compileCommandsPath: "unitTests.compile-commands.json",
                compileCommandsSha256: String(repeating: "b", count: 64),
                sourceFiles: unitTestSources,
                sourceFilesSha256: AnalyzerTargetPlan.sourceInventoryDigest(unitTestSources),
                rulePlans: [
                    .init(rule: "capture_variable", mode: .wholeTarget, batches: []),
                    .init(rule: "unused_import", mode: .batches, batches: [
                        .init(batchIndex: 0, requestedPaths: unitTestSources),
                    ]),
                ]
            ),
        ]
    )
}

private func capabilities() -> [String: AnalyzerRuleCapability] {
    [
        "capture_variable": .init(isCollecting: true, maximumBatchSize: nil),
        "unused_import": .init(isCollecting: false, maximumBatchSize: 32),
    ]
}

private func analyzeOptions() -> LintOrAnalyzeOptions {
    LintOrAnalyzeOptions(
        mode: .analyze,
        paths: [URL(filePath: "/tmp/Sources")],
        useSTDIN: false,
        configurationFiles: [],
        strict: false,
        lenient: false,
        forceExclude: false,
        useExcludingByPrefix: false,
        useScriptInputFiles: false,
        useScriptInputFileLists: false,
        benchmark: false,
        reporter: "json",
        baseline: nil,
        writeBaseline: nil,
        workingDirectory: nil,
        quiet: true,
        output: nil,
        progress: false,
        cachePath: nil,
        ignoreCache: true,
        enableAllRules: false,
        onlyRule: [],
        autocorrect: false,
        format: false,
        disableSourceKit: false,
        compilerLogPath: nil,
        compileCommands: nil,
        checkForUpdates: false
    )
}

private func workerResult(job: AnalyzerJob) -> AnalyzerWorkerResult {
    AnalyzerWorkerResult(
        schemaIdentity: AnalyzerWorkerResult.schemaIdentity,
        schemaVersion: AnalyzerWorkerResult.currentVersion,
        workerId: job.workerId,
        jobId: job.jobId,
        targetId: job.targetId,
        ruleIdentifier: job.ruleIdentifier,
        batchIndex: job.batchIndex,
        requestedPaths: job.requestedPaths,
        compileCommandsSha256: job.compileCommandsSha256,
        violations: [],
        files: job.requestedPaths.map { URL(filePath: $0) },
        fileTimings: [],
        ruleTimings: [],
        startOffsetSeconds: 0,
        durationSeconds: 1,
        exitCode: 0
    )
}

private func violation(rule: String, file: String, line: Int) -> StyleViolation {
    StyleViolation(
        ruleDescription: RuleDescription(identifier: rule, name: rule, description: rule, kind: .lint),
        location: Location(file: URL(filePath: file), line: line, character: 1)
    )
}

private enum TestWorkerError: Error {
    case failed
}

private actor ConcurrencyProbe {
    private var activeJobs = 0
    private(set) var maximumActiveJobs = 0

    func started() {
        activeJobs += 1
        maximumActiveJobs = max(maximumActiveJobs, activeJobs)
    }

    func finished() {
        activeJobs -= 1
    }
}

private actor CancellationProbe {
    private var startedRequests = Set<Int>()
    private var startWaiters = [CheckedContinuation<Void, Never>]()
    private var cancellationWaiters = [Int: [CheckedContinuation<Void, Never>]]()
    private(set) var cancelledRequests = Set<Int>()

    func started(_ request: Int) {
        startedRequests.insert(request)
        guard startedRequests.count == 2 else { return }
        startWaiters.forEach { $0.resume() }
        startWaiters.removeAll()
    }

    func waitUntilBothStarted() async {
        guard startedRequests.count < 2 else { return }
        await withCheckedContinuation { continuation in
            startWaiters.append(continuation)
        }
    }

    func cancelled(_ request: Int) {
        cancelledRequests.insert(request)
        cancellationWaiters.removeValue(forKey: request)?.forEach { $0.resume() }
    }

    func waitUntilCancelled(_ request: Int) async {
        guard !cancelledRequests.contains(request) else { return }
        await withCheckedContinuation { continuation in
            cancellationWaiters[request, default: []].append(continuation)
        }
    }
}

private struct ProcessFixture {
    let directory: URL

    init(suffix: String = "") throws {
        directory = FileManager.default.temporaryDirectory.appending(
            path: "swiftlint-process-runner-tests-\(UUID().uuidString)\(suffix)",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }

    func runner() -> AnalyzerWorkerProcessRunner {
        AnalyzerWorkerProcessRunner(
            executableURL: URL(filePath: "/bin/sh"),
            currentDirectoryURL: directory,
            environment: ProcessInfo.processInfo.environment
        )
    }

    func invocation(jobId: String, script: String) -> AnalyzerWorkerInvocation {
        let identifier = jobId.replacingOccurrences(of: "/", with: "-")
        let requestURL = directory.appending(path: "\(identifier)-request.json")
        let resultURL = directory.appending(path: "\(identifier)-result.json")
        let standardOutputURL = directory.appending(path: "\(identifier)-stdout.txt")
        let standardErrorURL = directory.appending(path: "\(identifier)-stderr.txt")
        FileManager.default.createFile(atPath: standardOutputURL.path, contents: nil)
        FileManager.default.createFile(atPath: standardErrorURL.path, contents: nil)
        var environment = ProcessInfo.processInfo.environment
        environment["PID_FILE"] = directory.appending(path: jobId.contains("forwarded")
            ? "forwarded-descendant.pid"
            : "descendant.pid").path
        return AnalyzerWorkerInvocation(
            jobId: jobId,
            requestURL: requestURL,
            resultURL: resultURL,
            standardOutputURL: standardOutputURL,
            standardErrorURL: standardErrorURL,
            arguments: ["-c", script],
            environment: environment
        )
    }
}

private func waitForProcessIdentifier(at url: URL) async throws -> pid_t {
    for _ in 0..<200 {
        if let contents = try? String(contentsOf: url, encoding: .utf8),
           let processIdentifier = pid_t(contents) {
            return processIdentifier
        }
        try await Task.sleep(for: .milliseconds(10))
    }
    throw TestProcessError.pidNotWritten
}

private func platformCompilerContextArguments() throws -> [String] {
    #if os(macOS)
    let process = Process()
    process.executableURL = URL(filePath: "/usr/bin/xcrun")
    process.arguments = ["--sdk", "macosx", "--show-sdk-path"]
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0,
          let sdkRoot = String(
              data: output.fileHandleForReading.readDataToEndOfFile(),
              encoding: .utf8
          )?.trimmingCharacters(in: .whitespacesAndNewlines),
          !sdkRoot.isEmpty else {
        throw AnalyzerProcessRunnerError.invalidExecutable("macOS SDK")
    }
    #if arch(arm64)
    let target = "arm64-apple-macos14.0"
    #elseif arch(x86_64)
    let target = "x86_64-apple-macos14.0"
    #endif
    return ["-target", target, "-sdk", sdkRoot]
    #else
    return []
    #endif
}

private func testSwiftLintExecutable() throws -> URL {
    let packageRoot = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let candidates = [
        Bundle.main.bundleURL.deletingLastPathComponent().appending(path: "swiftlint"),
        packageRoot.appending(path: ".build/debug/swiftlint"),
    ]
    guard let executable = candidates.first(where: {
        FileManager.default.isExecutableFile(atPath: $0.path)
    }) else {
        throw AnalyzerProcessRunnerError.invalidExecutable("swiftlint test product")
    }
    return executable
}

private func processExits(_ processIdentifier: pid_t) async -> Bool {
    for _ in 0..<200 {
        if kill(processIdentifier, 0) == -1, errno == ESRCH {
            return true
        }
        #if canImport(Glibc)
        if let stat = try? String(contentsOfFile: "/proc/\(processIdentifier)/stat", encoding: .utf8),
           let commandEnd = stat.range(of: ")", options: .backwards)?.upperBound {
            let fields = stat[commandEnd...].split(whereSeparator: \.isWhitespace)
            if fields.first == "Z" || fields.first == "X" {
                return true
            }
        }
        #endif
        try? await Task.sleep(for: .milliseconds(10))
    }
    return false
}

private enum TestProcessError: Error {
    case pidNotWritten
}
