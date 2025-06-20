import Foundation
import SourceKittenFramework

public extension Request {
    static let disableSourceKit = ProcessInfo.processInfo.environment["SWIFTLINT_DISABLE_SOURCEKIT"] != nil

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
                    if ruleType is any SourceKitFreeRule.Type {
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
            throw Self.Error.connectionInterrupted("SourceKit is disabled by `SWIFTLINT_DISABLE_SOURCEKIT`.")
        }
        return try send()
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
