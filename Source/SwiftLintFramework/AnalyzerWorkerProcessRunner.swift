import Dispatch
import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

#if canImport(Darwin)
private typealias AnalyzerSpawnFileActions = posix_spawn_file_actions_t?
private typealias AnalyzerSpawnAttributes = posix_spawnattr_t?
#elseif canImport(Glibc)
private typealias AnalyzerSpawnFileActions = posix_spawn_file_actions_t
private typealias AnalyzerSpawnAttributes = posix_spawnattr_t
#endif

// Process-group creation, signal forwarding, metrics, and quiescence are intentionally colocated.
// swiftlint:disable file_length

package enum AnalyzerWorkerEnvironment {
    package static let requestPath = "SWIFTLINT_ANALYZER_WORKER_REQUEST_V1"
}

package struct AnalyzerWorkerInvocation: Sendable {
    package let jobId: String
    package let requestURL: URL
    package let resultURL: URL
    package let standardOutputURL: URL
    package let standardErrorURL: URL
    package let arguments: [String]
    package let environment: [String: String]

    package init(
        jobId: String,
        requestURL: URL,
        resultURL: URL,
        standardOutputURL: URL,
        standardErrorURL: URL,
        arguments: [String],
        environment: [String: String]
    ) {
        self.jobId = jobId
        self.requestURL = requestURL
        self.resultURL = resultURL
        self.standardOutputURL = standardOutputURL
        self.standardErrorURL = standardErrorURL
        self.arguments = arguments
        self.environment = environment
    }
}

package struct AnalyzerWorkerProcessOutput: Sendable {
    package let jobId: String
    package let resultData: Data
    package let diagnostics: String
}

package struct AnalyzerWorkerProcessMetrics: Equatable, Sendable {
    package let peakConcurrentJobs: Int
    package let peakAggregateResidentMemoryBytes: UInt64
}

package final class AnalyzerWorkerProcessRunner: @unchecked Sendable {
    private let executableURL: URL
    private let currentDirectoryURL: URL
    private let environment: [String: String]
    private let registry = AnalyzerProcessRegistry()

    package init(executableURL: URL, currentDirectoryURL: URL, environment: [String: String]) {
        self.executableURL = executableURL
        self.currentDirectoryURL = currentDirectoryURL
        self.environment = environment
    }

    package func prepare(
        requests: [AnalyzerWorkerRequest],
        graph: [AnalyzerJob],
        in directory: URL
    ) throws -> [AnalyzerWorkerInvocation] {
        guard requests.count == graph.count else {
            throw AnalyzerWorkerContractError.jobCount(expected: graph.count, actual: requests.count)
        }
        return try zip(requests, graph).enumerated().map { index, pair in
            let (request, job) = pair
            try request.validate(for: job)
            let requestURL = directory.appending(path: "request-\(index).json", directoryHint: .notDirectory)
            let standardOutputURL = directory.appending(path: "stdout-\(index).txt", directoryHint: .notDirectory)
            let standardErrorURL = directory.appending(path: "stderr-\(index).txt", directoryHint: .notDirectory)
            try AnalyzerJSON.encoder.encode(request).write(to: requestURL, options: .atomic)
            guard FileManager.default.createFile(atPath: standardOutputURL.path, contents: nil),
                  FileManager.default.createFile(atPath: standardErrorURL.path, contents: nil) else {
                throw AnalyzerProcessRunnerError.cannotCreateDiagnostics(job.jobId)
            }
            var childEnvironment = environment
            childEnvironment[AnalyzerWorkerEnvironment.requestPath] = requestURL.path
            childEnvironment.removeValue(forKey: "BUILD_WORKSPACE_DIRECTORY")
            return AnalyzerWorkerInvocation(
                jobId: job.jobId,
                requestURL: requestURL,
                resultURL: request.resultURL,
                standardOutputURL: standardOutputURL,
                standardErrorURL: standardErrorURL,
                arguments: ["analyze"],
                environment: childEnvironment
            )
        }
    }

    package func run(_ invocation: AnalyzerWorkerInvocation) async throws -> AnalyzerWorkerProcessOutput {
        try await withTaskCancellationHandler {
            let processIdentifier = try registry.spawn(
                executableURL: executableURL,
                arguments: invocation.arguments,
                environment: invocation.environment,
                currentDirectoryURL: currentDirectoryURL,
                standardOutputURL: invocation.standardOutputURL,
                standardErrorURL: invocation.standardErrorURL
            )
            let sampler = Task.detached(priority: .utility) { [registry] in
                while !Task.isCancelled {
                    registry.sampleResidentMemory()
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
            let status = await Task.detached(priority: .userInitiated) {
                AnalyzerProcessRegistry.wait(for: processIdentifier)
            }.value
            sampler.cancel()
            registry.sampleResidentMemory()
            let wasCancelled = registry.finished(processIdentifier)
            let groupWasQuiescent = registry.ensureGroupQuiescence(processIdentifier)
            if wasCancelled {
                throw CancellationError()
            }
            guard groupWasQuiescent else {
                throw AnalyzerWorkerContractError.workerFailed(
                    job: invocation.jobId,
                    reason: "descendant cleanup failed",
                    diagnostics: "The worker process group remained live after its leader exited."
                )
            }
            return try Self.processOutput(for: invocation, status: status)
        } onCancel: {
            registry.terminateAll(forwarding: SIGTERM)
        }
    }

    package func cancelAll() {
        registry.terminateAll(forwarding: SIGTERM)
    }

    package func forward(signal signalNumber: Int32) {
        registry.terminateAll(forwarding: signalNumber)
    }

    package var metrics: AnalyzerWorkerProcessMetrics {
        registry.metrics
    }

    private static func processOutput(
        for invocation: AnalyzerWorkerInvocation,
        status: Int32
    ) throws -> AnalyzerWorkerProcessOutput {
        let diagnostics = try String(contentsOf: invocation.standardErrorURL, encoding: .utf8)
        let output = try String(contentsOf: invocation.standardOutputURL, encoding: .utf8)
        guard output.isEmpty else {
            throw AnalyzerWorkerContractError.workerFailed(
                job: invocation.jobId,
                reason: "unexpected standard output",
                diagnostics: output
            )
        }
        guard let exitCode = Self.exitCode(status), exitCode == 0 else {
            let reason = Self.terminationDescription(status)
            throw AnalyzerWorkerContractError.workerFailed(
                job: invocation.jobId,
                reason: reason,
                diagnostics: diagnostics
            )
        }
        guard diagnostics.isEmpty else {
            throw AnalyzerWorkerContractError.workerFailed(
                job: invocation.jobId,
                reason: "unexpected standard error",
                diagnostics: diagnostics
            )
        }
        guard FileManager.default.fileExists(atPath: invocation.resultURL.path) else {
            throw AnalyzerWorkerContractError.workerFailed(
                job: invocation.jobId,
                reason: "missing result",
                diagnostics: "The worker exited successfully without writing its versioned result."
            )
        }
        return AnalyzerWorkerProcessOutput(
            jobId: invocation.jobId,
            resultData: try Data(contentsOf: invocation.resultURL),
            diagnostics: diagnostics
        )
    }

    private static func exitCode(_ status: Int32) -> Int32? {
        status & 0x7f == 0 ? (status >> 8) & 0xff : nil
    }

    private static func terminationDescription(_ status: Int32) -> String {
        if let exitCode = exitCode(status) {
            return "exit \(exitCode)"
        }
        return "signal \(status & 0x7f)"
    }
}

package final class AnalyzerSignalForwarder: @unchecked Sendable {
    private struct Registration {
        let signalNumber: Int32
        let previousHandler: sig_t?
        let source: any DispatchSourceSignal
    }

    private let registrations: [Registration]

    package init(runner: AnalyzerWorkerProcessRunner) {
        registrations = [SIGINT, SIGTERM].map { signalNumber in
            let previousHandler = signal(signalNumber, SIG_IGN)
            let source = DispatchSource.makeSignalSource(
                signal: signalNumber,
                queue: DispatchQueue.global(qos: .userInitiated)
            )
            source.setEventHandler {
                runner.forward(signal: signalNumber)
                _ = signal(signalNumber, SIG_DFL)
                _ = kill(getpid(), signalNumber)
            }
            source.activate()
            return Registration(
                signalNumber: signalNumber,
                previousHandler: previousHandler,
                source: source
            )
        }
    }

    deinit {
        for registration in registrations {
            registration.source.cancel()
            if let previousHandler = registration.previousHandler {
                _ = signal(registration.signalNumber, previousHandler)
            }
        }
    }
}

package enum AnalyzerProcessRunnerError: LocalizedError {
    case cannotCreateDiagnostics(String)
    case invalidExecutable(String)
    case spawnFailed(String, Int32)
    case stringAllocation

    package var errorDescription: String? {
        switch self {
        case .cannotCreateDiagnostics(let job):
            "Could not create analyzer worker diagnostics for '\(job)'."
        case .invalidExecutable(let path):
            "Analyzer worker executable is not executable: '\(path)'."
        case let .spawnFailed(path, code):
            "Could not spawn analyzer worker '\(path)': \(String(cString: strerror(code)))."
        case .stringAllocation:
            "Could not allocate analyzer worker process arguments."
        }
    }
}

// All mutable state is protected by `lock`; process groups are registered atomically with `posix_spawn`.
private final class AnalyzerProcessRegistry: @unchecked Sendable {
    private let lock = NSLock()
    private var processGroups = Set<pid_t>()
    private var cancelledProcessGroups = Set<pid_t>()
    private var cancellationRequested = false
    private var maximumActiveJobs = 0
    private var maximumResidentMemoryBytes: UInt64 = 0

    var metrics: AnalyzerWorkerProcessMetrics {
        lock.withLock {
            AnalyzerWorkerProcessMetrics(
                peakConcurrentJobs: maximumActiveJobs,
                peakAggregateResidentMemoryBytes: maximumResidentMemoryBytes
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    func spawn(
        executableURL: URL,
        arguments: [String],
        environment: [String: String],
        currentDirectoryURL: URL,
        standardOutputURL: URL,
        standardErrorURL: URL
    ) throws -> pid_t {
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw AnalyzerProcessRunnerError.invalidExecutable(executableURL.path)
        }

        return try lock.withLock {
            guard !cancellationRequested else { throw CancellationError() }

            var fileActions = Self.makeSpawnFileActions()
            var attributes = Self.makeSpawnAttributes()
            guard posix_spawn_file_actions_init(&fileActions) == 0,
                  posix_spawnattr_init(&attributes) == 0 else {
                throw AnalyzerProcessRunnerError.spawnFailed(executableURL.path, errno)
            }
            defer {
                posix_spawn_file_actions_destroy(&fileActions)
                posix_spawnattr_destroy(&attributes)
            }

            try Self.configureFileActions(
                &fileActions,
                currentDirectoryURL: currentDirectoryURL,
                standardOutputURL: standardOutputURL,
                standardErrorURL: standardErrorURL
            )
            let flags = Int16(POSIX_SPAWN_SETPGROUP)
            let flagsResult = posix_spawnattr_setflags(&attributes, flags)
            let groupResult = posix_spawnattr_setpgroup(&attributes, 0)
            guard flagsResult == 0, groupResult == 0 else {
                throw AnalyzerProcessRunnerError.spawnFailed(
                    executableURL.path,
                    flagsResult == 0 ? groupResult : flagsResult
                )
            }

            var processIdentifier: pid_t = 0
            let environmentStrings = environment.keys.sorted().compactMap { key in
                environment[key].map { "\(key)=\($0)" }
            }
            let spawnResult = try Self.withCStringArray([executableURL.path] + arguments) { argumentPointer in
                try Self.withCStringArray(environmentStrings) { environmentPointer in
                    posix_spawn(
                        &processIdentifier,
                        executableURL.path,
                        &fileActions,
                        &attributes,
                        argumentPointer,
                        environmentPointer
                    )
                }
            }
            guard spawnResult == 0 else {
                throw AnalyzerProcessRunnerError.spawnFailed(executableURL.path, spawnResult)
            }
            processGroups.insert(processIdentifier)
            maximumActiveJobs = max(maximumActiveJobs, processGroups.count)
            return processIdentifier
        }
    }

    func finished(_ processGroup: pid_t) -> Bool {
        lock.withLock {
            processGroups.remove(processGroup)
            return cancelledProcessGroups.remove(processGroup) != nil
        }
    }

    func terminateAll(forwarding signalNumber: Int32) {
        let groups = lock.withLock { () -> [pid_t] in
            cancellationRequested = true
            cancelledProcessGroups.formUnion(processGroups)
            return Array(processGroups)
        }
        Self.signal(groups: groups, signalNumber: signalNumber)
        let deadline = ContinuousClock.now.advanced(by: .seconds(2))
        while ContinuousClock.now < deadline, groups.contains(where: Self.groupExists) {
            usleep(20_000)
        }
        let survivingGroups = groups.filter(Self.groupExists)
        Self.signal(groups: survivingGroups, signalNumber: SIGKILL)
    }

    func ensureGroupQuiescence(_ processGroup: pid_t) -> Bool {
        guard Self.groupExists(processGroup) else { return true }
        Self.signal(groups: [processGroup], signalNumber: SIGTERM)
        let gracefulDeadline = ContinuousClock.now.advanced(by: .seconds(2))
        while ContinuousClock.now < gracefulDeadline, Self.groupExists(processGroup) {
            usleep(20_000)
        }
        if Self.groupExists(processGroup) {
            Self.signal(groups: [processGroup], signalNumber: SIGKILL)
        }
        let killDeadline = ContinuousClock.now.advanced(by: .seconds(2))
        while ContinuousClock.now < killDeadline, Self.groupExists(processGroup) {
            usleep(20_000)
        }
        return !Self.groupExists(processGroup)
    }

    func sampleResidentMemory() {
        let groups = lock.withLock { Array(processGroups) }
        let residentMemory = groups.reduce(UInt64(0)) { partial, processIdentifier in
            partial + Self.residentMemoryBytes(processIdentifier)
        }
        lock.withLock {
            maximumResidentMemoryBytes = max(maximumResidentMemoryBytes, residentMemory)
        }
    }

    static func wait(for processIdentifier: pid_t) -> Int32 {
        var status: Int32 = 0
        while waitpid(processIdentifier, &status, 0) == -1, errno == EINTR {
            // Retry after an interrupted system call.
        }
        return status
    }

    private static func makeSpawnFileActions() -> AnalyzerSpawnFileActions {
        #if canImport(Darwin)
        nil
        #else
        AnalyzerSpawnFileActions()
        #endif
    }

    private static func makeSpawnAttributes() -> AnalyzerSpawnAttributes {
        #if canImport(Darwin)
        nil
        #else
        AnalyzerSpawnAttributes()
        #endif
    }

    private static func configureFileActions(
        _ actions: inout AnalyzerSpawnFileActions,
        currentDirectoryURL: URL,
        standardOutputURL: URL,
        standardErrorURL: URL
    ) throws {
        let changeDirectoryResult: Int32
        #if canImport(Darwin)
        if #available(macOS 26.0, *) {
            changeDirectoryResult = posix_spawn_file_actions_addchdir(&actions, currentDirectoryURL.path)
        } else {
            changeDirectoryResult = posix_spawn_file_actions_addchdir_np(&actions, currentDirectoryURL.path)
        }
        #else
        changeDirectoryResult = posix_spawn_file_actions_addchdir_np(&actions, currentDirectoryURL.path)
        #endif
        let mode = mode_t(S_IRUSR | S_IWUSR)
        let stdoutResult = posix_spawn_file_actions_addopen(
            &actions,
            STDOUT_FILENO,
            standardOutputURL.path,
            O_WRONLY | O_CREAT | O_TRUNC,
            mode
        )
        let stderrResult = posix_spawn_file_actions_addopen(
            &actions,
            STDERR_FILENO,
            standardErrorURL.path,
            O_WRONLY | O_CREAT | O_TRUNC,
            mode
        )
        guard changeDirectoryResult == 0 else {
            throw AnalyzerProcessRunnerError.spawnFailed(currentDirectoryURL.path, changeDirectoryResult)
        }
        guard stdoutResult == 0 else {
            throw AnalyzerProcessRunnerError.spawnFailed(standardOutputURL.path, stdoutResult)
        }
        guard stderrResult == 0 else {
            throw AnalyzerProcessRunnerError.spawnFailed(standardErrorURL.path, stderrResult)
        }
    }

    private static func withCStringArray<Result>(
        _ values: [String],
        body: (UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) throws -> Result
    ) throws -> Result {
        var pointers = [UnsafeMutablePointer<CChar>]()
        defer { pointers.forEach { free(UnsafeMutableRawPointer($0)) } }
        for value in values {
            guard let pointer = strdup(value) else {
                throw AnalyzerProcessRunnerError.stringAllocation
            }
            pointers.append(pointer)
        }
        var nullablePointers = pointers.map(Optional.some)
        nullablePointers.append(nil)
        return try nullablePointers.withUnsafeMutableBufferPointer { buffer in
            guard let baseAddress = buffer.baseAddress else {
                throw AnalyzerProcessRunnerError.stringAllocation
            }
            return try body(baseAddress)
        }
    }

    private static func signal(groups: [pid_t], signalNumber: Int32) {
        for group in groups where group > 0 {
            if kill(-group, signalNumber) == -1, errno != ESRCH {
                // The wait path reports the authoritative worker outcome.
            }
        }
    }

    private static func groupExists(_ group: pid_t) -> Bool {
        guard group > 0 else { return false }
        if kill(-group, 0) == -1 {
            return errno == EPERM
        }
        #if canImport(Glibc)
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: "/proc") else {
            return true
        }
        var foundGroupMember = false
        for entry in entries where pid_t(entry) != nil {
            guard let stat = try? String(contentsOfFile: "/proc/\(entry)/stat", encoding: .utf8),
                  let commandEnd = stat.range(of: ")", options: .backwards)?.upperBound else {
                continue
            }
            let fields = stat[commandEnd...].split(whereSeparator: \.isWhitespace)
            guard fields.count > 2, pid_t(fields[2]) == group else { continue }
            foundGroupMember = true
            if fields[0] != "Z", fields[0] != "X" {
                return true
            }
        }
        return !foundGroupMember && kill(-group, 0) == 0
        #else
        return true
        #endif
    }

    private static func residentMemoryBytes(_ processIdentifier: pid_t) -> UInt64 {
        #if canImport(Darwin)
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(processIdentifier, PROC_PIDTASKINFO, 0, &info, size) == size else { return 0 }
        return info.pti_resident_size
        #elseif canImport(Glibc)
        guard let contents = try? String(contentsOfFile: "/proc/\(processIdentifier)/status", encoding: .utf8),
              let line = contents.split(separator: "\n").first(where: { $0.hasPrefix("VmRSS:") }),
              let kilobytes = UInt64(line.split(whereSeparator: \.isWhitespace).dropFirst().first ?? "") else {
            return 0
        }
        return kilobytes * 1024
        #else
        return 0
        #endif
    }
}

package enum AnalyzerJSON {
    package static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
