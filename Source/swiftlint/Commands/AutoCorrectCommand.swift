import Commandant
import SwiftLintFramework

struct AutoCorrectCommand: CommandProtocol {
    let verb = "autocorrect"
    let function = "Automatically correct warnings and errors"

    func run(_ options: AutoCorrectOptions) -> Result<(), CommandantError<()>> {
        let configuration = Configuration(options: options)
        let storage = RuleStorage()
        let visitor = options.visitor(with: configuration, storage: storage)
        return configuration.visitLintableFiles(with: visitor, storage: storage).flatMap { files in
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

struct AutoCorrectOptions: OptionsProtocol {
    let paths: [String]
    let configurationFile: String
    let useScriptInputFiles: Bool
    let quiet: Bool
    let forceExclude: Bool
    let excludeByPrefix: Bool
    let format: Bool
    let cachePath: String
    let ignoreCache: Bool

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ configurationFile: String) -> (_ useScriptInputFiles: Bool) -> (_ quiet: Bool) -> (_ forceExclude: Bool) ->
    (_ excludeByPrefix: Bool) -> (_ format: Bool) -> (_ cachePath: String) -> (_ ignoreCache: Bool) -> (_ paths: [String]) -> AutoCorrectOptions {
    return { configurationFile in { useScriptInputFiles in { quiet in { forceExclude in { excludeByPrefix in { format in { cachePath in { ignoreCache in { paths in
            let allPaths: [String]
            if !path.isEmpty {
                allPaths = [path]
            } else {
                allPaths = paths
            }
            return self.init(paths: allPaths, configurationFile: configurationFile, useScriptInputFiles: useScriptInputFiles, quiet: quiet, forceExclude: forceExclude,
                             excludeByPrefix: excludeByPrefix, format: format, cachePath: cachePath, ignoreCache: ignoreCache)
            // swiftlint:enable line_length
            }}}}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| pathOption(action: "correct")
            <*> mode <| configOption
            <*> mode <| useScriptInputFilesOption
            <*> mode <| quietOption(action: "correcting")
            <*> mode <| Option(key: "force-exclude", defaultValue: false,
                               usage: "exclude files in config `excluded` even if their paths are explicitly specified")
            <*> mode <| useAlternativeExcludingOption
            <*> mode <| Option(key: "format", defaultValue: false,
                               usage: "should reformat the Swift files")
            <*> mode <| Option(key: "cache-path", defaultValue: "",
                               usage: "the directory of the cache used when correcting")
            <*> mode <| Option(key: "no-cache", defaultValue: false,
                               usage: "ignore cache when correcting")
            // This should go last to avoid eating other args
            <*> mode <| pathsArgument(action: "correct")
    }

    fileprivate func visitor(with configuration: Configuration, storage: RuleStorage) -> LintableFilesVisitor {
        let cache = ignoreCache ? nil : LinterCache(configuration: configuration)
        return LintableFilesVisitor(paths: paths, action: "Correcting", useSTDIN: false, quiet: quiet,
                                    useScriptInputFiles: useScriptInputFiles, forceExclude: forceExclude,
                                    useExcludingByPrefix: excludeByPrefix, cache: cache, parallel: true,
                                    allowZeroLintableFiles: configuration.allowZeroLintableFiles) { linter in
            if self.format {
                switch configuration.indentation {
                case .tabs:
                    linter.format(useTabs: true, indentWidth: 4)
                case .spaces(let count):
                    linter.format(useTabs: false, indentWidth: count)
                }
            }
            let corrections = linter.correct(using: storage)
            if !corrections.isEmpty && !self.quiet {
                let correctionLogs = corrections.map({ $0.consoleDescription })
                queuedPrint(correctionLogs.joined(separator: "\n"))
            }
        }
    }
}
