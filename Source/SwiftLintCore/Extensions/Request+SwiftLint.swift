import Foundation
import SourceKittenFramework

/// Tracks whether sourcekitd has wedged in the current process.
///
/// Under Swift Testing the suite runs as many concurrent tasks on a small cooperative executor.
/// Each linted file issues a synchronous, blocking sourcekitd request; if the daemon wedges — as it
/// does on the macOS CI runners — every concurrent caller blocks on it and the whole run hangs. To
/// bound that, ``Request/sendIfNotDisabled()`` runs each request with a timeout, and the first time
/// one times out this status latches so subsequent requests skip sourcekitd instead of each paying
/// the timeout. A healthy daemon answers immediately, so the latch never trips and behaviour is
/// unchanged. See PR #6048.
public enum SourceKitStatus {
    nonisolated(unsafe) private static var timedOut = false
    private static let lock = NSLock()

    /// Test-only override scoped to the current task tree, letting tests force the unavailable state
    /// deterministically and in isolation from other tests running in parallel.
    @TaskLocal package static var forceUnavailableForTesting = false

    /// Whether SourceKit requests should be skipped rather than issued.
    public static var isUnavailable: Bool {
        if forceUnavailableForTesting {
            return true
        }
        lock.lock()
        defer { lock.unlock() }
        return timedOut
    }

    /// Records that a request timed out, latching sourcekitd as unavailable for the rest of the run.
    static func recordTimeout() {
        lock.lock()
        defer { lock.unlock() }
        timedOut = true
    }
}

/// Thrown by ``Request/sendIfNotDisabled()`` when sourcekitd has already timed out, so that callers
/// skip the request instead of issuing another one that would block.
public struct SourceKitUnavailableError: Error, Equatable {}

/// Thrown when sourcekitd does not answer a request within the timeout.
public struct SourceKitRequestTimedOutError: Error, Equatable {
    public let timeout: TimeInterval
}

private struct UncheckedSendableValue<Value>: @unchecked Sendable {
    let value: Value
}

private final class SourceKitResponseBox: @unchecked Sendable {
    private let lock = NSLock()
    private var result: Result<[String: any SourceKitRepresentable], any Error>?

    func store(_ result: Result<[String: any SourceKitRepresentable], any Error>) {
        lock.lock()
        defer { lock.unlock() }
        self.result = result
    }

    func load() -> Result<[String: any SourceKitRepresentable], any Error>? {
        lock.lock()
        defer { lock.unlock() }
        return result
    }
}

public extension Request {
    nonisolated(unsafe) static var disableSourceKitOverride = false

    /// How long to wait for a single sourcekitd request before giving up and treating the daemon as
    /// wedged.
    static let sourceKitRequestTimeout: TimeInterval = 30

    static var disableSourceKit: Bool {
        #if SWIFTLINT_DISABLE_SOURCEKIT
        // Compile-time
        true
        #else
        // Runtime
        ProcessInfo.processInfo.environment["SWIFTLINT_DISABLE_SOURCEKIT"] != nil || disableSourceKitOverride
        #endif
    }

    func sendIfNotDisabled() throws -> [String: any SourceKitRepresentable] {
        // Skip safety checks if explicitly allowed (e.g., for testing or specific operations)
        if !CurrentRule.allowSourceKitRequestWithoutRule {
            // Check if we have a rule context
            if let ruleID = CurrentRule.identifier {
                // Skip registry check for mock test rules
                if ruleID != "mock_test_rule_for_swiftlint_tests" {
                    // Ensure the rule exists in the registry
                    guard let ruleType = RuleRegistry.shared.rule(forID: ruleID) else {
                        queuedFatalError("""
                            Rule '\(ruleID)' not found in RuleRegistry. This indicates a configuration or wiring issue.
                            """)
                    }

                    // Check if the current rule is a SourceKitFreeRule
                    // Skip check for ConditionallySourceKitFree rules since we can't determine
                    // at the type level if they're effectively SourceKit-free
                    if ruleType is any SourceKitFreeRule.Type, !(ruleType is any ConditionallySourceKitFree.Type) {
                        queuedFatalError("""
                            '\(ruleID)' is a SourceKitFreeRule and should not be making requests to SourceKit.
                            """)
                    }
                }
            } else {
                // No rule context and not explicitly allowed
                queuedFatalError("""
                    SourceKit request made outside of rule execution context without explicit permission.
                    Use CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) { ... } for allowed exceptions.
                    """)
            }
        }

        guard !Self.disableSourceKit else {
            queuedFatalError("SourceKit is disabled by configuration.")
        }
        // Once a sourcekitd request has wedged, skip the rest. Re-issuing a blocking request for
        // every file would otherwise starve the bounded test executor and hang the run. See PR #6048.
        guard !SourceKitStatus.isUnavailable else {
            throw SourceKitUnavailableError()
        }
        do {
            return try sendWithTimeout(Self.sourceKitRequestTimeout)
        } catch let error as SourceKitRequestTimedOutError {
            SourceKitStatus.recordTimeout()
            throw error
        }
    }

    /// Runs `send()` on a background queue and waits up to `timeout` seconds for a response, so a
    /// wedged sourcekitd request cannot block the calling (cooperative executor) thread forever.
    private func sendWithTimeout(_ timeout: TimeInterval) throws -> [String: any SourceKitRepresentable] {
        let request = UncheckedSendableValue(value: self)
        let box = SourceKitResponseBox()
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            box.store(Result { try request.value.send() })
            semaphore.signal()
        }

        guard semaphore.wait(timeout: .now() + timeout) == .success, let result = box.load() else {
            throw SourceKitRequestTimedOutError(timeout: timeout)
        }
        return try result.get()
    }

    static func cursorInfoWithoutSymbolGraph(file: String, offset: ByteCount, arguments: [String]) -> Request {
        .customRequest(request: [
            "key.request": UID("source.request.cursorinfo"),
            "key.name": file,
            "key.sourcefile": file,
            "key.offset": Int64(offset.value),
            "key.compilerargs": arguments,
            "key.cancel_on_subsequent_request": 0,
            "key.retrieve_symbol_graph": 0,
        ])
    }
}
