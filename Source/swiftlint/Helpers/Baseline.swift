import Foundation
import SwiftLintFramework


struct Baseline : Equatable {
    private let violations: [String: [StyleViolation]]

    init(fromPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        let violations = try decoder.decode([String: [StyleViolation]].self, from: data)
        self.violations = violations
    }

    init(violations: [StyleViolation]) {
        self.violations = Dictionary(grouping: violations, by: { $0.location.relativeFile ?? "" })
    }

    func write(toPath path: String) throws {
        try Self.write(violations: violations, toPath: path)
    }

    static func write(violations: [StyleViolation], toPath path: String) throws {
        let violations = Dictionary(grouping: violations, by: { $0.location.relativeFile ?? "" })
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
        guard let baselineViolations = self.violations[firstViolation.location.relativeFile ?? ""], baselineViolations.isNotEmpty else {
            return violations
        }
        if violations == baselineViolations {
            return []
        }
        var filteredViolations: [StyleViolation] = []
        for (index, violation) in violations.enumerated() {
            let baselineViolationIndex = index - filteredViolations.count
            let baselineViolation = baselineViolationIndex < baselineViolations.count ? baselineViolations[baselineViolationIndex] : nil
            if let baselineViolation,
               violation.ruleIdentifier == baselineViolation.ruleIdentifier,
               violation.reason == baselineViolation.reason,
               violation.severity == baselineViolation.severity {
                continue
            }
            filteredViolations.append(violation)
        }

        return filteredViolations
    }
}
