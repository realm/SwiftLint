import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

enum LintOrAnalyzeModeWithCompilerArguments {
    case lint
    case analyze(compilerArgumentsPerFile: [String: [String]])
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
    let block: (Linter) -> Void

    init(paths: [String], action: String, useSTDIN: Bool, quiet: Bool, useScriptInputFiles: Bool, forceExclude: Bool,
         cache: LinterCache?, parallel: Bool, block: @escaping (Linter) -> Void) {
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
                 forceExclude: Bool, cache: LinterCache?, compilerLogContents: String,
                 block: @escaping (Linter) -> Void) {
        self.paths = paths
        self.action = action
        self.useSTDIN = useSTDIN
        self.quiet = quiet
        self.useScriptInputFiles = useScriptInputFiles
        self.forceExclude = forceExclude
        self.cache = cache
        self.parallel = true
        let compilerArgumentsPerFile = CompilerArgumentsExtractor
            .extractCompilerArgumentsPerFile(compilerLogs: compilerLogContents)
        self.mode = .analyze(compilerArgumentsPerFile: compilerArgumentsPerFile)
        self.block = block
    }

    static func create(_ options: LintOrAnalyzeOptions, cache: LinterCache?, block: @escaping (Linter) -> Void)
        -> Result<LintableFilesVisitor, CommandantError<()>> {
        let compilerLogContents: String
        if options.mode == .lint {
            compilerLogContents = ""
        } else if let logContents = LintableFilesVisitor.compilerLogContents(logPath: options.compilerLogPath),
            !logContents.isEmpty {
            compilerLogContents = logContents
        } else {
            return .failure(
                .usageError(description: "Could not read compiler log at path: '\(options.compilerLogPath)'")
            )
        }

        let visitor = LintableFilesVisitor(paths: options.paths, action: options.verb.bridge().capitalized,
                                           useSTDIN: options.useSTDIN, quiet: options.quiet,
                                           useScriptInputFiles: options.useScriptInputFiles,
                                           forceExclude: options.forceExclude, cache: cache,
                                           compilerLogContents: compilerLogContents, block: block)
        return .success(visitor)
    }

    func shouldSkipFile(atPath path: String?) -> Bool {
        switch self.mode {
        case .lint:
            return false
        case let .analyze(compilerArgumentsPerFile):
            let compilerArguments = path.flatMap { compilerArgumentsPerFile[$0] } ?? []
            return compilerArguments.isEmpty
        }
    }

    func linter(forFile file: File, configuration: Configuration) -> Linter {
        switch self.mode {
        case .lint:
            return Linter(file: file, configuration: configuration, cache: cache)
        case let .analyze(compilerArgumentsPerFile):
            let compilerArguments = file.path.flatMap { compilerArgumentsPerFile[$0] } ?? []
            return Linter(file: file, configuration: configuration, compilerArguments: compilerArguments)
        }
    }

    private static func compilerLogContents(logPath: String) -> String? {
        if logPath.isEmpty {
            return nil
        }

        if let data = FileManager.default.contents(atPath: logPath),
            let logContents = String(data: data, encoding: .utf8) {
            return logContents
        }

        print("couldn't read log file at path '\(logPath)'")
        return nil
    }
}
