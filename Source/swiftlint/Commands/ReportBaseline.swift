import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct ReportBaseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Reports the violations in a saved Baseline."
        )

        @Option(help: "The path to a baseline file.")
        var baseline: String
        @Option(help: "The reporter used to log errors and warnings.")
        var reporter: String?
        @Option(help: "The file where violations should be saved. Prints to stdout by default.")
        var output: String?

        func run() throws {
            let savedBaseline = try Baseline(fromPath: baseline)
            let reporter = reporterFrom(identifier: reporter)
            let report = reporter.generateReport(savedBaseline.violations)
            if report.isNotEmpty {
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
            }
            ExitHelper.successfullyExit()
        }
    }
}
