import Commandant
import Foundation
import Result
import SourceKittenFramework
import SwiftLintFramework

struct LintableFilesVisitor {
    let paths: [String]
    let action: String
    let useSTDIN: Bool
    let quiet: Bool
    let useScriptInputFiles: Bool
    let forceExclude: Bool
    let cache: LinterCache?
    let parallel: Bool
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
        self.block = block
    }

    static func create(_ options: LintOrAnalyzeOptions, cache: LinterCache?, block: @escaping (Linter) -> Void)
        -> Result<LintableFilesVisitor, CommandantError<()>> {
        let visitor = LintableFilesVisitor(paths: options.paths, action: "Linting",
                                           useSTDIN: options.useSTDIN, quiet: options.quiet,
                                           useScriptInputFiles: options.useScriptInputFiles,
                                           forceExclude: options.forceExclude, cache: cache, parallel: true,
                                           block: block)
        return .success(visitor)
    }
}
