import ArgumentParser
import Foundation
import SwiftLintFramework

enum Action: String, ExpressibleByArgument {
    case report, compare
}

extension SwiftLint {
    struct Baseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Performs report or compare actions on a saved Baseline."
        )

        @Argument(help: "The action to perform on the baseline.")
        var action: Action = .report
        @Option(help: "The path to a baseline file.")
        var baseline: String
        @Option(
            help: """
                  The path to a new baseline to compare the baseline against. \
                  Violations that are not present in the new baseline will be reported.
                  """
        )
        var newBaseline: String?
        @Option(help: "The reporter used to log errors and warnings.")
        var reporter: String?
        @Option(help: "The file where violations should be saved. Prints to stdout by default.")
        var output: String?

        func run() throws {
            switch action {
            case .report:
                try report()
            case .compare:
                try compare()
            }
            ExitHelper.successfullyExit()
        }

        private func report() throws {
            let savedBaseline = try SwiftLintCore.Baseline(fromPath: baseline)
            try report(savedBaseline.violations)
        }

        private func report(_ violations: [StyleViolation]) throws {
            guard newBaseline == nil else {
                Issue.genericError("Unexpected argument '--new-baseline <new-baseline>'").print()
                return
            }
            let reporter = reporterFrom(identifier: reporter)
            let report = reporter.generateReport(violations)
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

        private func compare() throws {
            guard let newBaselinePath = newBaseline else {
                Issue.genericError("Missing expected argument '--new-baseline <new-baseline>'").print()
                return
            }
            let oldBaseline = try SwiftLintCore.Baseline(fromPath: baseline)
            let newBaseline = try SwiftLintCore.Baseline(fromPath: newBaselinePath)
            let violations = newBaseline.compare(oldBaseline)
            try report(violations)
        }
    }
}
