import Commandant

struct LintCommand: CommandProtocol {
    let verb = "lint"
    let function = "Print lint warnings and errors (default command)"

    func run(_ options: LintOptions) -> Result<(), CommandantError<()>> {
        return LintOrAnalyzeCommand.run(LintOrAnalyzeOptions(options))
    }
}

struct LintOptions: OptionsProtocol {
    let paths: [String]
    let useSTDIN: Bool
    let configurationFile: String
    let strict: Bool
    let lenient: Bool
    let forceExclude: Bool
    let excludeByPrefix: Bool
    let useScriptInputFiles: Bool
    let benchmark: Bool
    let reporter: String
    let quiet: Bool
    let cachePath: String
    let ignoreCache: Bool
    let enableAllRules: Bool

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ useSTDIN: Bool) -> (_ configurationFile: String) -> (_ strict: Bool) -> (_ lenient: Bool) -> (_ forceExclude: Bool) -> (_ excludeByPrefix: Bool) -> (_ useScriptInputFiles: Bool) -> (_ benchmark: Bool) -> (_ reporter: String) -> (_ quiet: Bool) -> (_ cachePath: String) -> (_ ignoreCache: Bool) -> (_ enableAllRules: Bool) -> (_ paths: [String]) -> LintOptions {
        return { useSTDIN in { configurationFile in { strict in { lenient in { forceExclude in { excludeByPrefix in { useScriptInputFiles in { benchmark in { reporter in { quiet in { cachePath in { ignoreCache in { enableAllRules in { paths in
            let allPaths: [String]
            if !path.isEmpty {
                allPaths = [path]
            } else {
                allPaths = paths
            }
            return self.init(paths: allPaths, useSTDIN: useSTDIN, configurationFile: configurationFile, strict: strict, lenient: lenient, forceExclude: forceExclude, excludeByPrefix: excludeByPrefix, useScriptInputFiles: useScriptInputFiles, benchmark: benchmark, reporter: reporter, quiet: quiet, cachePath: cachePath, ignoreCache: ignoreCache, enableAllRules: enableAllRules)
            // swiftlint:enable line_length
        }}}}}}}}}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<LintOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| pathOption(action: "lint")
            <*> mode <| Option(key: "use-stdin", defaultValue: false,
                               usage: "lint standard input")
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
            <*> mode <| Option(key: "cache-path", defaultValue: "",
                               usage: "the directory of the cache used when linting")
            <*> mode <| Option(key: "no-cache", defaultValue: false,
                               usage: "ignore cache when linting")
            <*> mode <| Option(key: "enable-all-rules", defaultValue: false,
                               usage: "run all rules, even opt-in and disabled ones, ignoring `whitelist_rules`")
            // This should go last to avoid eating other args
            <*> mode <| pathsArgument(action: "lint")
    }
}
