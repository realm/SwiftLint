import Foundation
import SwiftLintFramework

struct Baseline: Equatable {
    private let violations: [String: [StyleViolation]]

    init(fromPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        let violations = try decoder.decode([String: [StyleViolation]].self, from: data)
        self.violations = violations
    }

    init(violations: [StyleViolation]) {
        self.violations = violations.groupByFile()
    }

    func write(toPath path: String) throws {
        try Self.write(violations: violations, toPath: path)
    }

    static func write(violations: [StyleViolation], toPath path: String) throws {
        let violations = violations.groupByFile()
        try write(violations: violations, toPath: path)
    }

    private static func write(violations: [String: [StyleViolation]], toPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(violations)
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

        let convertedViolations = violations.removeAbsolutePaths()
        guard convertedViolations != baselineViolations else {
            return []
        }

        // remove any that are identical
        let setOfViolations = Set(convertedViolations)
        let setOfBaselineViolations = Set(baselineViolations)
        let remainingViolations = convertedViolations.filter { !setOfBaselineViolations.contains($0) }
        let remainingBaselineViolations = baselineViolations.filter { !setOfViolations.contains($0) }
        let violationsByRuleIdentifier = Dictionary(grouping: remainingViolations, by: { $0.ruleIdentifier })
        let baselineViolationsByRuleIdentifier = Dictionary(
            grouping: remainingBaselineViolations,
            by: { $0.ruleIdentifier }
        )

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
            violations: remainingViolations,
            baselineViolations: remainingBaselineViolations
        )

        return violations.filter { filteredViolations.contains($0) }
    }

    private func filterViolationsByOrder(
        filteredViolations: Set<StyleViolation>,
        violations: [StyleViolation],
        baselineViolations: [StyleViolation]
    ) -> Set<StyleViolation> {
        var filteredViolationsByRuleIdentifier = Dictionary(
            grouping: filteredViolations,
            by: { $0.ruleIdentifier }
        )
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

        let groupedOrderedViolations = Dictionary(grouping: orderedViolations, by: { $0.ruleIdentifier })
        for (ruleIdentifier, orderedViolations) in groupedOrderedViolations {
            if let filteredViolationsForRule = filteredViolationsByRuleIdentifier[ruleIdentifier] {
                if orderedViolations.count < filteredViolationsForRule.count {
                    // If we found fewer violations by ordering, report the lower number
                    filteredViolationsByRuleIdentifier[ruleIdentifier] = orderedViolations
                }
            }
        }
        return Set(filteredViolationsByRuleIdentifier.flatMap { _, value in value })
    }
}

private extension Array where Element == StyleViolation {
    func groupByFile() -> [String: [StyleViolation]] {
        Dictionary(
            grouping: self,
            by: { $0.location.relativeFile ?? "" }
        ).mapValues { $0.removeAbsolutePaths() }
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
