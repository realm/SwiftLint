import Foundation
import SourceKittenFramework

public struct SonarQubeReporter: Reporter {
    public static let identifier = "sonarqube"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations in SonarQube import format."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return toJSON(["issues": violations
            .filter { $0.location.relativeFile != nil && $0.location.line != nil }
            .map(dictionary(for:))
            ])
    }

    // refer to https://docs.sonarqube.org/display/SONAR/Generic+Issue+Data
    static func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            "engineId": "SwiftLint",
            "ruleId": violation.ruleDescription.identifier,
            "primaryLocation": [
                "message": violation.reason,
                "filePath": violation.location.relativeFile ?? "",
                "textRange": [
                    "startLine": violation.location.line ?? 0
                ]
            ],
            "type": "CODE_SMELL",
            "severity": violation.severity == .error ? "MAJOR": "MINOR"
        ]
    }
}
