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
        let numberOfViolationHeader = "number of violations"
        let numberOfFileHeader = "number of files"
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "opt-in"),
            TextTableColumn(header: "correctable"),
            TextTableColumn(header: numberOfViolationHeader),
            TextTableColumn(header: numberOfFileHeader)
        ]
        self.init(columns: columns)

        let ruleIdentifiersToViolationsMap = ruleIdentifiersToViolationsMap(violations: violations)
        let ruleIdentifiers = ruleIdentifiersToViolationsMap.keys
        let sortedRuleIdentifiers = ruleIdentifiers.sorted {
            (ruleIdentifiersToViolationsMap[$0]?.count ?? 0) > (ruleIdentifiersToViolationsMap[$1]?.count ?? 0)
        }

        for ruleIdentifier in sortedRuleIdentifiers {
            guard let ruleIdentifier = ruleIdentifiersToViolationsMap[ruleIdentifier]?.first?.ruleIdentifier else {
                continue
            }
            guard let ruleType = builtInRules.first(where: { $0.description.identifier == ruleIdentifier }) else {
                continue
            }
            let rule = ruleType.init()

            let numberOfViolationsString = "\(ruleIdentifiersToViolationsMap[ruleIdentifier]?.count ?? 0)"
            let setOfFiles = Set((ruleIdentifiersToViolationsMap[ruleIdentifier] ?? []).map { $0.location.file })
            let numberOfFilesString = "\(setOfFiles.count)"

            addRow(values: [
                ruleIdentifier,
                (rule is OptInRule) ? "yes" : "no",
                (rule is CorrectableRule) ? "yes" : "no",
                numberOfViolationsString.leftPadded(count: numberOfViolationHeader.count)
                numberOfFilesString.leftPadded(count: numberOfFileHeader.count)
            ])
        }
    }

    private func ruleIdentifiersToViolationsMap(violations: [StyleViolation]) -> [String: [StyleViolation]] {
        var map: [String: [StyleViolation]] = [:]
        for violation in violations {
            let key = violation.ruleIdentifier
            if var array = map[key] {
                array.append(violation)
                map[key] = array
            } else {
                map[key] = [violation]
            }
        }
        return map
    }
}

private extension String {
    func leftPadded(count: Int) -> String {
        String(repeating: " ", count: count - self.count) + self
    }
}
