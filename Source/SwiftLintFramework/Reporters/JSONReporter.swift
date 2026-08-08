import Foundation
import SourceKittenFramework

/// Reports violations as a JSON array.
struct JSONReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "json"
    static let isRealtime = false
    static let description = "Reports violations as a JSON array."

    /// Below this many violations a run is short enough that splitting it costs more than it saves.
    private static let minimumViolationsPerChunk = 2000

    static func generateReport(_ violations: [StyleViolation]) -> String {
        // Rendering the report is the one part of a run that does not parallelize, and over a large
        // code base it is the whole of the single-threaded tail. The array is a concatenation of
        // independent objects, so it is split into chunks that encode concurrently and are then
        // joined, leaving escaping and formatting to `JSONEncoder`.
        let chunkCount = min(
            ProcessInfo.processInfo.activeProcessorCount,
            max(1, violations.count / minimumViolationsPerChunk)
        )
        guard chunkCount > 1 else {
            return encode(violations) ?? "[]"
        }
        let chunkSize = (violations.count + chunkCount - 1) / chunkCount
        let chunks = stride(from: 0, to: violations.count, by: chunkSize).map { start in
            Array(violations[start..<min(start + chunkSize, violations.count)])
        }
        let fragments = chunks.parallelMap { chunk in encode(chunk).map(Self.elements) ?? "" }
        return "[\n" + fragments.joined(separator: ",\n") + "\n]"
    }

    // MARK: - Private

    private static func encode(_ violations: [StyleViolation]) -> String? {
        let encoder = JSONEncoder()
        // The options `JSONSerialization` was given. `.sortedKeys` is not redundant despite the
        // coding keys being declared in the order it sorts them into: without it `JSONEncoder`
        // emits keys in an unrelated order.
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(violations.map(Violation.init)) else {
            return nil
        }
        return String(bytes: data, encoding: .utf8)
    }

    /// A rendered array's elements, without the brackets and newlines that wrap them, so that
    /// separately encoded chunks can be joined back into one array.
    private static func elements(of report: String) -> String {
        guard report.hasPrefix("[\n"), report.hasSuffix("\n]") else {
            return report
        }
        return String(report.dropFirst(2).dropLast(2))
    }
}

/// A violation in the shape the report exposes.
private struct Violation: Encodable, Sendable {
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
