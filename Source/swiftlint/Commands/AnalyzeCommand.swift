import Commandant
import SwiftLintFramework

struct AnalyzeCommand: CommandProtocol {
    let verb = "analyze"
    let function = "[Experimental] Run analysis rules"

    func run(_ options: AnalyzeOptions) -> Result<(), CommandantError<()>> {
        let options = LintOrAnalyzeOptions(options)
        if options.autocorrect {
            return autocorrect(options)
        } else {
            return LintOrAnalyzeCommand.run(options)
        }
    }

    private func autocorrect(_ options: LintOrAnalyzeOptions) -> Result<(), CommandantError<()>> {
        let storage = RuleStorage()
        let configuration = Configuration(options: options)
        return configuration.visitLintableFiles(options: options, cache: nil, storage: storage) { linter in
            let corrections = linter.correct(using: storage)
            if !corrections.isEmpty && !options.quiet {
                let correctionLogs = corrections.map({ $0.consoleDescription })
                queuedPrint(correctionLogs.joined(separator: "\n"))
            }
        }.flatMap { files in
            if !options.quiet {
                let pluralSuffix = { (collection: [Any]) -> String in
                    return collection.count != 1 ? "s" : ""
                }
                queuedPrintError("Done correcting \(files.count) file\(pluralSuffix(files))!")
            }
            return .success(())
        }
    }
}

struct AnalyzeOptions: OptionsProtocol {
    let paths: [String]
    let configurationFile: String
    let strict: Bool
    let lenient: Bool
    let forceExclude: Bool
    let excludeByPrefix: Bool
    let useScriptInputFiles: Bool
    let benchmark: Bool
    let reporter: String
    let quiet: Bool
    let enableAllRules: Bool
    let autocorrect: Bool
    let compilerLogPath: String
    let compileCommands: String

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ configurationFile: String) -> (_ strict: Bool) -> (_ lenient: Bool) -> (_ forceExclude: Bool) -> (_ excludeByPrefix: Bool) -> (_ useScriptInputFiles: Bool) -> (_ benchmark: Bool) -> (_ reporter: String) -> (_ quiet: Bool) -> (_ enableAllRules: Bool) -> (_ autocorrect: Bool) -> (_ compilerLogPath: String) -> (_ compileCommands: String) -> (_ paths: [String]) -> AnalyzeOptions {
        return { configurationFile in { strict in { lenient in { forceExclude in { excludeByPrefix in { useScriptInputFiles in { benchmark in { reporter in { quiet in { enableAllRules in { autocorrect in { compilerLogPath in { compileCommands in { paths in
            let allPaths: [String]
            if !path.isEmpty {
                allPaths = [path]
            } else {
                allPaths = paths
            }
            return self.init(paths: allPaths, configurationFile: configurationFile, strict: strict, lenient: lenient, forceExclude: forceExclude, excludeByPrefix: excludeByPrefix, useScriptInputFiles: useScriptInputFiles, benchmark: benchmark, reporter: reporter, quiet: quiet, enableAllRules: enableAllRules, autocorrect: autocorrect, compilerLogPath: compilerLogPath, compileCommands: compileCommands)
            // swiftlint:enable line_length
            }}}}}}}}}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<AnalyzeOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| pathOption(action: "analyze")
            <*> mode <| configOption
            <*> mode <| Option(key: "strict", defaultValue: false,
                               usage: "fail on warnings")
            <*> mode <| Option(key: "lenient", defaultValue: false,
                               usage: "downgrades serious violations to warnings, warning threshold is disabled")
            <*> mode <| Option(key: "force-exclude", defaultValue: false,
                               usage: "exclude files in config `excluded` even if their paths are explicitly specified")
            <*> mode <| useAlternativeExcludingOption
            <*> mode <| useScriptInputFilesOption
            <*> mode <| Option(key: "benchmark", defaultValue: false,
                               usage: "save benchmarks to benchmark_files.txt " +
                                      "and benchmark_rules.txt")
            <*> mode <| Option(key: "reporter", defaultValue: "",
                               usage: "the reporter used to log errors and warnings")
            <*> mode <| quietOption(action: "linting")
            <*> mode <| Option(key: "enable-all-rules", defaultValue: false,
                               usage: "run all rules, even opt-in and disabled ones, ignoring `whitelist_rules`")
            <*> mode <| Option(key: "autocorrect", defaultValue: false,
                               usage: "correct violations whenever possible")
            <*> mode <| Option(key: "compiler-log-path", defaultValue: "",
                               usage: "the path of the full xcodebuild log to use when linting AnalyzerRules")
            <*> mode <| Option(key: "compile-commands", defaultValue: "",
                               usage: "the path of a compilation database to use when linting AnalyzerRules")
            // This should go last to avoid eating other args
            <*> mode <| pathsArgument(action: "analyze")
    }
}
