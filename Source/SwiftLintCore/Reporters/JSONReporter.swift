import Foundation
import SourceKittenFramework

/// Reports violations as a JSON array.
public struct JSONReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "json"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as a JSON array."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
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
            "reason": violation.reason
        ]
    }
}
