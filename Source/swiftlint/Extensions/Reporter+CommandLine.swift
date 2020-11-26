import SwiftLintFramework

extension Reporter {
    static func report(violations: [StyleViolation], realtimeCondition: Bool) {
        if isRealtime == realtimeCondition {
            let report = generateReport(violations)
            if !report.isEmpty {
                queuedPrint(report)
            }
        }
    }
}

func reporterFrom(optionsReporter: String?, configuration: Configuration) -> Reporter.Type {
    return reporterFrom(identifier: optionsReporter ?? configuration.reporter)
}
