import Foundation
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
        var table = TextTable(violations: violations).render()
        if violations.isEmpty == false {
            var lines = table.components(separatedBy: "\n")
            if lines.count >= 2, let lastLine = lines.last {
                lines.insert(lastLine, at: lines.count - 2)
            }
            table = lines.joined(separator: "\n")
        }
        return table
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
            let count1 = ruleIdentifiersToViolationsMap[$0]?.count ?? 0
            let count2 = ruleIdentifiersToViolationsMap[$1]?.count ?? 0
            if count1 > count2 {
                return true
            } else if count1 == count2 {
                return $0 < $1
            }
            return false
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
            let ruleViolations = ruleIdentifiersToViolationsMap[ruleIdentifier] ?? []
            let numberOfFiles = Set(ruleViolations.map { $0.location.file }).count

            addRow(values: [
                ruleIdentifier,
                (rule is OptInRule) ? "yes" : "no",
                (rule is CorrectableRule) ? "yes" : "no",
                numberOfViolations.formattedString.leftPadded(count: numberOfViolationHeader.count),
                numberOfFiles.formattedString.leftPadded(count: numberOfFileHeader.count)
            ])
        }

        let totalNumberOfFiles = Set(violations.map { $0.location.file }).count
        addRow(values: [
            "Total",
            "",
            "",
            totalNumberOfViolations.formattedString.leftPadded(count: numberOfViolationHeader.count),
            totalNumberOfFiles.formattedString.leftPadded(count: numberOfFileHeader.count)
        ])
    }
}

private extension String {
    func leftPadded(count: Int) -> String {
        String(repeating: " ", count: count - self.count) + self
    }
}

private extension Int {
    private static var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    var formattedString: String {
        // swiftlint:disable:next legacy_objc_type
        Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
