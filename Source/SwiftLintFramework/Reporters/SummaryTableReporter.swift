import SwiftyTextTable

/// Reports a summary table of all violations
public struct SummaryTableReporter: Reporter {
    // MARK: - Reporter Conformance
    
    public static let identifier = "summary-table"
    public static let isRealtime = false
    
    public var description: String {
        return "Reports a summary table of all violations."
    }
    
    public static func generateReport(_ violations: [StyleViolation]) -> String {
        TextTable(violations: violations).render()
    }
}

// MARK: - SwiftyTextTable
private extension TextTable {
    init(violations: [StyleViolation]) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "number of violations"),
        ]
        self.init(columns: columns)
        
        let identifierToViolationsMap = Dictionary(grouping: violations) { (violation) -> String in
            violation.ruleIdentifier
        }
        let ruleIdentifiers = identifierToViolationsMap.keys
        
        for ruleIdentifier in ruleIdentifiers {
            addRow(values: [
                ruleIdentifier,
                identifierToViolationsMap[ruleIdentifier]?.count ?? 0
            ])
        }
    }
}
