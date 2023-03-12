import SwiftyTextTable

/// Reports a summary table of all violations
public struct SummaryReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "summary"
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

        let ruleIdentifiersToViolationsMap = violations.group { $0.ruleIdentifier }
        let sortedRuleIdentifiers = ruleIdentifiersToViolationsMap.keys.sorted {
            (ruleIdentifiersToViolationsMap[$0]?.count ?? 0) > (ruleIdentifiersToViolationsMap[$1]?.count ?? 0)
        }

        var totalNumberOfViolations = 0

        for ruleIdentifier in sortedRuleIdentifiers {
            guard let ruleIdentifier = ruleIdentifiersToViolationsMap[ruleIdentifier]?.first?.ruleIdentifier else {
                continue
            }
            guard let ruleType = builtInRules.first(where: { $0.description.identifier == ruleIdentifier }) else {
                continue
            }
            let rule = ruleType.init()

            let numberOfViolations = ruleIdentifiersToViolationsMap[ruleIdentifier]?.count ?? 0
            totalNumberOfViolations += numberOfViolations
            let numberOfFiles = Set((ruleIdentifiersToViolationsMap[ruleIdentifier] ?? []).map { $0.location.file }).count

            addRow(values: [
                ruleIdentifier,
                (rule is OptInRule) ? "yes" : "no",
                (rule is CorrectableRule) ? "yes" : "no",
                "\(numberOfViolations)".leftPadded(count: numberOfViolationHeader.count),
                "\(numberOfFiles)".leftPadded(count: numberOfFileHeader.count)
            ])
        }

        let totalNumberOfFiles = Set(violations.map { $0.location.file }).count
        addRow(values: [
            "Total",
            "",
            "",
            "\(totalNumberOfViolations)".leftPadded(count: numberOfViolationHeader.count),
            "\(totalNumberOfFiles)".leftPadded(count: numberOfFileHeader.count)
        ])
    }
}

private extension String {
    func leftPadded(count: Int) -> String {
        String(repeating: " ", count: count - self.count) + self
    }
}
