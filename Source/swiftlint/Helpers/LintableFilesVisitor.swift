import Foundation
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
}
