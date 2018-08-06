import Commandant
import Result
import SwiftLintFramework

struct AutoCorrectCommand: CommandProtocol {
    let verb = "autocorrect"
    let function = "Automatically correct warnings and errors"

    func run(_ options: AutoCorrectOptions) -> Result<(), CommandantError<()>> {
        switch options.visitor {
        case let .success(visitor):
            return Configuration(options: options).visitLintableFiles(with: visitor).flatMap { files in
                if !options.quiet {
                    let pluralSuffix = { (collection: [Any]) -> String in
                        return collection.count != 1 ? "s" : ""
                    }
                    queuedPrintError("Done correcting \(files.count) file\(pluralSuffix(files))!")
                }
                return .success(())
            }
        case let .failure(error):
            return .failure(error)
        }
    }
}

struct AutoCorrectOptions: OptionsProtocol {
    let paths: [String]
    let configurationFile: String
    let useScriptInputFiles: Bool
    let quiet: Bool
    let forceExclude: Bool
    let format: Bool
    let cachePath: String
    let ignoreCache: Bool
    let useTabs: Bool

    // swiftlint:disable line_length
    static func create(_ path: String) -> (_ configurationFile: String) -> (_ useScriptInputFiles: Bool) -> (_ quiet: Bool) -> (_ forceExclude: Bool) -> (_ format: Bool) -> (_ cachePath: String) -> (_ ignoreCache: Bool) -> (_ useTabs: Bool) -> (_ paths: [String]) -> AutoCorrectOptions {
        return { configurationFile in { useScriptInputFiles in { quiet in { forceExclude in { format in { cachePath in { ignoreCache in { useTabs in { paths in
            let allPaths: [String]
            if !path.isEmpty {
                allPaths = [path]
            } else {
                allPaths = paths
            }
            return self.init(paths: allPaths, configurationFile: configurationFile, useScriptInputFiles: useScriptInputFiles, quiet: quiet, forceExclude: forceExclude, format: format, cachePath: cachePath, ignoreCache: ignoreCache, useTabs: useTabs)
        }}}}}}}}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>> {
        // swiftlint:enable line_length
        return create
            <*> mode <| pathOption(action: "correct")
            <*> mode <| configOption
            <*> mode <| useScriptInputFilesOption
            <*> mode <| quietOption(action: "correcting")
            <*> mode <| Option(key: "force-exclude",
                               defaultValue: false,
                               usage: "exclude files in config `excluded` even if their paths are explicitly specified")
            <*> mode <| Option(key: "format",
                               defaultValue: false,
                               usage: "should reformat the Swift files")
            <*> mode <| Option(key: "cache-path", defaultValue: "",
                               usage: "the directory of the cache used when correcting")
            <*> mode <| Option(key: "no-cache", defaultValue: false,
                               usage: "ignore cache when correcting")
            <*> mode <| Option(key: "use-tabs",
                               defaultValue: false,
                               usage: "should use tabs over spaces when reformatting. Deprecated.")
            // This should go last to avoid eating other args
            <*> mode <| pathsArgument(action: "correct")
    }

    fileprivate var visitor: Result<LintableFilesVisitor, CommandantError<()>> {
        let configuration = Configuration(options: self)
        let cache = ignoreCache ? nil : LinterCache(configuration: configuration)
        let indentWidth: Int
        var useTabs: Bool

        switch configuration.indentation {
        case .tabs:
            indentWidth = 4
            useTabs = true
        case .spaces(let count):
            indentWidth = count
            useTabs = false
        }

        if useTabs {
            queuedPrintError("'use-tabs' is deprecated and will be completely removed" +
                " in a future release. 'indentation' can now be defined in a configuration file.")
            useTabs = self.useTabs
        }

        let visitor = LintableFilesVisitor(paths: paths, action: "Correcting", useSTDIN: false, quiet: quiet,
                                           useScriptInputFiles: useScriptInputFiles, forceExclude: forceExclude,
                                           cache: cache, parallel: true) { linter in
            let corrections = linter.correct()
            if !corrections.isEmpty && !self.quiet {
                let correctionLogs = corrections.map({ $0.consoleDescription })
                queuedPrint(correctionLogs.joined(separator: "\n"))
            }
            if self.format {
                linter.format(useTabs: useTabs, indentWidth: indentWidth)
            }
        }

        return .success(visitor)
    }
}
