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

        return violations.filter { filteredViolations.contains($0) }
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

