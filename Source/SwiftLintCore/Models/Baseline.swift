import Foundation

private typealias GroupedViolations = [String: [BaselineViolation]]

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
    private let baselineViolations: GroupedViolations
    private var sortedBaselineViolations: [BaselineViolation] {
        baselineViolations.map { ($0, $1) }.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
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
        guard relativePathViolations != baselineViolations else {
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
}

private extension Sequence where Element == StyleViolation {
    var baselineViolations: [BaselineViolation] {
        var lines: [String: [String]] = [:]
        var baselineViolations: [BaselineViolation] = []
        for violation in self {
            guard let absolutePath = violation.location.file,
                  let lineNumber = violation.location.line != nil ? (violation.location.line ?? 0) - 1 : nil,
                  lineNumber > 0 else {
                baselineViolations.append(violation.baselineViolation())
                continue
            }
            if let fileLines = lines[absolutePath] {
                let text = (!fileLines.isEmpty && lineNumber < fileLines.count ) ? fileLines[lineNumber] : ""
                baselineViolations.append(violation.baselineViolation(text: text))
                continue
            }
            let text: String
            if let fileLines = SwiftLintFile(path: absolutePath)?.lines.map(\.content),
               lineNumber < fileLines.count {
                text = fileLines[lineNumber]
                lines[absolutePath] = fileLines
            } else {
                text = ""
            }
            baselineViolations.append(violation.baselineViolation(text: text))
        }
        return baselineViolations
    }
}

private extension Sequence where Element == BaselineViolation {
    var violationsWithAbsolutePaths: [StyleViolation] {
        map { $0.violation.withAbsolutePath }
    }

    func groupedByFile() -> GroupedViolations {
        Dictionary(grouping: self) { $0.violation.location.relativeFile ?? "" }
    }

    func groupedByRuleIdentifier() -> GroupedViolations {
        Dictionary(grouping: self) { $0.violation.ruleIdentifier }
    }

    func groupedByRuleIdentifier(filteredBy existingViolations: [BaselineViolation]) -> GroupedViolations {
        Set(self).subtracting(existingViolations).groupedByRuleIdentifier()
    }
}

private extension StyleViolation {
    var withAbsolutePath: StyleViolation {
        let absolutePath: String?
        if let relativePath = location.file {
            absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
        } else {
            absolutePath = nil
        }
        let newLocation = Location(file: absolutePath, line: location.line, character: location.character)
        return with(location: newLocation)
    }

    func baselineViolation(text: String = "") -> BaselineViolation {
        BaselineViolation(violation: self, text: text)
    }
}
