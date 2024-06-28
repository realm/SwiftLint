import Foundation
import SourceKittenFramework

/// Reports violations as a JSON array.
struct JSONReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "json"
    static let isRealtime = false
    static let description = "Reports violations as a JSON array."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        return toJSON(violations.map(dictionary(for:)))
    }

    // MARK: - Private

    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            "file": violation.location.file ?? NSNull() as Any,
            "line": violation.location.line ?? NSNull() as Any,
            "character": violation.location.character ?? NSNull() as Any,
            "severity": violation.severity.rawValue.capitalized,
            "type": violation.ruleName,
            "rule_id": violation.ruleIdentifier,
            "reason": violation.reason,
        ]
    }
}
