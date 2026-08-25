import Foundation
@preconcurrency import SwiftLintCore

// Versioned plan, worker, aggregate, and evidence schemas intentionally share one owned protocol file.
// swiftlint:disable file_length

package struct AnalyzerRuleCapability: Equatable, Sendable {
    package let isCollecting: Bool
    package let maximumBatchSize: Int?

    package init(isCollecting: Bool, maximumBatchSize: Int?) {
        self.isCollecting = isCollecting
        self.maximumBatchSize = maximumBatchSize
    }
}

package struct AnalyzerTargetPlan: Codable, Equatable, Sendable {
    package static let schemaIdentity = "swiftlint-analyzer-target-plan"
    package static let currentVersion = 1

    package struct Target: Codable, Equatable, Sendable {
        package var targetId: String
        package var moduleName: String
        package var sourceRoot: String
        package var compileCommandsPath: String
        package var compileCommandsSha256: String
        package var sourceFiles: [String]
        package var sourceFilesSha256: String
        package var rulePlans: [RulePlan]

        package init(
            targetId: String,
            moduleName: String,
            sourceRoot: String,
            compileCommandsPath: String,
            compileCommandsSha256: String,
            sourceFiles: [String],
            sourceFilesSha256: String,
            rulePlans: [RulePlan]
        ) {
            self.targetId = targetId
            self.moduleName = moduleName
            self.sourceRoot = sourceRoot
            self.compileCommandsPath = compileCommandsPath
            self.compileCommandsSha256 = compileCommandsSha256
            self.sourceFiles = sourceFiles
            self.sourceFilesSha256 = sourceFilesSha256
            self.rulePlans = rulePlans
        }
    }

    package struct RulePlan: Codable, Equatable, Sendable {
        // swiftlint:disable:next nesting
        package enum Mode: String, Codable, Sendable {
            // swiftlint:disable:next redundant_string_enum_value
            case wholeTarget = "wholeTarget"
            case batches
        }

        package var rule: String
        package var mode: Mode
        package var batches: [Batch]

        package init(rule: String, mode: Mode, batches: [Batch]) {
            self.rule = rule
            self.mode = mode
            self.batches = batches
        }
    }

    package struct Batch: Codable, Equatable, Sendable {
        package var batchIndex: Int
        package var requestedPaths: [String]

        package init(batchIndex: Int, requestedPaths: [String]) {
            self.batchIndex = batchIndex
            self.requestedPaths = requestedPaths
        }
    }

    package var schemaIdentity: String
    package var schemaVersion: Int
    package var compilerLogSha256: String
    package var workingDirectory: String
    package var rules: [String]
    package var targets: [Target]

    package init(
        schemaIdentity: String,
        schemaVersion: Int,
        compilerLogSha256: String,
        workingDirectory: String,
        rules: [String],
        targets: [Target]
    ) {
        self.schemaIdentity = schemaIdentity
        self.schemaVersion = schemaVersion
        self.compilerLogSha256 = compilerLogSha256
        self.workingDirectory = workingDirectory
        self.rules = rules
        self.targets = targets
    }

    package static func sourceInventoryDigest(_ paths: [String]) -> String {
        var data: Data
        do {
            data = try AnalyzerJSON.encoder.encode(paths)
        } catch {
            preconditionFailure("String arrays must be JSON encodable: \(error)")
        }
        data.append(0x0a)
        return AnalyzerSHA256.hexDigest(data)
    }

    package static func sha256(_ data: Data) -> String {
        AnalyzerSHA256.hexDigest(data)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    package func validatedJobGraph(capabilities: [String: AnalyzerRuleCapability]) throws -> [AnalyzerJob] {
        guard schemaIdentity == Self.schemaIdentity, schemaVersion == Self.currentVersion else {
            throw AnalyzerTargetPlanError.invalidSchema
        }
        guard Self.isSHA256(compilerLogSha256), !workingDirectory.isEmpty else {
            throw AnalyzerTargetPlanError.invalidProvenance
        }
        try Self.requireUniqueNonempty(rules, label: "rule")
        guard Set(capabilities.keys) == Set(rules) else {
            throw AnalyzerTargetPlanError.ruleCapabilityMismatch
        }
        try Self.requireUniqueNonempty(targets.map(\.targetId), label: "target")

        var jobs = [AnalyzerJob]()
        for target in targets {
            guard !target.moduleName.isEmpty,
                  !target.sourceRoot.isEmpty,
                  !target.compileCommandsPath.isEmpty,
                  Self.isSHA256(target.compileCommandsSha256),
                  target.sourceFiles.isNotEmpty,
                  target.sourceFiles == target.sourceFiles.sorted(),
                  target.sourceFilesSha256 == Self.sourceInventoryDigest(target.sourceFiles) else {
                throw AnalyzerTargetPlanError.invalidTarget(target.targetId)
            }
            try Self.requireUniqueNonempty(target.sourceFiles, label: "source path")
            guard target.rulePlans.map(\.rule) == rules else {
                throw AnalyzerTargetPlanError.rulePlanMismatch(target.targetId)
            }

            for rulePlan in target.rulePlans {
                guard let capability = capabilities[rulePlan.rule] else {
                    throw AnalyzerTargetPlanError.ruleCapabilityMismatch
                }
                switch rulePlan.mode {
                case .wholeTarget:
                    guard rulePlan.batches.isEmpty else {
                        throw AnalyzerTargetPlanError.invalidBatches(target: target.targetId, rule: rulePlan.rule)
                    }
                    jobs.append(
                        AnalyzerJob(
                            workerId: "",
                            jobId: "\(target.targetId)/\(rulePlan.rule)",
                            targetId: target.targetId,
                            moduleName: target.moduleName,
                            sourceRoot: target.sourceRoot,
                            ruleIdentifier: rulePlan.rule,
                            batchIndex: nil,
                            requestedPaths: target.sourceFiles,
                            targetSourcePaths: target.sourceFiles,
                            compileCommandsPath: target.compileCommandsPath,
                            compileCommandsSha256: target.compileCommandsSha256
                        )
                    )
                case .batches:
                    guard !capability.isCollecting,
                          let maximumBatchSize = capability.maximumBatchSize,
                          maximumBatchSize > 0,
                          rulePlan.batches.isNotEmpty else {
                        throw AnalyzerTargetPlanError.unsafeBatching(rulePlan.rule)
                    }
                    let expectedIndices = Array(rulePlan.batches.indices)
                    guard rulePlan.batches.map(\.batchIndex) == expectedIndices,
                          rulePlan.batches.allSatisfy({
                              !$0.requestedPaths.isEmpty && $0.requestedPaths.count <= maximumBatchSize
                          }),
                          rulePlan.batches.flatMap(\.requestedPaths) == target.sourceFiles else {
                        throw AnalyzerTargetPlanError.invalidBatches(target: target.targetId, rule: rulePlan.rule)
                    }
                    for batch in rulePlan.batches {
                        jobs.append(
                            AnalyzerJob(
                                workerId: "",
                                jobId: "\(target.targetId)/\(rulePlan.rule)/batch-"
                                    + String(format: "%03d", batch.batchIndex),
                                targetId: target.targetId,
                                moduleName: target.moduleName,
                                sourceRoot: target.sourceRoot,
                                ruleIdentifier: rulePlan.rule,
                                batchIndex: batch.batchIndex,
                                requestedPaths: batch.requestedPaths,
                                targetSourcePaths: target.sourceFiles,
                                compileCommandsPath: target.compileCommandsPath,
                                compileCommandsSha256: target.compileCommandsSha256
                            )
                        )
                    }
                }
            }
        }

        return jobs.enumerated().map { index, job in
            var job = job
            job.workerId = "worker-\(String(format: "%04d", index))"
            return job
        }
    }

    private static func requireUniqueNonempty(_ values: [String], label: String) throws {
        guard values.allSatisfy({ !$0.isEmpty }), Set(values).count == values.count else {
            throw AnalyzerTargetPlanError.duplicateIdentity(label)
        }
    }

    private static func isSHA256(_ value: String) -> Bool {
        value.count == 64 && value.allSatisfy(\.isHexDigit)
    }
}

package enum AnalyzerTargetPlanError: LocalizedError, Equatable {
    case invalidSchema
    case invalidProvenance
    case duplicateIdentity(String)
    case ruleCapabilityMismatch
    case invalidTarget(String)
    case rulePlanMismatch(String)
    case unsafeBatching(String)
    case invalidBatches(target: String, rule: String)

    package var errorDescription: String? {
        switch self {
        case .invalidSchema:
            "Unsupported analyzer target-plan schema."
        case .invalidProvenance:
            "Analyzer target-plan provenance is invalid."
        case .duplicateIdentity(let identity):
            "Analyzer target plan contains an empty or duplicate \(identity)."
        case .ruleCapabilityMismatch:
            "Analyzer target-plan rules do not match configured analyzer capabilities."
        case .invalidTarget(let target):
            "Analyzer target '\(target)' has invalid source or compilation-database provenance."
        case .rulePlanMismatch(let target):
            "Analyzer target '\(target)' does not contain the exact configured rule order."
        case .unsafeBatching(let rule):
            "Analyzer rule '\(rule)' does not explicitly permit batching."
        case let .invalidBatches(target, rule):
            "Analyzer batches for '\(target)/\(rule)' do not exactly partition the target source inventory."
        }
    }
}

package struct AnalyzerJob: Codable, Equatable, Sendable {
    package var workerId: String
    package var jobId: String
    package let targetId: String
    package let moduleName: String
    package let sourceRoot: String
    package let ruleIdentifier: String
    package let batchIndex: Int?
    package let requestedPaths: [String]
    package let targetSourcePaths: [String]
    package var compileCommandsPath: String
    package let compileCommandsSha256: String
}

package struct AnalyzerProcessCoordinator<Input: Sendable, Output: Sendable>: Sendable {
    private let jobs: Int
    private let operation: @Sendable (Input) async throws -> Output

    package init(jobs: Int, operation: @escaping @Sendable (Input) async throws -> Output) {
        self.jobs = jobs
        self.operation = operation
    }

    package func run(_ inputs: [Input]) async throws -> [Output] {
        guard jobs > 0 else {
            throw AnalyzerWorkerContractError.invalidJobs(jobs)
        }
        guard inputs.isNotEmpty else { return [] }

        return try await withThrowingTaskGroup(of: (Int, Output).self) { group in
            var nextIndex = 0
            var outputs = [Int: Output]()

            func addNext() {
                let index = nextIndex
                nextIndex += 1
                let input = inputs[index]
                group.addTask {
                    try Task.checkCancellation()
                    return (index, try await operation(input))
                }
            }

            for _ in 0..<min(jobs, inputs.count) {
                addNext()
            }

            do {
                while let (index, output) = try await group.next() {
                    outputs[index] = output
                    if nextIndex < inputs.count {
                        addNext()
                    }
                }
            } catch {
                group.cancelAll()
                throw error
            }

            return try inputs.indices.map { index in
                guard let output = outputs[index] else {
                    throw AnalyzerWorkerContractError.missingJob("index \(index)")
                }
                return output
            }
        }
    }
}

package struct AnalyzerWorkerOptions: Codable, Equatable, Sendable {
    package let configurationFiles: [URL]
    package let strict: Bool
    package let lenient: Bool
    package let forceExclude: Bool
    package let useExcludingByPrefix: Bool
    package let reporter: String?
    package let benchmark: Bool
    package let quiet: Bool
    package let disableSourceKit: Bool
    package let autocorrect: Bool

    init(_ options: LintOrAnalyzeOptions) {
        configurationFiles = options.configurationFiles
        strict = options.strict
        lenient = options.lenient
        forceExclude = options.forceExclude
        useExcludingByPrefix = options.useExcludingByPrefix
        reporter = options.reporter
        benchmark = options.benchmark
        quiet = options.quiet
        disableSourceKit = options.disableSourceKit
        autocorrect = options.autocorrect
    }
}

package struct AnalyzerWorkerRequest: Codable, Equatable, Sendable {
    package static let schemaIdentity = "swiftlint-analyzer-worker-request"
    package static let currentVersion = 1

    package var schemaIdentity: String
    package var schemaVersion: Int
    package var workerId: String
    package var jobId: String
    package var targetId: String
    package var moduleName: String
    package var sourceRoot: String
    package var ruleIdentifier: String
    package var batchIndex: Int?
    package var requestedPaths: [String]
    package var targetSourcePaths: [String]
    package var compileCommandsPath: String
    package var compileCommandsSha256: String
    package var options: AnalyzerWorkerOptions
    package var resultURL: URL

    package init(job: AnalyzerJob, options: LintOrAnalyzeOptions, resultURL: URL) {
        schemaIdentity = Self.schemaIdentity
        schemaVersion = Self.currentVersion
        workerId = job.workerId
        jobId = job.jobId
        targetId = job.targetId
        moduleName = job.moduleName
        sourceRoot = job.sourceRoot
        ruleIdentifier = job.ruleIdentifier
        batchIndex = job.batchIndex
        requestedPaths = job.requestedPaths
        targetSourcePaths = job.targetSourcePaths
        compileCommandsPath = job.compileCommandsPath
        compileCommandsSha256 = job.compileCommandsSha256
        self.options = AnalyzerWorkerOptions(options)
        self.resultURL = resultURL
    }

    package func validate(for job: AnalyzerJob) throws {
        guard schemaIdentity == Self.schemaIdentity,
              schemaVersion == Self.currentVersion,
              workerId == job.workerId,
              jobId == job.jobId,
              targetId == job.targetId,
              moduleName == job.moduleName,
              sourceRoot == job.sourceRoot,
              ruleIdentifier == job.ruleIdentifier,
              batchIndex == job.batchIndex,
              requestedPaths == job.requestedPaths,
              targetSourcePaths == job.targetSourcePaths,
              compileCommandsPath == job.compileCommandsPath,
              compileCommandsSha256 == job.compileCommandsSha256 else {
            throw AnalyzerWorkerContractError.requestMismatch(job.jobId)
        }
    }

    package func validate() throws {
        guard schemaIdentity == Self.schemaIdentity,
              schemaVersion == Self.currentVersion,
              !workerId.isEmpty,
              !jobId.isEmpty,
              !targetId.isEmpty,
              !moduleName.isEmpty,
              !sourceRoot.isEmpty,
              !ruleIdentifier.isEmpty,
              !requestedPaths.isEmpty,
              !targetSourcePaths.isEmpty,
              Set(requestedPaths).count == requestedPaths.count,
              Set(targetSourcePaths).count == targetSourcePaths.count,
              requestedPaths.allSatisfy(Set(targetSourcePaths).contains),
              compileCommandsSha256.count == 64,
              compileCommandsSha256.allSatisfy(\.isHexDigit),
              !resultURL.path.isEmpty else {
            throw AnalyzerWorkerContractError.requestMismatch(jobId)
        }
        if let batchIndex {
            guard batchIndex >= 0,
                  jobId.hasSuffix("/batch-\(String(format: "%03d", batchIndex))") else {
                throw AnalyzerWorkerContractError.requestMismatch(jobId)
            }
        } else {
            guard requestedPaths == targetSourcePaths else {
                throw AnalyzerWorkerContractError.requestMismatch(jobId)
            }
        }
    }
}

package struct AnalyzerFileTiming: Codable, Equatable, Sendable {
    package let path: String
    package let seconds: Double
}

package struct AnalyzerRuleTiming: Codable, Equatable, Sendable {
    package let ruleIdentifier: String
    package let seconds: Double
}

package struct AnalyzerWorkerResult: Codable, Equatable, Sendable {
    package static let schemaIdentity = "swiftlint-analyzer-worker-result"
    package static let currentVersion = 1

    package var schemaIdentity: String
    package var schemaVersion: Int
    package var workerId: String
    package var jobId: String
    package var targetId: String
    package var ruleIdentifier: String
    package var batchIndex: Int?
    package var requestedPaths: [String]
    package var compileCommandsSha256: String
    package var violations: [StyleViolation]
    package var files: [URL]
    package var fileTimings: [AnalyzerFileTiming]
    package var ruleTimings: [AnalyzerRuleTiming]
    package var startOffsetSeconds: Double
    package var durationSeconds: Double
    package var exitCode: Int32

    package init(
        schemaIdentity: String,
        schemaVersion: Int,
        workerId: String,
        jobId: String,
        targetId: String,
        ruleIdentifier: String,
        batchIndex: Int?,
        requestedPaths: [String],
        compileCommandsSha256: String,
        violations: [StyleViolation],
        files: [URL],
        fileTimings: [AnalyzerFileTiming],
        ruleTimings: [AnalyzerRuleTiming],
        startOffsetSeconds: Double,
        durationSeconds: Double,
        exitCode: Int32
    ) {
        self.schemaIdentity = schemaIdentity
        self.schemaVersion = schemaVersion
        self.workerId = workerId
        self.jobId = jobId
        self.targetId = targetId
        self.ruleIdentifier = ruleIdentifier
        self.batchIndex = batchIndex
        self.requestedPaths = requestedPaths
        self.compileCommandsSha256 = compileCommandsSha256
        self.violations = violations
        self.files = files
        self.fileTimings = fileTimings
        self.ruleTimings = ruleTimings
        self.startOffsetSeconds = startOffsetSeconds
        self.durationSeconds = durationSeconds
        self.exitCode = exitCode
    }

    // swiftlint:disable:next cyclomatic_complexity
    package func validate(for job: AnalyzerJob) throws {
        guard schemaIdentity == Self.schemaIdentity else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [schemaIdentity]")
        }
        guard schemaVersion == Self.currentVersion else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [schemaVersion]")
        }
        guard workerId == job.workerId else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [workerId]")
        }
        guard jobId == job.jobId else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [jobId]")
        }
        guard targetId == job.targetId else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [targetId]")
        }
        guard ruleIdentifier == job.ruleIdentifier else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [ruleIdentifier]")
        }
        guard batchIndex == job.batchIndex else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [batchIndex]")
        }
        guard requestedPaths == job.requestedPaths else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [requestedPaths]")
        }
        guard compileCommandsSha256 == job.compileCommandsSha256 else {
            throw AnalyzerWorkerContractError.resultMismatch("\(job.jobId) [compileCommandsSha256]")
        }
        guard exitCode == 0 else {
            throw AnalyzerWorkerContractError.workerFailed(
                job: job.jobId,
                reason: "exit \(exitCode)",
                diagnostics: "Worker result reported a nonzero exit."
            )
        }
        guard durationSeconds.isFinite, durationSeconds >= 0,
              startOffsetSeconds.isFinite, startOffsetSeconds >= 0 else {
            throw AnalyzerWorkerContractError.invalidTiming(job.jobId)
        }
    }
}

package struct AnalyzerWorkerAggregate: Equatable, Sendable {
    package let violations: [StyleViolation]
    package let files: [URL]
    package let fileTimings: [AnalyzerFileTiming]
    package let ruleTimings: [AnalyzerRuleTiming]

    package static func merge(graph: [AnalyzerJob], results: [AnalyzerWorkerResult]) throws -> Self {
        guard graph.count == results.count else {
            throw AnalyzerWorkerContractError.jobCount(expected: graph.count, actual: results.count)
        }
        guard Set(graph.map(\.workerId)).count == graph.count,
              Set(graph.map(\.jobId)).count == graph.count,
              Set(results.map(\.workerId)).count == results.count,
              Set(results.map(\.jobId)).count == results.count else {
            throw AnalyzerWorkerContractError.duplicateIdentity
        }

        let resultByJob = Dictionary(uniqueKeysWithValues: results.map { ($0.jobId, $0) })
        let orderedResults = try graph.map { job in
            guard let result = resultByJob[job.jobId] else {
                throw AnalyzerWorkerContractError.missingJob(job.jobId)
            }
            try result.validate(for: job)
            return result
        }
        guard Set(resultByJob.keys) == Set(graph.map(\.jobId)) else {
            throw AnalyzerWorkerContractError.extraJob
        }

        let rawViolations = orderedResults.flatMap(\.violations)
        guard Set(rawViolations).count == rawViolations.count else {
            throw AnalyzerWorkerContractError.duplicateRawFinding
        }

        return Self(
            violations: rawViolations.sorted(by: violationOrder),
            files: orderedUnique(orderedResults.flatMap(\.files)),
            fileTimings: orderedResults.flatMap(\.fileTimings),
            ruleTimings: orderedResults.flatMap(\.ruleTimings)
        )
    }

    private static func violationOrder(_ lhs: StyleViolation, _ rhs: StyleViolation) -> Bool {
        if lhs.location != rhs.location { return lhs.location < rhs.location }
        if lhs.ruleIdentifier != rhs.ruleIdentifier { return lhs.ruleIdentifier < rhs.ruleIdentifier }
        if lhs.reason != rhs.reason { return lhs.reason < rhs.reason }
        return lhs.severity.rawValue < rhs.severity.rawValue
    }

    private static func orderedUnique<T: Hashable>(_ values: [T]) -> [T] {
        var seen = Set<T>()
        return values.filter { seen.insert($0).inserted }
    }
}

private struct AnalyzerCanonicalFinding: Codable {
    let file: String?
    let line: Int?
    let character: Int?
    let severity: String
    let type: String
    let ruleId: String
    let reason: String

    enum CodingKeys: String, CodingKey {
        case file, line, character, severity, type, reason
        case ruleId = "rule_id"
    }
}

package struct AnalyzerExecutionEvidence: Codable, Equatable, Sendable {
    package static let schemaIdentity = "swiftlint-analyzer-execution-evidence"
    package static let currentVersion = 1

    package struct Worker: Codable, Equatable, Sendable {
        package let workerId: String
        package let jobId: String
        package let targetId: String
        package let ruleIdentifier: String
        package let batchIndex: Int?
        package let requestedPaths: [String]
        package let compileCommandsSha256: String
        package let startOffsetSeconds: Double
        package let durationSeconds: Double
        package let exitCode: Int32
        package let rawFindingCount: Int
    }

    package struct Topology: Codable, Equatable, Sendable {
        package let targetCount: Int
        package let ruleCount: Int
        package let wholeTargetJobCount: Int
        package let batchedJobCount: Int
        package let totalJobCount: Int
        package let jobOrder: [String]
    }

    package var schemaIdentity: String
    package var schemaVersion: Int
    package var targetPlanSha256: String
    package var jobsRequested: Int
    package var peakConcurrentJobs: Int
    package var peakChildResidentMemoryBytes: UInt64
    package var elapsedSeconds: Double
    package var topology: Topology
    package var workers: [Worker]
    package var findingsCount: Int
    package var findingsSha256: String
    package var reporterOutputSha256: String

    // swiftlint:disable:next function_parameter_count
    package static func make(
        targetPlanSha256: String,
        jobsRequested: Int,
        peakConcurrentJobs: Int,
        peakChildResidentMemoryBytes: UInt64,
        elapsedSeconds: Double,
        graph: [AnalyzerJob],
        results: [AnalyzerWorkerResult],
        findings: [StyleViolation],
        reporterOutput: Data,
        workingDirectory: URL = .cwd
    ) throws -> Self {
        _ = try AnalyzerWorkerAggregate.merge(graph: graph, results: results)
        let resultByJob = Dictionary(uniqueKeysWithValues: results.map { ($0.jobId, $0) })
        return Self(
            schemaIdentity: schemaIdentity,
            schemaVersion: currentVersion,
            targetPlanSha256: targetPlanSha256,
            jobsRequested: jobsRequested,
            peakConcurrentJobs: peakConcurrentJobs,
            peakChildResidentMemoryBytes: peakChildResidentMemoryBytes,
            elapsedSeconds: elapsedSeconds,
            topology: Topology(
                targetCount: Set(graph.map(\.targetId)).count,
                ruleCount: Set(graph.map(\.ruleIdentifier)).count,
                wholeTargetJobCount: graph.filter({ $0.batchIndex == nil }).count,
                batchedJobCount: graph.filter({ $0.batchIndex != nil }).count,
                totalJobCount: graph.count,
                jobOrder: graph.map(\.jobId)
            ),
            workers: try graph.map { job in
                guard let result = resultByJob[job.jobId] else {
                    throw AnalyzerWorkerContractError.missingJob(job.jobId)
                }
                return Worker(
                    workerId: result.workerId,
                    jobId: result.jobId,
                    targetId: result.targetId,
                    ruleIdentifier: result.ruleIdentifier,
                    batchIndex: result.batchIndex,
                    requestedPaths: result.requestedPaths,
                    compileCommandsSha256: result.compileCommandsSha256,
                    startOffsetSeconds: result.startOffsetSeconds,
                    durationSeconds: result.durationSeconds,
                    exitCode: result.exitCode,
                    rawFindingCount: result.violations.count
                )
            },
            findingsCount: findings.count,
            findingsSha256: try digestFindings(findings, workingDirectory: workingDirectory),
            reporterOutputSha256: AnalyzerSHA256.hexDigest(reporterOutput)
        )
    }

    package func validate(graph: [AnalyzerJob], targetPlanSha256 expectedPlanDigest: String) throws {
        guard schemaIdentity == Self.schemaIdentity,
              schemaVersion == Self.currentVersion,
              targetPlanSha256 == expectedPlanDigest,
              jobsRequested > 0,
              peakConcurrentJobs > 0,
              peakConcurrentJobs <= jobsRequested,
              elapsedSeconds.isFinite,
              elapsedSeconds >= 0,
              topology == Topology(
                  targetCount: Set(graph.map(\.targetId)).count,
                  ruleCount: Set(graph.map(\.ruleIdentifier)).count,
                  wholeTargetJobCount: graph.filter({ $0.batchIndex == nil }).count,
                  batchedJobCount: graph.filter({ $0.batchIndex != nil }).count,
                  totalJobCount: graph.count,
                  jobOrder: graph.map(\.jobId)
              ),
              workers.count == graph.count,
              workers.map(\.workerId) == graph.map(\.workerId),
              workers.map(\.jobId) == graph.map(\.jobId),
              Set(workers.map(\.workerId)).count == workers.count,
              Set(workers.map(\.jobId)).count == workers.count else {
            throw AnalyzerWorkerContractError.evidenceMismatch
        }
        for (worker, job) in zip(workers, graph) {
            guard worker.targetId == job.targetId,
                  worker.ruleIdentifier == job.ruleIdentifier,
                  worker.batchIndex == job.batchIndex,
                  worker.requestedPaths == job.requestedPaths,
                  worker.compileCommandsSha256 == job.compileCommandsSha256,
                  worker.exitCode == 0,
                  worker.startOffsetSeconds.isFinite,
                  worker.startOffsetSeconds >= 0,
                  worker.durationSeconds.isFinite,
                  worker.durationSeconds >= 0,
                  worker.rawFindingCount >= 0 else {
                throw AnalyzerWorkerContractError.evidenceMismatch
            }
        }
    }

    private static func digestFindings(_ findings: [StyleViolation], workingDirectory: URL) throws -> String {
        let directoryPath = workingDirectory.standardizedFileURL.path
        let prefix = directoryPath.hasSuffix("/") ? directoryPath : directoryPath + "/"
        let canonical = findings.map { finding in
            let absolutePath = finding.location.file?.standardizedFileURL.path
            let file = absolutePath.map { path in
                path.hasPrefix(prefix) ? String(path.dropFirst(prefix.count)) : path
            }
            return AnalyzerCanonicalFinding(
                file: file,
                line: finding.location.line,
                character: finding.location.character,
                severity: finding.severity.rawValue.capitalized,
                type: finding.ruleName,
                ruleId: finding.ruleIdentifier,
                reason: finding.reason
            )
        }
        var data = try AnalyzerJSON.encoder.encode(canonical)
        data.append(0x0a)
        return AnalyzerSHA256.hexDigest(data)
    }
}

package enum AnalyzerWorkerContractError: LocalizedError, Equatable {
    case invalidJobs(Int)
    case requestMismatch(String)
    case resultMismatch(String)
    case duplicateIdentity
    case missingJob(String)
    case extraJob
    case jobCount(expected: Int, actual: Int)
    case duplicateRawFinding
    case findingsMismatch
    case evidenceMismatch
    case invalidTiming(String)
    case workerFailed(job: String, reason: String, diagnostics: String)

    package var errorDescription: String? {
        switch self {
        case .invalidJobs(let jobs):
            "Analyzer jobs must be positive; received \(jobs)."
        case .requestMismatch(let job):
            "Analyzer worker request does not match scheduled job '\(job)'."
        case .resultMismatch(let job):
            "Analyzer worker result does not match scheduled job '\(job)'."
        case .duplicateIdentity:
            "Analyzer workers contain a duplicate job or worker identity."
        case .missingJob(let job):
            "Analyzer worker result is missing scheduled job '\(job)'."
        case .extraJob:
            "Analyzer worker results contain an unscheduled job."
        case let .jobCount(expected, actual):
            "Analyzer worker result count \(actual) does not match scheduled job count \(expected)."
        case .duplicateRawFinding:
            "Analyzer workers produced an unexpected duplicate raw finding."
        case .findingsMismatch:
            "Analyzer evidence findings do not match the deterministic worker aggregate."
        case .evidenceMismatch:
            "Analyzer execution evidence does not match the scheduled target plan."
        case .invalidTiming(let job):
            "Analyzer worker '\(job)' reported an invalid timing."
        case let .workerFailed(job, reason, diagnostics):
            "Analyzer worker '\(job)' failed (\(reason)): \(diagnostics)"
        }
    }
}

private enum AnalyzerSHA256 {
    static func hexDigest(_ data: Data) -> String {
        hash(Array(data)).map { String(format: "%02x", $0) }.joined()
    }

    // FIPS 180-4 SHA-256. Kept local so the worker protocol hashes identically on macOS and Linux.
    // swiftlint:disable:next function_body_length
    private static func hash(_ bytes: [UInt8]) -> [UInt8] {
        let constants: [UInt32] = [
            0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
            0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
            0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
            0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
            0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
            0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
            0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
            0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
        ]
        var message = bytes
        let bitLength = UInt64(message.count) * 8
        message.append(0x80)
        while message.count % 64 != 56 { message.append(0) }
        message.append(contentsOf: withUnsafeBytes(of: bitLength.bigEndian, Array.init))

        var state: [UInt32] = [
            0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
            0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
        ]
        for offset in stride(from: 0, to: message.count, by: 64) {
            var words = [UInt32](repeating: 0, count: 64)
            for index in 0..<16 {
                let start = offset + index * 4
                words[index] = UInt32(message[start]) << 24
                    | UInt32(message[start + 1]) << 16
                    | UInt32(message[start + 2]) << 8
                    | UInt32(message[start + 3])
            }
            for index in 16..<64 {
                let value15 = words[index - 15]
                let value2 = words[index - 2]
                let sigma0 = value15.rotateRight(7) ^ value15.rotateRight(18) ^ (value15 >> 3)
                let sigma1 = value2.rotateRight(17) ^ value2.rotateRight(19) ^ (value2 >> 10)
                words[index] = words[index - 16] &+ sigma0 &+ words[index - 7] &+ sigma1
            }

            var working0 = state[0]
            var working1 = state[1]
            var working2 = state[2]
            var working3 = state[3]
            var working4 = state[4]
            var working5 = state[5]
            var working6 = state[6]
            var working7 = state[7]
            for index in 0..<64 {
                let sum1 = working4.rotateRight(6) ^ working4.rotateRight(11) ^ working4.rotateRight(25)
                let choose = (working4 & working5) ^ (~working4 & working6)
                let temporary1 = working7 &+ sum1 &+ choose &+ constants[index] &+ words[index]
                let sum0 = working0.rotateRight(2) ^ working0.rotateRight(13) ^ working0.rotateRight(22)
                let majority = (working0 & working1) ^ (working0 & working2) ^ (working1 & working2)
                let temporary2 = sum0 &+ majority
                working7 = working6
                working6 = working5
                working5 = working4
                working4 = working3 &+ temporary1
                working3 = working2
                working2 = working1
                working1 = working0
                working0 = temporary1 &+ temporary2
            }
            state[0] &+= working0
            state[1] &+= working1
            state[2] &+= working2
            state[3] &+= working3
            state[4] &+= working4
            state[5] &+= working5
            state[6] &+= working6
            state[7] &+= working7
        }
        return state.flatMap { word in withUnsafeBytes(of: word.bigEndian, Array.init) }
    }
}

private extension UInt32 {
    func rotateRight(_ amount: UInt32) -> UInt32 {
        self >> amount | self << (32 - amount)
    }
}
