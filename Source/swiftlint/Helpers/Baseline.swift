import Foundation
import SwiftLintFramework

struct BaselineViolation: Equatable, Codable, Hashable {
    let violation: StyleViolation
    let line: String

    init(violation: StyleViolation, line: String) {
        let location = violation.location
        self.violation = violation.with(location: Location(
            file: location.relativeFile,
            line: location.line,
            character: location.character)
        )
        self.line = line
    }
}

struct Baseline: Equatable {
    private let violations: [String: [BaselineViolation]]

    init(fromPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let violations = try PropertyListDecoder().decode([String: [BaselineViolation]].self, from: data)
        self.violations = violations
    }

    init(violations: [StyleViolation]) {
        // we need to convert and read the lines here
        let baselineViolations = violations.baselineViolations
        self.violations = baselineViolations.groupedByFile()
    }

    func write(toPath path: String) throws {
        try Self.write(violations: violations, toPath: path)
    }

    static func write(violations: [StyleViolation], toPath path: String) throws {
        let baselineViolations = violations.baselineViolations
        let violations = baselineViolations.groupedByFile()
        try write(violations: violations, toPath: path)
    }

    private static func write(violations: [String: [BaselineViolation]], toPath path: String) throws {
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

        // remove any that are identical
        let setOfViolations = Set(relativePathViolations)
        let setOfBaselineViolations = Set(baselineViolations)
        let remainingViolations = relativePathViolations.filter { !setOfBaselineViolations.contains($0) }
        let remainingBaselineViolations = baselineViolations.filter { !setOfViolations.contains($0) }
        let violationsByRuleIdentifier = remainingViolations.groupedByRuleIdentifier()
        let baselineViolationsByRuleIdentifier = remainingBaselineViolations.groupedByRuleIdentifier()

        var filteredViolations: Set<BaselineViolation> = []

        for (ruleIdentifier, ruleViolations) in violationsByRuleIdentifier {
            guard let baselineViolations = baselineViolationsByRuleIdentifier[ruleIdentifier] else {
                filteredViolations.formUnion(ruleViolations)
                continue
            }
            guard ruleViolations.count > baselineViolations.count else {
                continue
            }
            // TODO: We need to try to work out which ones are new here
            filteredViolations.formUnion(ruleViolations)
        }

        guard filteredViolations.count > 1 else {
            let originalViolations = Set(filteredViolations.originalViolations)
            return violations.filter { originalViolations.contains($0) }
        }

        // Experimental extra filtering
        filteredViolations = filterViolationsByOrder(
            filteredViolations: filteredViolations,
            violations: relativePathViolations, // remainingViolations,
            baselineViolations: baselineViolations
        )

        let originalViolations = Set(filteredViolations.originalViolations)
        return violations.filter { originalViolations.contains($0) }
    }

    private func filterViolationsByOrder(
        filteredViolations: Set<BaselineViolation>,
        violations: [BaselineViolation],
        baselineViolations: [BaselineViolation]
    ) -> Set<BaselineViolation> {
        var filteredViolationsByRuleIdentifier = filteredViolations.groupedByRuleIdentifier()
        guard filteredViolationsByRuleIdentifier.filter({ $0.value.count > 1 }).isNotEmpty else {
            return filteredViolations
        }

        var orderedViolations: [BaselineViolation] = []
        for (index, violation) in violations.enumerated() {
            let baselineViolationIndex = index - orderedViolations.count
            let baselineViolation = baselineViolationIndex < baselineViolations.count ?
            baselineViolations[baselineViolationIndex] : nil
            if let baselineViolation,
               violation.violation.ruleIdentifier == baselineViolation.violation.ruleIdentifier,
               violation.violation.reason == baselineViolation.violation.reason,
               violation.violation.severity == baselineViolation.violation.severity {
                continue
            }
            orderedViolations.append(violation)
        }

        let groupedOrderedViolations = orderedViolations.groupedByRuleIdentifier()
        let groupedBaselineViolations = baselineViolations.groupedByRuleIdentifier()
        for (ruleIdentifier, orderedViolations) in groupedOrderedViolations {
            if let filteredViolationsForRule = filteredViolationsByRuleIdentifier[ruleIdentifier] {
                let newOrderedViolations: [BaselineViolation]
                if let baselineViolations = groupedBaselineViolations[ruleIdentifier] {
                    newOrderedViolations = orderedViolations.filter { !baselineViolations.contains($0) }
                } else {
                    newOrderedViolations = orderedViolations
                }
                if newOrderedViolations.count < filteredViolationsForRule.count {
                    // If we found fewer violations by ordering, report the lower number
                    filteredViolationsByRuleIdentifier[ruleIdentifier] = newOrderedViolations
                }
            }
        }
        return Set(filteredViolationsByRuleIdentifier.flatMap { _, value in value })
    }
}

private extension Sequence where Element == StyleViolation {
    var baselineViolations: [BaselineViolation] {
        var lines: [String:[String]] = [:]
        var result: [BaselineViolation] = []
        for violation in self {
            if let file = violation.location.file, let lineNumber = violation.location.line {
                if let lines = lines[file] {
                    let line = (lines.count > 0 && lineNumber < lines.count ) ? lines[lineNumber] : ""
                    result.append(BaselineViolation(violation: violation, line: line))
                } else {
                    // Try to read the lines here ...
                    result.append(BaselineViolation(violation: violation, line: ""))
                }
            } else {
                result.append(BaselineViolation(violation: violation, line: ""))
            }
        }
        return result
    }
}

private extension Sequence where Element == BaselineViolation {
    var originalViolations: [StyleViolation] {
        map {
            let location = $0.violation.location
            let file = location.file != nil ? FileManager.default.currentDirectoryPath + "/" + (location.file ?? "") : nil
            return $0.violation.with(location: Location(
                file: file,
                line: location.line,
                character: location.character
            ))
        }
    }

    func groupedByFile() -> [String: [BaselineViolation]] {
        Dictionary(
            grouping: self,
            by: { $0.violation.location.relativeFile ?? "" }
        )
    }

    func groupedByRuleIdentifier() -> [String: [BaselineViolation]] {
        Dictionary(grouping: self) { $0.violation.ruleIdentifier }
    }
}
