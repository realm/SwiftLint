import Foundation
import SourceKittenFramework

private typealias BaselineViolations = [BaselineViolation]
private typealias ViolationsPerFile = [String: BaselineViolations]
private typealias ViolationsPerRule = [String: BaselineViolations]

private struct BaselineViolation: Codable, Hashable, Comparable {
    let violation: StyleViolation
    let text: String
    var key: String { text + violation.reason }

    private enum CodingKeys: String, CodingKey {
        case violation
        case text
    }

    private struct CodableViolation: Codable {
        let ruleIdentifier: String
        let ruleDescription: String
        let ruleName: String
        let severity: ViolationSeverity
        let location: CodableLocation
        let reason: String

        init(_ violation: StyleViolation) {
            ruleIdentifier = violation.ruleIdentifier
            ruleDescription = violation.ruleDescription
            ruleName = violation.ruleName
            severity = violation.severity
            location = CodableLocation(violation.location)
            reason = violation.reason
        }

        var violation: StyleViolation {
            let location = location.location
            let description = RuleDescription(
                identifier: ruleIdentifier,
                name: ruleName,
                description: ruleDescription,
                kind: .style
            )
            return StyleViolation(
                ruleDescription: description,
                severity: severity,
                location: location,
                reason: reason
            )
        }
    }

    private struct CodableLocation: Codable {
        let file: String?
        let line: Int?
        let character: Int?

        init(_ location: Location) {
            file = location.file.map(\.relativeDisplayPath)
            line = location.line
            character = location.character
        }

        var location: Location {
            Location(file: file?.url(), line: line, character: character)
        }
    }

    init(violation: StyleViolation, text: String) {
        self.violation = violation
        self.text = text
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let violation = try container.decode(CodableViolation.self, forKey: .violation)
        text = try container.decode(String.self, forKey: .text)
        self.violation = violation.violation
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(CodableViolation(violation), forKey: .violation)
        try container.encode(text, forKey: .text)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.violation == rhs.violation && lhs.text == rhs.text
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.violation.location == rhs.violation.location
            ? lhs.violation.ruleIdentifier < rhs.violation.ruleIdentifier
            : lhs.violation.location < rhs.violation.location
    }
}

/// A set of violations that can be used to filter newly detected violations.
public struct Baseline: Equatable {
    private let baseline: ViolationsPerFile
    private var sortedBaselineViolations: BaselineViolations {
        baseline.flatMap(\.value).sorted()
    }

    /// The stored violations.
    public var violations: [StyleViolation] {
        sortedBaselineViolations.map(\.violation)
    }

    /// Creates a `Baseline` from a saved file.
    ///
    /// - parameter fromPath: The path to read from.
    public init(fromPath path: URL) throws {
        let data = try Data(contentsOf: path)
        baseline = try JSONDecoder().decode(BaselineViolations.self, from: data).groupedByFile()
    }

    /// Creates a `Baseline` from a list of violations.
    ///
    /// - parameter violations: The violations for the baseline.
    public init(violations: [StyleViolation]) {
        baseline = BaselineViolations(violations).groupedByFile()
    }

    /// Writes a `Baseline` to disk in JSON format.
    ///
    /// - parameter toPath: The path to write to.
    public func write(toPath path: URL) throws {
        try JSONEncoder().encode(sortedBaselineViolations).write(to: path)
    }

    /// Filters out violations that are present in the `Baseline`.
    ///
    /// Assumes that all violations are from the same file.
    ///
    /// - parameter violations: The violations to filter.
    /// - Returns: The new violations.
    public func filter(_ violations: [StyleViolation]) -> [StyleViolation] {
        guard let firstViolation = violations.first,
              let baselineViolations = baseline[firstViolation.location.file?.relativeDisplayPath ?? ""],
              baselineViolations.isNotEmpty else {
            return violations
        }

        let relativePathViolations = BaselineViolations(violations)
        let violationsWithAbsolutePaths = filter(
            relativePathViolations: relativePathViolations,
            baselineViolations: baselineViolations
        )
        return violations.filter { violationsWithAbsolutePaths.contains($0) }
    }

    private func filter(
        relativePathViolations: BaselineViolations, baselineViolations: BaselineViolations
    ) -> Set<StyleViolation> {
        if relativePathViolations == baselineViolations {
            return []
        }

        let violationsByRuleIdentifier = relativePathViolations.groupedByRuleIdentifier(
            filteredBy: baselineViolations
        )
        let baselineViolationsByRuleIdentifier = baselineViolations.groupedByRuleIdentifier(
            filteredBy: relativePathViolations
        )

        var filteredViolations: Set<BaselineViolation> = []

        for (ruleIdentifier, ruleViolations) in violationsByRuleIdentifier {
            guard let baselineViolations = baselineViolationsByRuleIdentifier[ruleIdentifier],
                  baselineViolations.isNotEmpty else {
                  filteredViolations.formUnion(ruleViolations)
                continue
            }

            let groupedRuleViolations = Dictionary(grouping: ruleViolations, by: \.key)
            let groupedBaselineViolations = Dictionary(grouping: baselineViolations, by: \.key)

            for (key, ruleViolations) in groupedRuleViolations {
                guard let baselineViolations = groupedBaselineViolations[key] else {
                    filteredViolations.formUnion(ruleViolations)
                    continue
                }
                if ruleViolations.count > baselineViolations.count {
                    filteredViolations.formUnion(ruleViolations)
                }
            }
        }

        return Set(filteredViolations.map(\.violation))
    }

    /// Returns the violations that are present in another `Baseline`, but not in this one.
    ///
    /// The violations are filtered using the same algorithm as the `filter` method above.
    ///
    /// - parameter otherBaseline: The other `Baseline`.
    public func compare(_ otherBaseline: Self) -> [StyleViolation] {
        otherBaseline.baseline.flatMap { relativePath, otherBaselineViolations -> Set<StyleViolation> in
            if let baselineViolations = baseline[relativePath] {
                return filter(relativePathViolations: otherBaselineViolations, baselineViolations: baselineViolations)
            }
            return Set(otherBaselineViolations.map(\.violation))
        }.sorted {
            $0.location == $1.location ? $0.ruleIdentifier < $1.ruleIdentifier : $0.location < $1.location
        }
    }
}

private struct LineCache {
    private var lines: [URL: [String]] = [:]

    mutating func text(at location: Location) -> String {
        let line = (location.line ?? 0) - 1
        if line > 0, let file = location.file, let content = cached(file: file), line < content.count {
            return content[line]
        }
        return ""
    }

    private mutating func cached(file: URL) -> [String]? {
        if let fileLines = lines[file] {
            return fileLines
        }
        if let fileLines = SwiftLintFile(path: file)?.lines.map(\.content) {
            lines[file] = fileLines
            return fileLines
        }
        return nil
    }
}

private extension Sequence where Element == BaselineViolation {
    init(_ violations: [StyleViolation]) where Self == BaselineViolations {
        var lineCache = LineCache()
        self = violations.map { $0.baselineViolation(text: lineCache.text(at: $0.location)) }
    }

    func groupedByFile() -> ViolationsPerFile {
        Dictionary(grouping: self) { $0.violation.location.file?.relativeDisplayPath ?? "" }
    }

    func groupedByRuleIdentifier(filteredBy existingViolations: [BaselineViolation] = []) -> ViolationsPerRule {
        Dictionary(grouping: Set(self).subtracting(existingViolations), by: \.violation.ruleIdentifier)
    }
}

private extension StyleViolation {
    func baselineViolation(text: String = "") -> BaselineViolation {
        BaselineViolation(violation: self, text: text)
    }
}
