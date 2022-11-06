#if canImport(CryptoSwift)
import CryptoSwift
#endif
import Foundation
import SourceKittenFramework

/// Reports violations as a JSON array in Code Climate format.
public struct CodeClimateReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "codeclimate"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as a JSON array in Code Climate format."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return toJSON(violations.map(dictionary(for:)))
            .replacingOccurrences(of: "\\/", with: "/")
    }

    // MARK: - Private

    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            "check_name": violation.ruleName,
            "description": violation.reason,
            "engine_name": "SwiftLint",
            "fingerprint": generateFingerprint(violation),
            "location": [
                "path": violation.location.relativeFile ?? NSNull() as Any,
                "lines": [
                    "begin": violation.location.line ?? NSNull() as Any,
                    "end": violation.location.line ?? NSNull() as Any
                ]
            ],
            "severity": violation.severity == .error ? "MAJOR" : "MINOR",
            "type": "issue"
        ]
    }

    internal static func generateFingerprint(_ violation: StyleViolation) -> String {
        let fingerprintLocation = Location(
            file: violation.location.relativeFile,
            line: violation.location.line,
            character: violation.location.character
        )

        return [
            "\(fingerprintLocation)",
            "\(violation.ruleIdentifier)"
        ].joined().sha256()
    }
}
