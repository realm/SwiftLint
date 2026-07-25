import Foundation
import SourceKittenFramework

/// Reports violations as a JSON array.
struct JSONReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "json"
    static let isRealtime = false
    static let description = "Reports violations as a JSON array."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        // Encoded rather than serialized through `JSONSerialization`, which bridges a dictionary per
        // violation to `NSDictionary` and re-sorts its keys each time. That work is single-threaded
        // and dominated the tail of a run over a large code base. It is given the same formatting
        // options, including `.sortedKeys`: `JSONEncoder` does not otherwise emit keys in the order
        // they are declared, so the option is what keeps the report's key order stable.
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(violations.map(Violation.init)),
              let report = String(bytes: data, encoding: .utf8) else {
            return "[]"
        }
        return report
    }
}

/// A violation in the shape the report exposes.
private struct Violation: Encodable {
    let character: Int?
    let file: String?
    let line: Int?
    let reason: String
    let ruleID: String
    let severity: String
    let type: String

    enum CodingKeys: String, CodingKey {
        case character
        case file
        case line
        case reason
        case ruleID = "rule_id"
        case severity
        case type
    }

    init(_ violation: StyleViolation) {
        character = violation.location.character
        file = violation.location.file?.path
        line = violation.location.line
        reason = violation.reason
        ruleID = violation.ruleIdentifier
        severity = violation.severity.rawValue.capitalized
        type = violation.ruleName
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Encoded unconditionally rather than with `encodeIfPresent`, so that a violation without a
        // location keeps its `null` entries as it had when these were `NSNull`.
        try container.encode(character, forKey: .character)
        try container.encode(file, forKey: .file)
        try container.encode(line, forKey: .line)
        try container.encode(reason, forKey: .reason)
        try container.encode(ruleID, forKey: .ruleID)
        try container.encode(severity, forKey: .severity)
        try container.encode(type, forKey: .type)
    }
}
