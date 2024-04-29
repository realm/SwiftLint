import Foundation

private typealias ViolationsPerFile = [String: [BaselineViolation]]
private typealias ViolationsPerRule = [String: [BaselineViolation]]

private struct BaselineViolation: Codable, Hashable {
    let violation: StyleViolation
    let text: String
    var key: String { text + violation.reason + violation.severity.rawValue }

    init(violation: StyleViolation, text: String) {
        let location = violation.location
        self.violation = violation.with(location: Location(
            // Within the baseline, we use relative paths, so that
            // comparisons are independent of the absolute path
            file: location.relativeFile,
            line: location.line,
            character: location.character)
        )
        self.text = text
    }
}

/// A set of violations that can be used to filter newly detected violations.
public struct Baseline: Equatable {
    private let baselineViolations: ViolationsPerFile
    private var sortedBaselineViolations: [BaselineViolation] {
        baselineViolations.sorted(by: { $0.key < $1.key }).flatMap(\.value)
    }

    /// The stored violations.
    public var violations: [StyleViolation] {
        sortedBaselineViolations.violationsWithAbsolutePaths
    }

    /// Creates a `Baseline` from a saved file.
    ///
    /// - parameter fromPath: The path to read from.
    public init(fromPath path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        baselineViolations = try JSONDecoder().decode([BaselineViolation].self, from: data).groupedByFile()
    }

    /// Creates a `Baseline` from a list of violations.
    ///
    /// - parameter violations: The violations for the baseline.
    public init(violations: [StyleViolation]) {
        baselineViolations = violations.baselineViolations.groupedByFile()
    }

    /// Writes a `Baseline` to disk in JSON format.
    ///
    /// - parameter toPath: The path to write to.
    public func write(toPath path: String) throws {
        let data = try JSONEncoder().encode(sortedBaselineViolations)
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// Filters out violations that are present in the `Baseline`.
    ///
    /// Assumes that all violations are from the same file.
    ///
    /// - parameter violations: The violations to filter.
    /// - Returns: The new violations.
    public func filter(_ violations: [StyleViolation]) -> [StyleViolation] {
        guard let firstViolation = violations.first,
              let baselineViolations = baselineViolations[firstViolation.location.relativeFile ?? ""],
              baselineViolations.isNotEmpty else {
            return violations
        }

        let relativePathViolations = violations.baselineViolations
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
            guard
                let baselineViolations = baselineViolationsByRuleIdentifier[ruleIdentifier],
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

        let violationsWithAbsolutePaths = Set(filteredViolations.violationsWithAbsolutePaths)
        return violations.filter { violationsWithAbsolutePaths.contains($0) }
    }

    /// Returns the violations that are present in another `Baseline`, but not in this one.
    ///
    /// The violations are filtered using the same algorithm as the `filter` method above.
    ///
    /// - parameter otherBaseline: The other `Baseline`.
    public func compare(_ otherBaseline: Baseline) -> [StyleViolation] {
        otherBaseline.baselineViolations.flatMap {
            filter($1.violationsWithAbsolutePaths)
        }
    }
}

private extension Sequence where Element == StyleViolation {
    var baselineViolations: [BaselineViolation] {
        var lineCache = LineCache()
        return map {
            $0.baselineViolation(text: lineCache.text(at: $0.location))
        }
    }
}

private struct LineCache {
    private var lines: [String: [String]] = [:]

    mutating func text(at location: Location) -> String {
        let line = (location.line ?? 0) - 1
        if line > 0, let file = location.file, let content = cached(file: file), line < content.count {
            return content[line]
        }
        return ""
    }

    private mutating func cached(file: String) -> [String]? {
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
    var violationsWithAbsolutePaths: [StyleViolation] {
        map { $0.violation.withAbsolutePath }
    }

    func groupedByFile() -> ViolationsPerFile {
        Dictionary(grouping: self) { $0.violation.location.relativeFile ?? "" }
    }

    func groupedByRuleIdentifier(filteredBy existingViolations: [BaselineViolation] = []) -> ViolationsPerRule {
        Dictionary(grouping: Set(self).subtracting(existingViolations), by: \.violation.ruleIdentifier)
    }
}

private extension StyleViolation {
    var withAbsolutePath: StyleViolation {
        let absolutePath: String? =
            if let relativePath = location.file {
                FileManager.default.currentDirectoryPath + "/" + relativePath
            } else {
                nil
            }
        let newLocation = Location(file: absolutePath, line: location.line, character: location.character)
        return with(location: newLocation)
    }

    func baselineViolation(text: String = "") -> BaselineViolation {
        BaselineViolation(violation: self, text: text)
    }
}
