import SwiftyTextTable

public struct GroupedReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "grouped"
    public static let isRealtime = false

    public var description: String {
        return "Reports how many times certain violations are broken."
    }

    private static func groupViolations(_ violations: [StyleViolation],
                                        WithViolationsSeverity severity: ViolationSeverity) -> [[StyleViolation]] {
        
        let groupedBySeverity = Dictionary(grouping: violations) { $0.severity }
        var groupedArrays = [[StyleViolation]]()
        
        if let errorViolations = groupedBySeverity[severity] {
            let groupedErrorViolations = Dictionary(grouping: errorViolations) { $0.ruleIdentifier }
            for key in groupedErrorViolations.keys {
                if let violations = groupedErrorViolations[key] {
                    groupedArrays.append(violations)
                }
            }
        }
        
        groupedArrays.sort { (array0, array1) -> Bool in
            return array0.count > array1.count
        }
        return groupedArrays
    }
    
    public static func generateReport(_ violations: [StyleViolation]) -> String {
        var report = ""
        
        let errorsCount = violations.filter{ $0.severity == .error }.count
        let warningsCount = violations.filter{ $0.severity == .warning }.count
        
        let groupedErrors = groupViolations(violations, WithViolationsSeverity: .error)
        let groupdeWarnings = groupViolations(violations, WithViolationsSeverity: .warning)
        
        var errorsTable = TextTable(groupedViolations: groupedErrors)
        errorsTable.header = "Errors: \(errorsCount)\n"
        
        var warningsTable = TextTable(groupedViolations: groupdeWarnings)
        warningsTable.header = "Errors: \(warningsCount)\n"

        report.append(errorsTable.render())
        report.append("\n\n\n")
        report.append(warningsTable.render())
        
        return report
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
        if let rule = primaryRuleList.list[self.ruleIdentifier], rule.init() is CorrectableRule {
            return true
        } else {
            return false
        }
    }
}
