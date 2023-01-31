import Foundation
import SourceKittenFramework
import SwiftLintFramework

typealias File = String
typealias Arguments = [String]

class CompilerInvocations {
    static func buildLog(compilerInvocations: [[String]]) -> CompilerInvocations {
        return ArrayCompilerInvocations(invocations: compilerInvocations)
    }

    static func compilationDatabase(compileCommands: [File: Arguments]) -> CompilerInvocations {
        return CompilationDatabaseInvocations(compileCommands: compileCommands)
    }

    /// Default implementation
    func arguments(forFile path: String?) -> Arguments { [] }

    // MARK: - Private

    private class ArrayCompilerInvocations: CompilerInvocations {
        private let invocationsByArgument: [String: [Arguments]]

        init(invocations: [Arguments]) {
            // Store invocations by the path, so next when we'll be asked for arguments,
            // we'll be able to return them faster
            self.invocationsByArgument = invocations.reduce(into: [:]) { result, arguments in
                arguments.forEach { result[$0, default: []].append(arguments) }
            }
        }

        override func arguments(forFile path: String?) -> Arguments {
            return path.flatMap { path in
                return invocationsByArgument[path]?.first
            } ?? []
        }
    }

    private class CompilationDatabaseInvocations: CompilerInvocations {
        private let compileCommands: [File: Arguments]

        init(compileCommands: [File: Arguments]) {
            self.compileCommands = compileCommands
        }

        override func arguments(forFile path: String?) -> Arguments {
            return path.flatMap { path in
                return compileCommands[path] ??
                compileCommands[path.path(relativeTo: FileManager.default.currentDirectoryPath)]
            } ?? []
        }
    }
}

enum LintOrAnalyzeModeWithCompilerArguments {
    case lint
    case analyze(allCompilerInvocations: CompilerInvocations)
}

private func resolveParamsFiles(args: [String]) -> [String] {
    return args.reduce(into: []) { (allArgs: inout [String], arg: String) -> Void in
        if arg.hasPrefix("@"), let contents = try? String(contentsOfFile: String(arg.dropFirst())) {
            allArgs.append(contentsOf: resolveParamsFiles(args: contents.split(separator: "\n").map(String.init)))
        } else {
            allArgs.append(arg)
        }
    }
}

struct LintableFilesVisitor {
    let paths: [String]
    let action: String
    let useSTDIN: Bool
    let quiet: Bool
    let showProgressBar: Bool
    let useScriptInputFiles: Bool
    let forceExclude: Bool
    let useExcludingByPrefix: Bool
    let cache: LinterCache?
    let parallel: Bool
    let allowZeroLintableFiles: Bool
    let mode: LintOrAnalyzeModeWithCompilerArguments
    let block: (CollectedLinter) async -> Void

    private init(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, showProgressBar: Bool,
                 useScriptInputFiles: Bool, forceExclude: Bool, useExcludingByPrefix: Bool,
                 cache: LinterCache?, compilerInvocations: CompilerInvocations?,
                 allowZeroLintableFiles: Bool, block: @escaping (CollectedLinter) async -> Void) {
        self.paths = resolveParamsFiles(args: paths)
        self.action = action
        self.useSTDIN = useSTDIN
        self.quiet = quiet
        self.showProgressBar = showProgressBar
        self.useScriptInputFiles = useScriptInputFiles
        self.forceExclude = forceExclude
        self.useExcludingByPrefix = useExcludingByPrefix
        self.cache = cache
        if let compilerInvocations {
            self.mode = .analyze(allCompilerInvocations: compilerInvocations)
            // SourceKit had some changes in 5.6 that makes it ~100x more expensive
            // to process files concurrently. By processing files serially, it's
            // only 2x slower than before.
            self.parallel = SwiftVersion.current < .fiveDotSix
        } else {
            self.mode = .lint
            self.parallel = true
        }
        self.block = block
        self.allowZeroLintableFiles = allowZeroLintableFiles
    }

    static func create(_ options: LintOrAnalyzeOptions,
                       cache: LinterCache?,
                       allowZeroLintableFiles: Bool,
                       block: @escaping (CollectedLinter) async -> Void)
        throws -> LintableFilesVisitor {
        try Signposts.record(name: "LintableFilesVisitor.Create") {
            let compilerInvocations: CompilerInvocations?
            if options.mode == .lint {
                compilerInvocations = nil
            } else {
                compilerInvocations = try loadCompilerInvocations(options)
            }

            return LintableFilesVisitor(
                paths: options.paths, action: options.verb.bridge().capitalized,
                useSTDIN: options.useSTDIN, quiet: options.quiet,
                showProgressBar: options.progress,
                useScriptInputFiles: options.useScriptInputFiles,
                forceExclude: options.forceExclude,
                useExcludingByPrefix: options.useExcludingByPrefix,
                cache: cache,
                compilerInvocations: compilerInvocations,
                allowZeroLintableFiles: allowZeroLintableFiles, block: block
            )
        }
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

    private static func loadCompilerInvocations(_ options: LintOrAnalyzeOptions) throws -> CompilerInvocations {
        if let path = options.compilerLogPath {
            guard let compilerInvocations = self.loadLogCompilerInvocations(path) else {
                throw SwiftLintError.usageError(description: "Could not read compiler log at path: '\(path)'")
            }

            return .buildLog(compilerInvocations: compilerInvocations)
        } else if let path = options.compileCommands {
            do {
                return .compilationDatabase(compileCommands: try self.loadCompileCommands(path))
            } catch {
                throw SwiftLintError.usageError(
                    description: "Could not read compilation database at path: '\(path)' \(error.localizedDescription)"
                )
            }
        }

        throw SwiftLintError.usageError(description: "Could not read compiler invocations")
    }

    private static func loadLogCompilerInvocations(_ path: String) -> [[String]]? {
        if let data = FileManager.default.contents(atPath: path),
            let logContents = String(data: data, encoding: .utf8) {
            if logContents.isEmpty {
                return nil
            }

            return CompilerArgumentsExtractor.allCompilerInvocations(compilerLogs: logContents)
        }

        return nil
    }

    private static func loadCompileCommands(_ path: String) throws -> [File: Arguments] {
        guard let fileContents = FileManager.default.contents(atPath: path) else {
            throw CompileCommandsLoadError.nonExistentFile(path)
        }

        if path.hasSuffix(".yaml") || path.hasSuffix(".yml") {
            // Assume this is a SwiftPM yaml file
            return try SwiftPMCompilationDB.parse(yaml: fileContents)
        }

        guard let object = try? JSONSerialization.jsonObject(with: fileContents),
            let compileDB = object as? [[String: Any]] else {
            throw CompileCommandsLoadError.malformedCommands(path)
        }

        // Convert the compilation database to a dictionary, with source files as keys and compiler arguments as values.
        //
        // Compilation databases are an array of dictionaries. Each dict has "file" and "arguments" keys.
        var commands = [File: Arguments]()
        for (index, entry) in compileDB.enumerated() {
            guard let file = entry["file"] as? String else {
                throw CompileCommandsLoadError.malformedFile(path, index)
            }

            guard let arguments = entry["arguments"] as? [String] else {
                throw CompileCommandsLoadError.malformedArguments(path, index)
            }

            guard arguments.contains(file) else {
                throw CompileCommandsLoadError.missingFileInArguments(path, index, arguments)
            }

            commands[file] = arguments.filteringCompilerArguments
        }

        return commands
    }
}

private enum CompileCommandsLoadError: LocalizedError {
    case nonExistentFile(String)
    case malformedCommands(String)
    case malformedFile(String, Int)
    case malformedArguments(String, Int)
    case missingFileInArguments(String, Int, [String])

    var errorDescription: String? {
        switch self {
        case let .nonExistentFile(path):
            return "Could not read compile commands file at '\(path)'"
        case let .malformedCommands(path):
            return "Compile commands file at '\(path)' isn't in the correct format"
        case let .malformedFile(path, index):
            return "Missing or invalid (must be a string) 'file' key in \(path) at index \(index)"
        case let .malformedArguments(path, index):
            return "Missing or invalid (must be an array of strings) 'arguments' key in \(path) at index \(index)"
        case let .missingFileInArguments(path, index, arguments):
            return "Entry in \(path) at index \(index) has 'arguments' which do not contain the 'file': \(arguments)"
        }
    }
}
