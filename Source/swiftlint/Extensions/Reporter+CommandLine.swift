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

func reporterFrom(options: LintOptions, configuration: Configuration) -> Reporter.Type {
    let string = options.reporter.isEmpty ? configuration.reporter : options.reporter
    return reporterFrom(identifier: string)
}
