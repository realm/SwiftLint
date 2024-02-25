import Foundation
import SwiftLintFramework

class Baseline {
    private let violations: [String: [StyleViolation]]

    init(fromPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        let decoder = PropertyListDecoder()
        let violations = try decoder.decode([String: [StyleViolation]].self, from: data)
        self.violations = violations
    }

    class func write(violations: [StyleViolation], toPath path: String) throws {
        let url = URL(fileURLWithPath: path)
        let encoder = PropertyListEncoder()
        let violationsMap = Dictionary(grouping: violations, by: { $0.location.relativeFile ?? "" })
        let data = try encoder.encode(violationsMap)
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
            let baselineViolation = index < baselineViolations.count ? baselineViolations[index] : nil
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
