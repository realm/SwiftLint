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
        TextTable(violations: violations).renderWithExtraSeparator()
    }
}

// MARK: - SwiftyTextTable

private extension TextTable {
    // swiftlint:disable:next function_body_length
    init(violations: [StyleViolation]) {
        let numberOfWarningsHeader = "warnings"
        let numberOfErrorsHeader = "errors"
        let numberOfViolationsHeader = "total violations"
        let numberOfFilesHeader = "number of files"
        let columns = [
            TextTableColumn(header: "rule identifier"),
            TextTableColumn(header: "opt-in"),
            TextTableColumn(header: "correctable"),
            TextTableColumn(header: "custom"),
            TextTableColumn(header: numberOfWarningsHeader),
            TextTableColumn(header: numberOfErrorsHeader),
            TextTableColumn(header: numberOfViolationsHeader),
            TextTableColumn(header: numberOfFilesHeader)
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

        var totalNumberOfWarnings = 0
        var totalNumberOfErrors = 0

        for ruleIdentifier in sortedRuleIdentifiers {
            guard let ruleIdentifier = ruleIdentifiersToViolationsMap[ruleIdentifier]?.first?.ruleIdentifier else {
                continue
            }

            let rule = primaryRuleList.list[ruleIdentifier]
            let violations = ruleIdentifiersToViolationsMap[ruleIdentifier]
            let numberOfWarnings = violations?.filter { $0.severity == .warning }.count ?? 0
            let numberOfErrors = violations?.filter { $0.severity == .error }.count ?? 0
            let numberOfViolations = numberOfWarnings + numberOfErrors
            totalNumberOfWarnings += numberOfWarnings
            totalNumberOfErrors += numberOfErrors
            let ruleViolations = ruleIdentifiersToViolationsMap[ruleIdentifier] ?? []
            let numberOfFiles = Set(ruleViolations.map { $0.location.file }).count

            addRow(values: [
                ruleIdentifier,
                rule is OptInRule.Type ? "yes" : "no",
                rule is CorrectableRule.Type ? "yes" : "no",
                rule == nil ? "yes" : "no",
                numberOfWarnings.formattedString.leftPadded(forHeader: numberOfWarningsHeader),
                numberOfErrors.formattedString.leftPadded(forHeader: numberOfErrorsHeader),
                numberOfViolations.formattedString.leftPadded(forHeader: numberOfViolationsHeader),
                numberOfFiles.formattedString.leftPadded(forHeader: numberOfFilesHeader)
            ])
        }

        let totalNumberOfViolations = totalNumberOfWarnings + totalNumberOfErrors
        let totalNumberOfFiles = Set(violations.map { $0.location.file }).count
        addRow(values: [
            "Total",
            "",
            "",
            "",
            totalNumberOfWarnings.formattedString.leftPadded(forHeader: numberOfWarningsHeader),
            totalNumberOfErrors.formattedString.leftPadded(forHeader: numberOfErrorsHeader),
            totalNumberOfViolations.formattedString.leftPadded(forHeader: numberOfViolationsHeader),
            totalNumberOfFiles.formattedString.leftPadded(forHeader: numberOfFilesHeader)
        ])
    }

    func renderWithExtraSeparator() -> String {
        var output = render()
        var lines = output.components(separatedBy: "\n")
        if lines.count > 5, let lastLine = lines.last {
            lines.insert(lastLine, at: lines.count - 2)
            output = lines.joined(separator: "\n")
        }
        return output
    }
}

private extension String {
    func leftPadded(forHeader header: String) -> String {
        let headerCount = header.count - self.count
        if headerCount > 0 {
            return String(repeating: " ", count: headerCount) + self
        }
        return self
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
