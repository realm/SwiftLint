#if canImport(CryptoSwift)
import CryptoSwift
#endif
import Foundation
import SourceKittenFramework

/// Reports violations as a JSON array in Code Climate format.
struct CodeClimateReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "codeclimate"
    static let isRealtime = false
    static let description = "Reports violations as a JSON array in Code Climate format."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        toJSON(violations.map(dictionary(for:)))
            .replacingOccurrences(of: "\\/", with: "/")
    }

    // MARK: - Private

    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        [
            "check_name": violation.ruleName,
            "description": violation.reason,
            "engine_name": "SwiftLint",
            "fingerprint": generateFingerprint(violation),
            "location": [
                "path": violation.location.relativeFile ?? NSNull() as Any,
                "lines": [
                    "begin": violation.location.line ?? NSNull() as Any,
                    "end": violation.location.line ?? NSNull() as Any,
                ],
            ],
            "severity": violation.severity == .error ? "major" : "minor",
            "type": "issue",
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
            "\(violation.ruleIdentifier)",
        ].joined().sha256()
    }
}
