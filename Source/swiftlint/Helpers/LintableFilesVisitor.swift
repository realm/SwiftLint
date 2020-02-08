import Commandant
import Foundation
import SourceKittenFramework
import SwiftLintFramework

typealias File = String
typealias Arguments = [String]

enum CompilerInvocations {
    case buildLog(compilerInvocations: [String])
    case compilationDatabase(compileCommands: [File: Arguments])

    func arguments(forFile path: String?) -> [String] {
        return path.flatMap { path in
            switch self {
            case let .buildLog(compilerInvocations):
                return CompilerArgumentsExtractor
                    .compilerArgumentsForFile(path, compilerInvocations: compilerInvocations)
            case let .compilationDatabase(compileCommands):
                return compileCommands[path]
            }
        } ?? []
    }
}

enum LintOrAnalyzeModeWithCompilerArguments {
    case lint
    case analyze(allCompilerInvocations: CompilerInvocations)
}

struct LintableFilesVisitor {
    let paths: [String]
    let action: String
    let useSTDIN: Bool
    let quiet: Bool
    let useScriptInputFiles: Bool
    let forceExclude: Bool
    let cache: LinterCache?
    let parallel: Bool
    let allowZeroLintableFiles: Bool
    let mode: LintOrAnalyzeModeWithCompilerArguments
    let block: (CollectedLinter) -> Void

    init(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, useScriptInputFiles: Bool, forceExclude: Bool,
         cache: LinterCache?, parallel: Bool,
         allowZeroLintableFiles: Bool, block: @escaping (CollectedLinter) -> Void) {
        self.paths = paths
        self.action = action
        self.useSTDIN = useSTDIN
        self.quiet = quiet
        self.useScriptInputFiles = useScriptInputFiles
        self.forceExclude = forceExclude
        self.cache = cache
        self.parallel = parallel
        self.mode = .lint
        self.allowZeroLintableFiles = allowZeroLintableFiles
        self.block = block
    }

    private init(paths: [String], action: String, useSTDIN: Bool, quiet: Bool,
                 useScriptInputFiles: Bool, forceExclude: Bool,
                 cache: LinterCache?, compilerInvocations: CompilerInvocations?,
                 allowZeroLintableFiles: Bool, block: @escaping (CollectedLinter) -> Void) {
        self.paths = paths
        self.action = action
        self.useSTDIN = useSTDIN
        self.quiet = quiet
        self.useScriptInputFiles = useScriptInputFiles
        self.forceExclude = forceExclude
        self.cache = cache
        self.parallel = true
        if let compilerInvocations = compilerInvocations {
            self.mode = .analyze(allCompilerInvocations: compilerInvocations)
        } else {
            self.mode = .lint
        }
        self.block = block
        self.allowZeroLintableFiles = allowZeroLintableFiles
    }

    static func create(_ options: LintOrAnalyzeOptions,
                       cache: LinterCache?,
                       allowZeroLintableFiles: Bool,
                       block: @escaping (CollectedLinter) -> Void)
        -> Result<LintableFilesVisitor, CommandantError<()>> {
        let compilerInvocations: CompilerInvocations?
        if options.mode == .lint {
            compilerInvocations = nil
        } else {
            switch loadCompilerInvocations(options) {
            case let .success(invocations):
                compilerInvocations = invocations
            case let .failure(error):
                return .failure(error)
            }
        }

        let visitor = LintableFilesVisitor(paths: options.paths, action: options.verb.bridge().capitalized,
                                           useSTDIN: options.useSTDIN, quiet: options.quiet,
                                           useScriptInputFiles: options.useScriptInputFiles,
                                           forceExclude: options.forceExclude, cache: cache,
                                           compilerInvocations: compilerInvocations,
                                           allowZeroLintableFiles: allowZeroLintableFiles, block: block)
        return .success(visitor)
    }

    func shouldSkipFile(atPath path: String?) -> Bool {
        switch self.mode {
        case .lint:
            return false
        case let .analyze(compilerInvocations):
            let compilerArguments = compilerInvocations.arguments(forFile: path)
            return compilerArguments.isEmpty
        }
    }

    func linter(forFile file: SwiftLintFile, configuration: Configuration) -> Linter {
        switch self.mode {
        case .lint:
            return Linter(file: file, configuration: configuration, cache: cache)
        case let .analyze(compilerInvocations):
            let compilerArguments = compilerInvocations.arguments(forFile: file.path)
            return Linter(file: file, configuration: configuration, compilerArguments: compilerArguments)
        }
    }

    private static func loadCompilerInvocations(_ options: LintOrAnalyzeOptions)
        -> Result<CompilerInvocations, CommandantError<()>> {
        if !options.compilerLogPath.isEmpty {
            let path = options.compilerLogPath
            guard let compilerInvocations = self.loadLogCompilerInvocations(path) else {
                return .failure(
                    .usageError(description: "Could not read compiler log at path: '\(path)'")
                )
            }

            return .success(.buildLog(compilerInvocations: compilerInvocations))
        } else if !options.compileCommands.isEmpty {
            let path = options.compileCommands
            guard let compileCommands = self.loadCompileCommands(path) else {
                return .failure(
                    .usageError(description: "Could not read compilation database at path: '\(path)'")
                )
            }

            return .success(.compilationDatabase(compileCommands: compileCommands))
        }

        return .failure(.usageError(description: "Could not read compiler invocations"))
    }

    private static func loadLogCompilerInvocations(_ path: String) -> [String]? {
        if let data = FileManager.default.contents(atPath: path),
            let logContents = String(data: data, encoding: .utf8) {
            if logContents.isEmpty {
                return nil
            }

            return CompilerArgumentsExtractor.allCompilerInvocations(compilerLogs: logContents)
        }

        return nil
    }

    private static func loadCompileCommands(_ path: String) -> [String: [String]]? {
        guard let jsonContents = FileManager.default.contents(atPath: path),
            let object = try? JSONSerialization.jsonObject(with: jsonContents),
            let compileDB = object as? [[String: Any]] else {
            return nil
        }

        // Convert the compilation database to a dictionary, with source files as keys and compiler arguments as values.
        //
        // Compilation databases are an array of dictionaries. Each dict has "file" and "arguments" keys.
        return compileDB.reduce(into: [:]) { (commands: inout [File: Arguments], entry: [String: Any]) in
            if let file = entry["file"] as? String, var arguments = entry["arguments"] as? [String] {
                // Compilation databases include the compiler, but it's left out when sending to SourceKit.
                if arguments.first == "swiftc" {
                    arguments.removeFirst()
                }

                commands[file] = CompilerArgumentsExtractor.filterCompilerArguments(arguments)
            }
        }
    }
}
