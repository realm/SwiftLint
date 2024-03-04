import Foundation

typealias GroupedViolations = [String: [BaselineViolation]]

struct BaselineViolation: Equatable, Codable, Hashable {
    let violation: StyleViolation
    let text: String
    var key: String { text + violation.reason }

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

public struct Baseline: Equatable {
    private let violations: GroupedViolations

    public init(fromPath path: String) throws {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        self.violations = try PropertyListDecoder().decode([String: [BaselineViolation]].self, from: data)
    }

    init(violations: [StyleViolation]) {
        self.violations = violations.baselineViolations.groupedByFile()
    }

    public static func write(_ violations: [StyleViolation], toPath path: String) throws {
        try write(violations.baselineViolations.groupedByFile(), toPath: path)
    }

    static func write(_ violations: GroupedViolations, toPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try PropertyListEncoder().encode(violations)
        try data.write(to: url)
    }

    public func filter(_ violations: [StyleViolation]) -> [StyleViolation] {
        guard let firstViolation = violations.first,
              let baselineViolations = self.violations[firstViolation.location.relativeFile ?? ""],
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

            let groupedRuleViolations = Dictionary(grouping: ruleViolations) { $0.key }
            let groupedBaselineViolations = Dictionary(grouping: baselineViolations) { $0.key }

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
            if let fileLines = SwiftLintFile(path: absolutePath)?.lines.map({ $0.content }),
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
        let setOfExistingViolations = Set(existingViolations)
        let remainingViolations = filter { !setOfExistingViolations.contains($0) }
        return remainingViolations.groupedByRuleIdentifier()
    }
}
