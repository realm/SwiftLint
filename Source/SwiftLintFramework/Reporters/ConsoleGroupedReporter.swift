import SwiftyTextTable

public struct ConsoleGroupedReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "console-grouped"
    public static let isRealtime = false

    public var description: String {
        return "Reports how many times certain violations are broken."
    }
    
    private static func groupByIdentifiers(violations: [StyleViolation]) -> [[StyleViolation]] {
        var groupedArrays = [[StyleViolation]]()
        
        let violationsGroupedByIdentifier = Dictionary(grouping: violations) { $0.ruleIdentifier }
        for key in violationsGroupedByIdentifier.keys {
            if let violations = violationsGroupedByIdentifier[key] {
                groupedArrays.append(violations)
            }
        }
        
        return groupedArrays
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        let errors = violations.filter { $0.severity == .error }
        let warnings = violations.filter { $0.severity == .warning }

        var groupedErrors = groupByIdentifiers(violations: errors)
        groupedErrors.sort {$0.count > $1.count}
        
        var groupedWarnings = groupByIdentifiers(violations: warnings)
        groupedWarnings.sort {$0.count > $1.count}

        var errorsTable = TextTable(groupedViolations: groupedErrors)
        errorsTable.header = "Errors: \(errors.count)"

        var warningsTable = TextTable(groupedViolations: groupedWarnings)
        warningsTable.header = "Warnings: \(warnings.count)"

        return """

            \(errorsTable.render())

            \(warningsTable.render())

            """
    }
}

private extension TextTable {
    init(groupedViolations: [[StyleViolation]]) {
        let columns = [
            TextTableColumn(header: "Count"),
            TextTableColumn(header: "Correctable"),
            TextTableColumn(header: "Name"),
            TextTableColumn(header: "Rule ID")
        ]
        self.init(columns: columns)

        for violations in groupedViolations {
            if let violation = violations.first {
                self.addRow(values: [
                    violations.count,
                    violation.isCorrectable ? "YES" : "NO",
                    violation.ruleName,
                    violation.ruleIdentifier
                ])
            }
        }
    }
}

private extension StyleViolation {
    var isCorrectable: Bool {
        primaryRuleList.list[self.ruleIdentifier] is CorrectableRule.Type
    }
}
