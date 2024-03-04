import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct ReportBaseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Reports the violations in a saved Baseline."
        )

        @Option(help: "The reporter used to log errors and warnings.")
        var reporter: String?
        @Option(help: "The path to a baseline file.")
        var baseline: String?
        @Option(help: "The file where violations should be saved. Prints to stdout by default.")
        var output: String?

        func run() throws {
            guard let baselinePath = baseline else {
                throw SwiftLintError.usageError(description: "You must specify a baseline")
            }

            let savedBaseline = try Baseline(fromPath: baselinePath)
            let reporterIdentifier = reporter ?? defaultReporterIdentifier()
            let reporter = reporterFrom(identifier: reporterIdentifier)
            let report = reporter.generateReport(savedBaseline.styleViolations)
            guard report.isNotEmpty else {
                return
            }
            if let output {
                let data = Data((report + "\n").utf8)
                do {
                    try data.write(to: URL(fileURLWithPath: output))
                } catch {
                    Issue.fileNotWritable(path: output).print()
                }
            } else {
                queuedPrint(report)
            }
            ExitHelper.successfullyExit()
        }
    }
}
