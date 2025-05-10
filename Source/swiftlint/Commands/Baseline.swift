import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct Baseline: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Operations on existing baselines",
            subcommands: [Report.self, Compare.self],
            defaultSubcommand: Report.self
        )
    }

    private struct BaselineOptions: ParsableArguments {
        @Argument(help: "The path to the baseline file.")
        var baseline: String
    }

    private struct ReportingOptions: ParsableArguments {
        @Option(
            help: """
                  The reporter used to report violations. The 'summary' reporter can be useful to \
                  provide an overview.
                  """
        )
        var reporter: String?
        @Option(help: "The file where violations should be saved. Prints to stdout by default.")
        var output: String?
    }

    private struct Report: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Reports the violations in a baseline.")

        @OptionGroup
        var options: BaselineOptions
        @OptionGroup
        var reportingOptions: ReportingOptions

        func run() throws {
            let savedBaseline = try SwiftLintCore.Baseline(fromPath: options.baseline)
            try report(savedBaseline.violations, using: reportingOptions.reporter, to: reportingOptions.output)
        }
    }

    private struct Compare: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Reports the violations that are present in another baseline " +
                      "but not in the original baseline."
        )

        @OptionGroup
        var options: BaselineOptions
        @Option(
            help: """
                  The path to a second baseline to compare against the baseline. Violations in \
                  the second baseline that are not present in the original baseline will be reported.
                  """
        )
        var otherBaseline: String
        @OptionGroup
        var reportingOptions: ReportingOptions

        func run() throws {
            let baseline = try SwiftLintCore.Baseline(fromPath: options.baseline)
            let otherBaseline = try SwiftLintCore.Baseline(fromPath: otherBaseline)
            try report(baseline.compare(otherBaseline), using: reportingOptions.reporter, to: reportingOptions.output)
        }
    }
}

private func report(_ violations: [StyleViolation], using reporterIdentifier: String?, to output: String?) throws {
    let reporter = reporterFrom(identifier: reporterIdentifier)
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
