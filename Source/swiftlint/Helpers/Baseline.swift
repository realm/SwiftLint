import Foundation
import SwiftLintFramework

struct Baseline: Equatable {
    private let violations: [String: [StyleViolation]]

    init(fromPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let violations = try PropertyListDecoder().decode([String: [StyleViolation]].self, from: data)
        self.violations = violations
    }

    init(violations: [StyleViolation]) {
        self.violations = violations.groupedByFile()
    }

    func write(toPath path: String) throws {
        try Self.write(violations: violations, toPath: path)
    }

    static func write(violations: [StyleViolation], toPath path: String) throws {
        let violations = violations.groupedByFile()
        try write(violations: violations, toPath: path)
    }

    private static func write(violations: [String: [StyleViolation]], toPath path: String) throws {
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

        let relativePathViolations = violations.removeAbsolutePaths()
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

        var filteredViolations: Set<StyleViolation> = []

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
            return violations.filter { filteredViolations.contains($0) }
        }

        // Experimental extra filtering
        filteredViolations = filterViolationsByOrder(
            filteredViolations: filteredViolations,
            violations: relativePathViolations, // remainingViolations,
            baselineViolations: baselineViolations
        )

        return violations.filter { filteredViolations.contains($0) }
    }

    private func filterViolationsByOrder(
        filteredViolations: Set<StyleViolation>,
        violations: [StyleViolation],
        baselineViolations: [StyleViolation]
    ) -> Set<StyleViolation> {
        var filteredViolationsByRuleIdentifier = filteredViolations.groupedByRuleIdentifier()
        guard filteredViolationsByRuleIdentifier.filter({ $0.value.count > 1 }).isNotEmpty else {
            return filteredViolations
        }

        var orderedViolations: [StyleViolation] = []
        for (index, violation) in violations.enumerated() {
            let baselineViolationIndex = index - orderedViolations.count
            let baselineViolation = baselineViolationIndex < baselineViolations.count ?
            baselineViolations[baselineViolationIndex] : nil
            if let baselineViolation,
               violation.ruleIdentifier == baselineViolation.ruleIdentifier,
               violation.reason == baselineViolation.reason,
               violation.severity == baselineViolation.severity {
                continue
            }
            orderedViolations.append(violation)
        }

        let groupedOrderedViolations = orderedViolations.groupedByRuleIdentifier()
        let groupedBaselineViolations = baselineViolations.groupedByRuleIdentifier()
        for (ruleIdentifier, orderedViolations) in groupedOrderedViolations {
            if let filteredViolationsForRule = filteredViolationsByRuleIdentifier[ruleIdentifier] {
                let newOrderedViolations: [StyleViolation]
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
    func groupedByFile() -> [String: [StyleViolation]] {
        Dictionary(
            grouping: self,
            by: { $0.location.relativeFile ?? "" }
        ).mapValues { $0.removeAbsolutePaths() }
    }

    func groupedByRuleIdentifier() -> [String: [StyleViolation]] {
        Dictionary(grouping: self) { $0.ruleIdentifier }
    }

    func removeAbsolutePaths() -> [StyleViolation] {
        self.map {
            $0.with(location: Location(
                file: $0.location.relativeFile,
                line: $0.location.line,
                character: $0.location.character)
            )
        }
    }
}
