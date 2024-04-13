import ArgumentParser
import Foundation
import SwiftLintFramework

enum Action: String, ExpressibleByArgument {
    case report
}

extension SwiftLint {
    struct Baseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Performs operations on a saved Baseline."
        )

        @Argument(help: "The operation to perform on the baseline.")
        var action: Action = .report
        @Option(help: "The path to a baseline file.")
        var baseline: String
        @Option(help: "The reporter used to log errors and warnings.")
        var reporter: String?
        @Option(help: "The file where violations should be saved. Prints to stdout by default.")
        var output: String?

        func run() throws {
            try report()
            ExitHelper.successfullyExit()
        }

        private func report() throws {
            let savedBaseline = try SwiftLintCore.Baseline(fromPath: baseline)
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
        }
    }
}
