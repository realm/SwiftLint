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
        // Resolved once: every violation renders two relative paths, and each would otherwise
        // reach `FileManager.currentDirectoryPath` and a `getcwd` syscall.
        let cwd = URL.cwd.path
        return toJSON(violations.map { dictionary(for: $0, cwd: cwd) })
            .replacingOccurrences(of: "\\/", with: "/")
    }

    // MARK: - Private

    private static func dictionary(for violation: StyleViolation, cwd: String) -> [String: Any] {
        [
            "check_name": violation.ruleName,
            "description": violation.reason,
            "engine_name": "SwiftLint",
            "fingerprint": generateFingerprint(violation, cwd: cwd),
            "location": [
                "path": violation.location.file?.relativeDisplayPath(against: cwd) ?? NSNull() as Any,
                "lines": [
                    "begin": violation.location.line ?? NSNull() as Any,
                    "end": violation.location.line ?? NSNull() as Any,
                ],
            ],
            "severity": violation.severity == .error ? "major" : "minor",
            "type": "issue",
        ]
    }

    internal static func generateFingerprint(_ violation: StyleViolation, cwd: String = URL.cwd.path) -> String {
        [
            "\(violation.location.file?.relativeDisplayPath(against: cwd) ?? "")",
            "\(violation.location.line ?? 0)",
            "\(violation.location.character ?? 0)",
            "\(violation.ruleIdentifier)",
        ].joined().sha256()
    }
}
