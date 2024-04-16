import ArgumentParser
import Foundation
import SwiftLintFramework

enum Action: String, ExpressibleByArgument {
    case report, compare
}

extension SwiftLint {
    struct Baseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Reports the violations in a baseline (the '\(Action.report)' action) or the violations " +
                      "that are present in another baseline, but not in the original (the '\(Action.compare)' action)."
        )

        @Argument(help: "The action to perform on the baseline ('\(Action.report)' or '\(Action.compare)').")
        var action: Action
        @Option(help: "The path to the baseline file.")
        var baseline: String
        @Option(
            help: """
                  The path to a second baseline to compare against the baseline. Violations in \
                  the second baseline that are not present in the original baseline will be reported \
                  when the '\(Action.compare)' action is selected.
                  """
        )
        var otherBaseline: String?
        @Option(help: "The reporter used to report violations. The 'summary' reporter can be useful to provide an overview.")
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
                guard otherBaseline == nil else {
                    throw ValidationError("Unexpected argument '--other-baseline <new-baseline>'")
                }
            case .compare:
                guard otherBaseline != nil else {
                    throw ValidationError("Missing expected argument '--other-baseline <other-baseline>'")
                }
            }
        }

        private func report() throws {
            let savedBaseline = try SwiftLintCore.Baseline(fromPath: baseline)
            try report(savedBaseline.violations)
        }

        private func compare() throws {
            guard let otherBaselinePath = otherBaseline else {
                return
            }
            let baseline = try SwiftLintCore.Baseline(fromPath: baseline)
            let otherBaseline = try SwiftLintCore.Baseline(fromPath: otherBaselinePath)
            try report(baseline.compare(otherBaseline))
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
