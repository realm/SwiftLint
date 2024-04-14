import ArgumentParser
import Foundation
import SwiftLintFramework

enum Action: String, ExpressibleByArgument {
    case report, compare
}

extension SwiftLint {
    struct Baseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Performs '\(Action.report)' or '\(Action.compare)' actions on a saved Baseline."
        )

        @Argument(help: "The action to perform on the baseline ('\(Action.report)' or '\(Action.compare)').")
        var action: Action
        @Option(help: "The path to a baseline file.")
        var baseline: String
        @Option(
            help: """
                  The path to a new baseline to compare the baseline against. \
                  New violations that are not present in the old baseline will be reported."
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

        func validate() throws {
            switch action {
            case .report:
                guard newBaseline == nil else {
                    throw ValidationError("Unexpected argument '--new-baseline <new-baseline>'")
                }
            case .compare:
                guard newBaseline != nil else {
                    throw ValidationError("Missing expected argument '--new-baseline <new-baseline>'")
                }
            }
        }

        private func report() throws {
            let savedBaseline = try SwiftLintCore.Baseline(fromPath: baseline)
            try report(savedBaseline.violations)
        }

        private func compare() throws {
            guard let newBaselinePath = newBaseline else {
                return
            }
            let oldBaseline = try SwiftLintCore.Baseline(fromPath: baseline)
            let newBaseline = try SwiftLintCore.Baseline(fromPath: newBaselinePath)
            let violations = oldBaseline.compare(newBaseline)
            try report(violations)
        }

        private func report(_ violations: [StyleViolation]) throws {
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
    }
}
