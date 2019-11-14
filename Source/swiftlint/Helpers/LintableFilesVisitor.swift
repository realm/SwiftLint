import Commandant
import Foundation
import SourceKittenFramework
import SwiftLintFramework

enum CompilerInvocations {
    case buildLog(compilerInvocations: [String])
    case compilationDatabase(compileCommands: [[String: Any]])

    func arguments(forFile path: String?) -> [String] {
        return path.flatMap { path in
            switch self {
            case let .buildLog(compilerInvocations):
                return CompilerArgumentsExtractor.compilerArgumentsForFile(path, compilerInvocations: compilerInvocations)
            case let .compilationDatabase(compileCommands):
                return compileCommands
                    .first { $0["file"] as? String == path }
                    .flatMap { $0["arguments"] as? [String] }
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
    let mode: LintOrAnalyzeModeWithCompilerArguments
    let block: (CollectedLinter) -> Void

    init(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, useScriptInputFiles: Bool, forceExclude: Bool,
         cache: LinterCache?, parallel: Bool, block: @escaping (CollectedLinter) -> Void) {
        self.paths = paths
        self.action = action
        self.useSTDIN = useSTDIN
        self.quiet = quiet
        self.useScriptInputFiles = useScriptInputFiles
        self.forceExclude = forceExclude
        self.cache = cache
        self.parallel = parallel
        self.mode = .lint
        self.block = block
    }

    private init(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, useScriptInputFiles: Bool,
                 forceExclude: Bool, cache: LinterCache?, compilerInvocations: CompilerInvocations?,
                 block: @escaping (CollectedLinter) -> Void) {
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
    }

    static func create(_ options: LintOrAnalyzeOptions, cache: LinterCache?, block: @escaping (CollectedLinter) -> Void)
        -> Result<LintableFilesVisitor, CommandantError<()>> {
        let compilerInvocations: CompilerInvocations?
        if options.mode == .lint {
            compilerInvocations = nil
        } else {
            if let logContents = LintableFilesVisitor.compilerLogContents(logPath: options.compilerLogPath) {
                let allCompilerInvocations = CompilerArgumentsExtractor.allCompilerInvocations(compilerLogs: logContents)
                compilerInvocations = .buildLog(compilerInvocations: allCompilerInvocations)
            } else if !options.compileCommands.isEmpty {
                do {
                    let yamlContents = try String(contentsOfFile: options.compileCommands, encoding: .utf8)
                    let compileCommands = try YamlParser.parseArray(yamlContents)
                    compilerInvocations = .compilationDatabase(compileCommands: compileCommands)
                } catch {
                    return .failure(
                        .usageError(description: "Could not compilation database at path: '\(options.compileCommands)'")
                    )
                }
            } else {
                return .failure(
                    .usageError(description: "Could not read compiler log at path: '\(options.compilerLogPath)'")
                )
            }
        }

        let visitor = LintableFilesVisitor(paths: options.paths, action: options.verb.bridge().capitalized,
                                           useSTDIN: options.useSTDIN, quiet: options.quiet,
                                           useScriptInputFiles: options.useScriptInputFiles,
                                           forceExclude: options.forceExclude, cache: cache,
                                           compilerInvocations: compilerInvocations, block: block)
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

    private static func compilerLogContents(logPath: String) -> String? {
        if logPath.isEmpty {
            return nil
        }

        if let data = FileManager.default.contents(atPath: logPath),
            let logContents = String(data: data, encoding: .utf8) {
            return logContents.isEmpty ? nil : logContents
        }

        print("couldn't read log file at path '\(logPath)'")
        return nil
    }
}
