import Foundation
import SourceKittenFramework

/// SARIFReporter
/// For some tools (i.e. DataDog), code quality findings are reported in a SARIF () format.
/// Some documentation re: SARIF:
///     - Full Spec: https://docs.oasis-open.org/sarif/sarif/v2.1.0/errata01/os/sarif-v2.1.0-errata01-os-complete.html
///     - Samples: https://github.com/microsoft/sarif-tutorials/blob/main/samples/
///     - JSON Validator: https://sarifweb.azurewebsites.net/Validation
struct SARIFReporter: Reporter {
    // MARK: - Reporter Conformance
    static let identifier = "json"
    static let isRealtime = false
    static let description: String = "Reports violations as a SARIF compatible JSON array."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        let orderedViolations = Dictionary(grouping: violations, by: { $0.ruleIdentifier })
        let SARIFJson = [
            "version": "2.1.0",
            "$schema": "https://docs.oasis-open.org/sarif/sarif/v2.1.0/cos02/schemas/sarif-schema-2.1.0.json",
            "runs": [
                [
                    "tool": [
                        "driver": [
                            "name": "SwiftLint",
                            "semanticVersion": Version.current.value,
                            "informationUri": "https://github.com/realm/SwiftLint/blob/main/README.md"
                        ]
                    ],
                    "results": orderedViolations.map(dictionary(for:))
                ]
            ]
        ] as [String: Any]

        return toJSON(SARIFJson)
    }

    // MARK: - Private

    private static func dictionary(for violation: Dictionary<String, [StyleViolation]>.Element) -> [String: Any] {
        return [
            "level": violation.value[0].severity.rawValue,
            "ruleId": violation.key,
            "message": [
                "text": violation.value[0].reason
            ],
            "locations": violation.value.map(dictionary(for:))
        ]
    }

    private static func dictionary(for violation: StyleViolation) -> [String: Any] {
        // According to SARIF specification JSON1008, minimum value for line is 1
        guard let line = violation.location.line, line > 0 else {
            return [
                "physicalLocation": [
                    "artifactLocation": [
                        "uri": violation.location.file ?? ""
                    ]
                ]
            ]
        }

        return [
            "physicalLocation": [
                "artifactLocation": [
                    "uri": violation.location.file ?? ""
                ],
                "region": [
                    "startLine": line
                ]
            ]
        ]
    }
}
