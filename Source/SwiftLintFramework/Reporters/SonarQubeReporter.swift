import Foundation
import SourceKittenFramework

/// Reports violations in SonarQube import format.
struct SonarQubeReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "sonarqube"
    static let isRealtime = false
    static let description = "Reports violations in SonarQube import format."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        // Resolved once: `URL.cwd` reaches a `getcwd` syscall on every access.
        let cwd = URL.cwd.path
        return toJSON(["issues": violations.map { dictionary(for: $0, cwd: cwd) }])
    }

    // MARK: - Private

    // refer to https://docs.sonarqube.org/display/SONAR/Generic+Issue+Data
    private static func dictionary(for violation: StyleViolation, cwd: String) -> [String: Any] {
        [
            "engineId": "SwiftLint",
            "ruleId": violation.ruleIdentifier,
            "primaryLocation": [
                "message": violation.reason,
                "filePath": violation.location.file?.relativeDisplayPath(against: cwd) ?? "",
                "textRange": [
                    "startLine": violation.location.line ?? 1
                ] as Any,
            ] as Any,
            "type": "CODE_SMELL",
            "severity": violation.severity == .error ? "MAJOR" : "MINOR",
        ]
    }
}
