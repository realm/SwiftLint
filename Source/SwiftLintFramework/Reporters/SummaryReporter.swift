import Foundation
import SwiftyTextTable

/// Reports a summary table of all violations
struct SummaryReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "summary"
    static let isRealtime = false

    static let description = "Reports a summary table of all violations."

    static func generateReport(_ violations: [StyleViolation]) -> String {
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
            TextTableColumn(header: numberOfFilesHeader),
        ]
        self.init(columns: columns)

        let ruleIdentifiersToViolationsMap = violations.group { $0.ruleIdentifier }
        let sortedRuleIdentifiers = ruleIdentifiersToViolationsMap.sorted { lhs, rhs in
            let count1 = lhs.value.count
            let count2 = rhs.value.count
            if count1 > count2 {
                return true
            }
            if count1 == count2 {
                return lhs.key < rhs.key
            }
            return false
        }.map(\.key)

        var totalNumberOfWarnings = 0
        var totalNumberOfErrors = 0

        for ruleIdentifier in sortedRuleIdentifiers {
            guard let ruleIdentifier = ruleIdentifiersToViolationsMap[ruleIdentifier]?.first?.ruleIdentifier else {
                continue
            }

            let rule = RuleRegistry.shared.rule(forID: ruleIdentifier)
            let violations = ruleIdentifiersToViolationsMap[ruleIdentifier]
            let numberOfWarnings = violations?.filter { $0.severity == .warning }.count ?? 0
            let numberOfErrors = violations?.filter { $0.severity == .error }.count ?? 0
            let numberOfViolations = numberOfWarnings + numberOfErrors
            totalNumberOfWarnings += numberOfWarnings
            totalNumberOfErrors += numberOfErrors
            let ruleViolations = ruleIdentifiersToViolationsMap[ruleIdentifier] ?? []
            let numberOfFiles = Set(ruleViolations.map(\.location.file)).count

            addRow(values: [
                ruleIdentifier,
                rule is any OptInRule.Type ? "yes" : "no",
                rule is any CorrectableRule.Type ? "yes" : "no",
                rule == nil ? "yes" : "no",
                numberOfWarnings.formattedString.leftPadded(forHeader: numberOfWarningsHeader),
                numberOfErrors.formattedString.leftPadded(forHeader: numberOfErrorsHeader),
                numberOfViolations.formattedString.leftPadded(forHeader: numberOfViolationsHeader),
                numberOfFiles.formattedString.leftPadded(forHeader: numberOfFilesHeader),
            ])
        }

        let totalNumberOfViolations = totalNumberOfWarnings + totalNumberOfErrors
        let totalNumberOfFiles = Set(violations.map(\.location.file)).count
        addRow(values: [
            "Total",
            "",
            "",
            "",
            totalNumberOfWarnings.formattedString.leftPadded(forHeader: numberOfWarningsHeader),
            totalNumberOfErrors.formattedString.leftPadded(forHeader: numberOfErrorsHeader),
            totalNumberOfViolations.formattedString.leftPadded(forHeader: numberOfViolationsHeader),
            totalNumberOfFiles.formattedString.leftPadded(forHeader: numberOfFilesHeader),
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
    private static let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    var formattedString: String {
        // swiftlint:disable:next legacy_objc_type
        Int.numberFormatter.string(from: NSNumber(value: self)) ?? ""
    }
}
