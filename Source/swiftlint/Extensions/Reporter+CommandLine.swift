import SwiftLintFramework

extension Reporter {
    /**
     Optionally reports violations as they are found.
             
        - Parameters:
            - violations: An array of `StyleViolation` to report.
            - realtimeCondition: When enabled, output the report as violations are found.
    */
    static func report(violations: [StyleViolation], realtimeCondition: Bool) {
        if isRealtime == realtimeCondition {
            let report = generateReport(violations)
            if !report.isEmpty {
                queuedPrint(report)
            }
        }
    }
}

/**
    Returns a reporter that corresponds with a defined identifier.
 
    - Parameters:
        - optionsReporter: An optional string that identifies the options.
        - configuration: A `Configuration` value.
    - Returns: A `Reporter` for the options, `Configuration` otherwise.
 */
func reporterFrom(optionsReporter: String?, configuration: Configuration) -> Reporter.Type {
    return reporterFrom(identifier: optionsReporter ?? configuration.reporter)
}
