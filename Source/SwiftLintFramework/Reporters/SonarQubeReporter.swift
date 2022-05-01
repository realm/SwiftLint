import SourceKittenFramework

/// Reports violations in SonarQube import format.
public struct SonarQubeReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "sonarqube"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations in SonarQube import format."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return toJSON(["issues": violations.map(dictionary(for:))])
    }

    // MARK: - Private

    // refer to https://docs.sonarqube.org/display/SONAR/Generic+Issue+Data
    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            "engineId": "SwiftLint",
            "ruleId": violation.ruleIdentifier,
            "primaryLocation": [
                "message": violation.reason,
                "filePath": violation.location.relativeFile ?? "",
                "textRange": [
                    "startLine": violation.location.line ?? 1
                ]
            ],
            "type": "CODE_SMELL",
            "severity": violation.severity == .error ? "MAJOR" : "MINOR"
        ]
    }
}
