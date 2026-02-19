import Foundation
import SourceKittenFramework

/// To some tools (i.e. Datadog), code quality findings are reported in the SARIF format:
///     - Full Spec: https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html
///     - Samples: https://github.com/microsoft/sarif-tutorials/blob/main/samples/
///     - JSON Validator: https://sarifweb.azurewebsites.net/Validation
struct SARIFReporter: Reporter {
    // MARK: - Reporter Conformance
    static let identifier = "sarif"
    static let isRealtime = false
    static let description = "Reports violations in the Static Analysis Results Interchange Format (SARIF)"
    static let swiftlintVersion = "https://github.com/realm/SwiftLint/blob/\(Version.current.value)/README.md"

    static func generateReport(_ violations: [StyleViolation]) -> String {
        let SARIFJson = [
            "version": "2.1.0",
            "$schema": "https://docs.oasis-open.org/sarif/sarif/v2.1.0/cos02/schemas/sarif-schema-2.1.0.json",
            "runs": [
                [
                    "tool": [
                        "driver": [
                            "name": "SwiftLint",
                            "semanticVersion": Version.current.value,
                            "informationUri": swiftlintVersion,
                            "rules": builtInRules.map(dictionary(for:)),
                        ],
                    ],
                    "results": violations.map(dictionary(for:)),
                ],
            ],
        ] as [String: Any]

        return toJSON(SARIFJson, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
    }

    // MARK: - Private

    private static func dictionary(for ruleType: any Rule.Type) -> [String: Any] {
        let description = ruleType.description
        return [
            "id": description.identifier,
            "shortDescription": [
                "text": description.name
            ],
            "fullDescription": [
                "text": description.description
            ],
            "helpUri": "https://realm.github.io/SwiftLint/\(description.identifier).html",
        ]
    }

    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        [
            "level": violation.severity.rawValue,
            "ruleId": violation.ruleIdentifier,
            "message": [
                "text": violation.reason
            ],
            "locations": [
                dictionary(for: violation.location)
            ],
        ]
    }

    private static func dictionary(for location: Location) -> [String: Any] {
        // According to SARIF specification JSON1008, minimum value for line is 1
        if let line = location.line, line > 0 {
            return [
                "physicalLocation": [
                    "artifactLocation": [
                        "uri": location.relativeFile ?? ""
                    ],
                    "region": [
                        "startLine": line,
                        "startColumn": location.character ?? 1,
                    ],
                ],
            ]
        }

        return [
            "physicalLocation": [
                "artifactLocation": [
                    "uri": location.file ?? ""
                ],
            ],
        ]
    }
}
