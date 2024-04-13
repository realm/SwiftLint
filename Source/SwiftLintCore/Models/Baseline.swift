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

    /// The stored violations.
    public var violations: [StyleViolation] {
        baselineViolations.keys.sorted().flatMap({ baselineViolations[$0]! }).violationsWithAbsolutePaths
    }

    /// Creates a `Baseline` from a saved file.
    ///
    /// - parameter fromPath: The path to read from.
    public init(fromPath path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        baselineViolations = try JSONDecoder().decode(GroupedViolations.self, from: data)
    }

    init(violations: [StyleViolation]) {
        baselineViolations = violations.baselineViolations.groupedByFile()
    }

    /// Writes a `Baseline` to disk in JSON format.
    ///
    /// - parameter violations: The violations to save.
    /// - parameter toPath: The path to write to.
    public static func write(_ violations: [StyleViolation], toPath path: String) throws {
        try write(violations.baselineViolations.groupedByFile(), toPath: path)
    }

    private static func write(_ violations: GroupedViolations, toPath path: String) throws {
        let data = try JSONEncoder().encode(violations)
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
                  let lineNumber = violation.location.line != nil ? violation.location.line! - 1 : nil,
                  lineNumber > 0 else {
                baselineViolations.append(BaselineViolation(violation: violation, text: ""))
                continue
            }
            if let fileLines = lines[absolutePath] {
                let text = (!fileLines.isEmpty && lineNumber < fileLines.count ) ? fileLines[lineNumber] : ""
                baselineViolations.append(BaselineViolation(violation: violation, text: text))
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
            baselineViolations.append(BaselineViolation(violation: violation, text: text))
        }
        return baselineViolations
    }
}

private extension Sequence where Element == BaselineViolation {
    var violationsWithAbsolutePaths: [StyleViolation] {
        map {
            let location = $0.violation.location
            let absolutePath: String?
            if let relativePath = location.file {
                absolutePath = FileManager.default.currentDirectoryPath + "/" + relativePath
            } else {
                absolutePath = nil
            }
            let newLocation = Location(file: absolutePath, line: location.line, character: location.character)
            return $0.violation.with(location: newLocation)
        }
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
