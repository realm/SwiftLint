import ArgumentParser
import SwiftLintFramework

enum LeniencyOptions: String, EnumerableFlag {
    case strict, lenient

    static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .strict:
            return "Upgrades warnings to serious violations (errors)."
        case .lenient:
            return "Downgrades serious violations to warnings, warning threshold is disabled."
        }
    }
}

// MARK: - Common Arguments

struct LintOrAnalyzeArguments: ParsableArguments {
    @Option(help: "The path to one or more SwiftLint configuration files, evaluated as a parent-child hierarchy.")
    var config = [String]()
    @Flag(name: [.long, .customLong("autocorrect")], help: "Correct violations whenever possible.")
    var fix = false

    @Flag(help: """
        Should reformat the Swift files using the same mechanism used by Xcode (via SourceKit).
        Only applied with `--fix`/`--autocorrect`.
        """)
    var format = false
    @Flag(help: "Use an alternative algorithm to exclude paths for `excluded`, which may be faster in some cases.")
    var useAlternativeExcluding = false
    @Flag(help: "Read SCRIPT_INPUT_FILE* environment variables as files.")
    var useScriptInputFiles = false
    @Flag(help: "Read SCRIPT_INPUT_FILE_LIST* environment variables as file lists.")
    var useScriptInputFileLists = false
    @Flag(exclusivity: .exclusive)
    var leniency: LeniencyOptions?
    @Flag(help: "Exclude files in config `excluded` even if their paths are explicitly specified.")
    var forceExclude = false
    @Flag(help: "Save benchmarks to `benchmark_files.txt` and `benchmark_rules.txt`.")
    var benchmark = false
    @Option(help: "The reporter used to log errors and warnings.")
    var reporter: String?
    @Option(help: "The path to a baseline file, which will be used to filter out detected violations.")
    var baseline: String?
    @Option(help: "The path to save detected violations to as a new baseline.")
    var writeBaseline: String?
    @Option(help: "The working directory to use when running SwiftLint.")
    var workingDirectory: String?
    @Option(help: "The file where violations should be saved. Prints to stdout by default.")
    var output: String?
    @Flag(help: "Show a live-updating progress bar instead of each file being processed.")
    var progress = false
    @Flag(help: "Check whether a later version of SwiftLint is available after processing all files.")
    var checkForUpdates = false
}

// MARK: - Common Argument Help

// It'd be great to be able to parameterize an `@OptionGroup` so we could move these options into
// `LintOrAnalyzeArguments`.

func pathsArgumentDescription(for mode: LintOrAnalyzeMode) -> ArgumentHelp {
    "List of paths to the files or directories to \(mode.imperative)."
}

func quietOptionDescription(for mode: LintOrAnalyzeMode) -> ArgumentHelp {
    "Don't print status logs like '\(mode.verb.capitalized) <file>' & 'Done \(mode.verb)'."
}
