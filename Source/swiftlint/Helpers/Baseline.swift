import Foundation
import SwiftLintFramework

struct BaselineViolation: Equatable, Codable, Hashable {
    let violation: StyleViolation
    let line: String

    init(violation: StyleViolation, line: String) {
        let location = violation.location
        self.violation = violation.with(location: Location(
            // Within the baseline, we use relative paths, so that
            // comparisons are independent of the absolute path
            file: location.relativeFile,
            line: location.line,
            character: location.character)
        )
        self.line = line
    }
}

struct Baseline: Equatable {
    let violations: [String: [BaselineViolation]]

    init(fromPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let violations = try PropertyListDecoder().decode([String: [BaselineViolation]].self, from: data)
        self.violations = violations
    }

    init(violations: [StyleViolation]) {
        self.violations = violations.baselineViolations.groupedByFile()
    }

    static func write(_ violations: [StyleViolation], toPath path: String) throws {
        try write(violations.baselineViolations.groupedByFile(), toPath: path)
    }

    static func write(_ violations: [String: [BaselineViolation]], toPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try PropertyListEncoder().encode(violations)
        try data.write(to: url)
    }

    func filter(_ violations: [StyleViolation]) -> [StyleViolation] {
        guard let firstViolation = violations.first else {
            return []
        }
        guard let baselineViolations = self.violations[firstViolation.location.relativeFile ?? ""],
              baselineViolations.isNotEmpty else {
            return violations
        }

        let relativePathViolations = violations.baselineViolations
        guard relativePathViolations != baselineViolations else {
            return []
        }

        // remove any exactly identical matchaes
        let setOfViolations = Set(relativePathViolations)
        let setOfBaselineViolations = Set(baselineViolations)
        let remainingViolations = relativePathViolations.filter { !setOfBaselineViolations.contains($0) }
        let remainingBaselineViolations = baselineViolations.filter { !setOfViolations.contains($0) }
        let violationsByRuleIdentifier = remainingViolations.groupedByRuleIdentifier()
        let baselineViolationsByRuleIdentifier = remainingBaselineViolations.groupedByRuleIdentifier()

        var filteredViolations: Set<BaselineViolation> = []

        for (ruleIdentifier, ruleViolations) in violationsByRuleIdentifier {
            guard
                let baselineViolations = baselineViolationsByRuleIdentifier[ruleIdentifier],
                    baselineViolations.isNotEmpty else {
                filteredViolations.formUnion(ruleViolations)
                continue
            }
            let groupedRuleViolations = Dictionary(grouping: ruleViolations, by: { $0.line + $0.violation.reason })
            let groupedBaselineViolations = Dictionary(
                grouping: baselineViolations,
                by: { $0.line + $0.violation.reason }
            )

            for (line, ruleViolations) in groupedRuleViolations {
                guard let baselineViolations = groupedBaselineViolations[line] else {
                    filteredViolations.formUnion(ruleViolations)
                    continue
                }
                if ruleViolations.count > baselineViolations.count {
                    filteredViolations.formUnion(ruleViolations)
                }
            }
        }

        // Restore the absolute paths, and the original order of the violations
        let violationsWithAbsolutePaths = Set(filteredViolations.violationsWithAbsolutePaths)
        return violations.filter { violationsWithAbsolutePaths.contains($0) }
    }
}

private extension Sequence where Element == StyleViolation {
    var baselineViolations: [BaselineViolation] {
        var lines: [String: [String]] = [:]
        var result: [BaselineViolation] = []
        for violation in self {
            guard let file = violation.location.file, let lineNumber = violation.location.line else {
                result.append(BaselineViolation(violation: violation, line: ""))
                continue
            }
            if let fileLines = lines[file] {
                let line = (!fileLines.isEmpty && lineNumber < fileLines.count ) ? fileLines[lineNumber] : ""
                result.append(BaselineViolation(violation: violation, line: line))
            } else {
                let line: String
                if let fileLines = SwiftLintFile(path: file)?.lines.map({ $0.content }),
                   lineNumber < fileLines.count {
                    line = fileLines[lineNumber]
                    lines[file] = fileLines
                } else {
                    line = ""
                }
                result.append(BaselineViolation(violation: violation, line: line))
            }
        }
        return result
    }
}

private extension Sequence where Element == BaselineViolation {
    var violationsWithAbsolutePaths: [StyleViolation] {
        map {
            let location = $0.violation.location
            let file = location.file != nil ?
            FileManager.default.currentDirectoryPath + "/" + (location.file ?? "")
            : nil
            return $0.violation.with(location: Location(file: file, line: location.line, character: location.character))
        }
    }

    func groupedByFile() -> [String: [BaselineViolation]] {
        Dictionary(grouping: self) { $0.violation.location.relativeFile ?? "" }
    }

    func groupedByRuleIdentifier() -> [String: [BaselineViolation]] {
        Dictionary(grouping: self) { $0.violation.ruleIdentifier }
    }
}
